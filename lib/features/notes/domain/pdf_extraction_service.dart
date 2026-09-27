import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

abstract interface class PdfExtractionService {
  Future<void> indexPdf(int fileId, String relativeFilePath);
}

/// Pages handed to a single [PdfDocument] instance.
///
/// Syncfusion caches parsed page objects, page resources and decoded image
/// XObjects inside the document for as long as it stays alive, so the memory
/// held by one open document grows with the number of pages read from it.
/// Measured on a 400 page / 91 MB PDF, one long lived document retained
/// ~2.6 MB per page (over 1 GB for the whole file) while a document disposed
/// every 10 pages stayed flat. Reopening also costs one cross-reference table
/// parse, so the batch size trades retained memory against re-parse time;
/// 10 pages measured lowest on both content shapes that were probed (a text
/// heavy and an image heavy 400 page file); 20 and 40 page batches retained
/// more, and 5 pages was worse again because of the extra reopens.
const int kPagesPerBatch = 10;

final class LocalPdfExtractionService implements PdfExtractionService {
  LocalPdfExtractionService(this._dao, this._storageService);

  final PdfSearchDao _dao;
  final SubjectFileStorageService _storageService;

  @override
  Future<void> indexPdf(int fileId, String relativeFilePath) async {
    File file;
    try {
      file = await _storageService.resolveFile(relativeFilePath);
    } catch (e) {
      debugPrint('Could not resolve PDF $fileId: $e');
      await _dao.markAsError(fileId);
      return;
    }

    if (!await file.exists()) {
      await _dao.markAsError(fileId);
      return;
    }

    // Check if this was previously interrupted/crashed
    final meta = await _dao.getMetadata(fileId);
    if (meta != null && meta.status.startsWith('indexing')) {
      debugPrint('Resuming or restarting interrupted index for $fileId');
    }

    await _dao.beginIndexing(fileId);

    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    Isolate? isolate;
    Timer? watchdog;

    // The isolate has to be the one that decides which pages were read, but the
    // main isolate has to be the one that decides how the operation ended, so
    // an isolate that dies without reporting (hard OOM, process level kill)
    // cannot leave the row stuck on `indexing` forever.
    var terminal = false;
    var totalPages = 0;

    final outcome = Completer<String?>(); // null == completed fine

    void finish(String? failure) {
      if (outcome.isCompleted) return;
      outcome.complete(failure);
    }

    try {
      isolate = await Isolate.spawn(
        _extractPagesIsolate,
        _ExtractionParams(file.path, receivePort.sendPort),
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
        errorsAreFatal: false,
        debugName: 'pdf-index-$fileId',
      );

      errorPort.listen((Object? error) {
        if (terminal || outcome.isCompleted) return;
        debugPrint('PDF extraction isolate error for $fileId: $error');
        finish('isolate error');
        // Unblock the receive loop: the isolate may still be alive but silent.
        receivePort.close();
      });

      exitPort.listen((Object? _) {
        if (terminal || outcome.isCompleted) return;
        // Messages already queued by the isolate may still be in flight, so
        // only declare the run dead when nothing arrives shortly after exit.
        watchdog?.cancel();
        watchdog = Timer(const Duration(seconds: 1), () {
          if (terminal || outcome.isCompleted) return;
          debugPrint(
            'PDF extraction isolate for $fileId exited without reporting',
          );
          finish('isolate exited without reporting');
          receivePort.close();
        });
      });

      await for (final message in receivePort) {
        switch (message) {
          case _ExtractionPageCount(:final count):
            totalPages = count;
            if (totalPages == 0) {
              terminal = true;
              await _dao.markAsUnsupported(fileId);
              finish(null);
            }
          case _ExtractionBatch(
            :final pages,
            :final lastPageAttempted,
            :final failedPages,
          ):
            if (failedPages > 0) {
              debugPrint(
                'PDF $fileId: $failedPages page(s) could not be extracted '
                '(skipped, indexing continues)',
              );
            }
            await _dao.transaction(() async {
              for (final page in pages) {
                await _dao.saveExtractedPage(fileId, page.pageNumber, page.text);
              }
            });
            // Progress tracks page numbers attempted, not only pages that
            // produced text, so a page that fails cannot stall the counter.
            await _dao.updateProgress(
              fileId,
              lastPageAttempted,
              totalPages == 0 ? lastPageAttempted : totalPages,
            );
          case _ExtractionComplete(:final pageCount):
            terminal = true;
            await _dao.completeIndexing(
              fileId,
              pageCount == 0 ? totalPages : pageCount,
            );
            finish(null);
          case _ExtractionFailure(:final reason):
            terminal = true;
            debugPrint('PDF extraction failed for $fileId: $reason');
            await _dao.markAsError(fileId);
            finish(reason);
        }
        if (terminal) break;
      }

      if (!outcome.isCompleted) {
        // The stream ended without a terminal message: the isolate is gone.
        debugPrint('PDF extraction for $fileId ended without a result');
        finish('isolate stopped without reporting');
      }

      final failure = await outcome.future;
      if (failure != null) {
        isolate.kill(priority: Isolate.immediate);
        await _dao.markAsError(fileId);
      }
    } on OutOfMemoryError {
      debugPrint('Out of memory while indexing PDF $fileId');
      isolate?.kill(priority: Isolate.immediate);
      await _dao.markAsError(fileId);
    } catch (e) {
      debugPrint('Error indexing PDF $fileId: $e');
      isolate?.kill(priority: Isolate.immediate);
      await _dao.markAsError(fileId);
    } finally {
      // Always release the isolate and every port, whatever happened, so a
      // failed run cannot leave the database row stuck on `indexing`.
      watchdog?.cancel();
      isolate?.kill(priority: Isolate.immediate);
      receivePort.close();
      errorPort.close();
      exitPort.close();
      if (!outcome.isCompleted) outcome.complete('indexing aborted');
    }
  }

  /// Reads, extracts and reports pages one small batch at a time.
  ///
  /// The isolate receives only the file path, never the PDF bytes, so no
  /// document buffer is ever serialised across isolates. Syncfusion's PDF
  /// reader has no file backed or streaming constructor: it only accepts the
  /// complete document as a `List<int>` (`PdfDocument(inputBytes: ...)` or
  /// `PdfDocument.fromBase64String`), so one buffer for the whole file is the
  /// lowest memory input this package supports. We therefore read it exactly
  /// once and hand the very same `Uint8List` to every document instance
  /// (Syncfusion keeps the reference, it does not copy it).
  static Future<void> _extractPagesIsolate(_ExtractionParams params) async {
    final sendPort = params.sendPort;
    Uint8List? buffer;
    try {
      final file = File(params.filePath);
      if (!file.existsSync()) {
        sendPort.send(const _ExtractionFailure('file is missing'));
        return;
      }

      // Single allocation: `readAsBytesSync` allocates the destination buffer
      // once and fills it, so there is no second copy of the PDF anywhere.
      buffer = file.readAsBytesSync();
      final data = _trimTrailingBytesAfterEndOfFile(buffer);

      var start = 0;
      int? knownPageCount;
      while (true) {
        final document = PdfDocument(inputBytes: data);
        try {
          var pageCount = knownPageCount;
          if (pageCount == null) {
            // The first document also answers the page count, so the file is
            // never parsed a second time just to count pages.
            pageCount = document.pages.count;
            knownPageCount = pageCount;
            sendPort.send(_ExtractionPageCount(pageCount));
            if (pageCount == 0) return;
          }

          final batchEnd = math.min(start + kPagesPerBatch, pageCount);
          final extractor = PdfTextExtractor(document);
          final pages = <_PageText>[];
          var failedPages = 0;
          for (int index = start; index < batchEnd; index++) {
            try {
              final text = extractor.extractText(
                startPageIndex: index,
                endPageIndex: index,
              );
              pages.add(_PageText(index + 1, text));
            } catch (e) {
              failedPages++;
              debugPrint('Failed to extract page ${index + 1}: $e');
            }
          }

          sendPort.send(
            _ExtractionBatch(
              pages: pages,
              lastPageAttempted: batchEnd,
              failedPages: failedPages,
            ),
          );
          start = batchEnd;
          if (start >= pageCount) break;
        } finally {
          // Disposing here is what bounds memory: it releases the parsed page
          // objects, resources and decoded image XObjects this batch created.
          document.dispose();
        }
      }

      sendPort.send(_ExtractionComplete(knownPageCount ?? 0));
    } on OutOfMemoryError {
      debugPrint('Out of memory extracting PDF ${params.filePath}');
      sendPort.send(const _ExtractionFailure('out of memory'));
    } catch (e) {
      debugPrint('Error in _extractPagesIsolate: $e');
      sendPort.send(_ExtractionFailure(e.toString()));
    } finally {
      buffer = null;
    }
  }

  /// Returns [bytes] ending exactly at the last `%%EOF` marker when anything
  /// other than trailing whitespace follows it.
  ///
  /// Syncfusion's cross table reader rereads the document tail and, if it finds
  /// a token after the final `%%EOF`, builds a *copy* of the entire file as a
  /// growable `List<int>` (about eight bytes of heap per byte of PDF) each time
  /// a document is constructed. On the measured 91 MB file that repeatedly cost
  /// ~700 MB per `PdfDocument` creation, ~1.9 GB peak and a 2.7x slower run.
  /// The view returned here shares the existing buffer (no allocation) and
  /// covers exactly the byte range Syncfusion would otherwise have kept, so the
  /// extracted text is unchanged.
  static Uint8List _trimTrailingBytesAfterEndOfFile(Uint8List bytes) {
    const eof = '%%EOF';
    if (bytes.length < eof.length) return bytes;
    for (int start = bytes.length - eof.length; start >= 0; start--) {
      var matches = true;
      for (int offset = 0; offset < eof.length; offset++) {
        if (bytes[start + offset] != eof.codeUnitAt(offset)) {
          matches = false;
          break;
        }
      }
      if (!matches) continue;
      final end = start + eof.length;
      return end == bytes.length ? bytes : Uint8List.sublistView(bytes, 0, end);
    }
    return bytes;
  }
}

// -- Isolate Messaging Classes --

class _ExtractionParams {
  const _ExtractionParams(this.filePath, this.sendPort);
  final String filePath;
  final SendPort sendPort;
}

/// Reported once, from the first open document, before any batch.
class _ExtractionPageCount {
  const _ExtractionPageCount(this.count);
  final int count;
}

class _PageText {
  const _PageText(this.pageNumber, this.text);
  final int pageNumber;
  final String text;
}

/// A small batch of pages. [lastPageAttempted] advances even when every page in
/// the batch failed to extract.
class _ExtractionBatch {
  const _ExtractionBatch({
    required this.pages,
    required this.lastPageAttempted,
    required this.failedPages,
  });

  final List<_PageText> pages;
  final int lastPageAttempted;
  final int failedPages;
}

class _ExtractionComplete {
  const _ExtractionComplete(this.pageCount);
  final int pageCount;
}

class _ExtractionFailure {
  const _ExtractionFailure(this.reason);
  final String reason;
}
