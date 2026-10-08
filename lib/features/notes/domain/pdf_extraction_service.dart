import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts PDF text into the FTS5 search index.
abstract interface class PdfExtractionService {
  /// Indexes the text of [relativeFilePath] into `pdf_page_fts`.
  ///
  /// Continues after the last page an interrupted run stored instead of
  /// starting over, skips files that are already indexed, and reports how long
  /// each phase of the run took.
  Future<PdfIndexReport> indexPdf(
    int fileId,
    String relativeFilePath, {
    void Function(int pagesIndexed, int totalPages)? onProgress,
  });
}

/// Pages handed to one database transaction.
///
/// The document stays open across batches; only the writes are grouped so a
/// crash cannot lose more than a handful of pages and memory stays flat.
const int kPagesPerDatabaseBatch = 20;

/// Resident memory the isolate may gain from the open document before it is
/// disposed and reopened.
///
/// Syncfusion retains parsed pages, page resources and decoded image XObjects
/// inside a [PdfDocument] for as long as it stays alive: on a 99 MB / 412 page
/// text PDF that measured ~3 MB per page, ~1.4 GB for a whole document, and
/// disposing the document is the only way to give it back (the package exposes
/// no public cache flush). A document is therefore opened once per file and only
/// recycled when the process really grows past this budget - never once per
/// batch. Ordinary course PDFs stay well below it and are read from one open.
///
/// A negative budget forces a recycle after every batch, which is what the tests
/// use to exercise that path without allocating gigabytes.
const int kDocumentMemoryBudgetBytes = 128 * 1024 * 1024;

/// How an indexing run ended.
enum PdfIndexOutcome {
  /// Every page of the document is in the FTS index, either from this run or
  /// from an interrupted run that this one continued.
  indexed,

  /// The file was already fully indexed; nothing was read or written.
  skipped,

  /// The document has no pages that can be extracted.
  unsupported,

  /// The run failed. Pages already stored are kept so a retry can resume.
  failed,
}

/// Timings and result of a single [PdfExtractionService.indexPdf] call.
final class PdfIndexReport {
  const PdfIndexReport({
    required this.outcome,
    required this.pageCount,
    required this.pagesIndexed,
    required this.resumedFromPage,
    required this.failedPages,
    required this.documentRecycles,
    required this.openTime,
    required this.extractionTime,
    required this.databaseTime,
    required this.totalTime,
    this.parallelWorkers = 1,
  });

  PdfIndexReport.failed(Duration total)
    : this(
        outcome: PdfIndexOutcome.failed,
        pageCount: 0,
        pagesIndexed: 0,
        resumedFromPage: 0,
        failedPages: 0,
        documentRecycles: 0,
        openTime: Duration.zero,
        extractionTime: Duration.zero,
        databaseTime: Duration.zero,
        totalTime: total,
      );

  PdfIndexReport.skipped({
    required int pageCount,
    required int resumedFromPage,
    required Duration total,
  }) : this(
         outcome: PdfIndexOutcome.skipped,
         pageCount: pageCount,
         pagesIndexed: 0,
         resumedFromPage: resumedFromPage,
         failedPages: 0,
         documentRecycles: 0,
         openTime: Duration.zero,
         extractionTime: Duration.zero,
         databaseTime: Duration.zero,
         totalTime: total,
       );

  final PdfIndexOutcome outcome;

  /// Pages in the document, or `0` when the document could not be read.
  final int pageCount;

  /// Pages this run extracted (pages that failed to extract are counted too,
  /// because their position is recorded as indexed).
  final int pagesIndexed;

  /// Highest page already stored when this run started (`0` for a fresh file).
  final int resumedFromPage;

  /// Pages that could not be extracted and were skipped.
  final int failedPages;

  /// How often the open document had to be disposed and reopened because the
  /// isolate grew past its memory budget. `0` means the document was opened
  /// exactly once for the whole run.
  final int documentRecycles;

  /// Time spent constructing [PdfDocument] (once, plus any recycle).
  final Duration openTime;

  /// Time spent in [PdfTextExtractor.extractText].
  final Duration extractionTime;

  /// Time spent writing to SQLite (page batches, progress, final status).
  final Duration databaseTime;

  /// Wall clock time of the whole call.
  final Duration totalTime;

  /// The number of isolates used in extraction.
  final int parallelWorkers;

  @override
  String toString() =>
      'PdfIndexReport(${outcome.name}, pages $pagesIndexed/$pageCount, '
      'workers $parallelWorkers, '
      'resumed from $resumedFromPage, failed $failedPages, '
      'document recycles $documentRecycles, '
      'open ${openTime.inMilliseconds}ms, '
      'extract ${extractionTime.inMilliseconds}ms, '
      'db ${databaseTime.inMilliseconds}ms, '
      'total ${totalTime.inMilliseconds}ms)';
}

final class LocalPdfExtractionService implements PdfExtractionService {
  LocalPdfExtractionService(
    this._dao,
    this._storageService, {
    this.documentMemoryBudgetBytes = kDocumentMemoryBudgetBytes,
    this.useParallel = true,
  });

  final PdfSearchDao _dao;
  final SubjectFileStorageService _storageService;

  /// Whether to attempt parallel extraction using exactly 2 isolates.
  /// Falls back to single isolate if system resources (e.g. processor count)
  /// are highly constrained.
  final bool useParallel;

  /// Document recycle threshold. Tests pass a tiny budget to force the
  /// recycle path without allocating gigabytes.
  final int documentMemoryBudgetBytes;

  /// System capability check: do not spin up extra workers on devices
  /// with <= 2 cores.
  bool get _canSafelyUseParallelWorkers => Platform.numberOfProcessors > 2;

  @override
  Future<PdfIndexReport> indexPdf(
    int fileId,
    String relativeFilePath, {
    void Function(int pagesIndexed, int totalPages)? onProgress,
  }) async {
    final total = Stopwatch()..start();

    // Never re-extract a document that is already fully indexed: the pages are
    // still in pdf_page_fts, so any further work would be wasted. This runs
    // before the file is touched so an indexed file is never even read.
    final meta = await _dao.getMetadata(fileId);
    if (meta != null &&
        meta.status == 'indexed' &&
        meta.pageCount > 0 &&
        meta.lastIndexedPage >= meta.pageCount) {
      debugPrint(
        'PdfIndex[$fileId] already indexed (${meta.pageCount} pages), skipping',
      );
      return PdfIndexReport.skipped(
        pageCount: meta.pageCount,
        resumedFromPage: meta.lastIndexedPage,
        total: total.elapsed,
      );
    }

    File file;
    try {
      file = await _storageService.resolveFile(relativeFilePath);
    } catch (e) {
      debugPrint('Could not resolve PDF $fileId: $e');
      await _dao.markAsError(fileId);
      return PdfIndexReport.failed(total.elapsed);
    }

    if (!await file.exists()) {
      await _dao.markAsError(fileId);
      return PdfIndexReport.failed(total.elapsed);
    }

    // Keeps every page a previous run stored and reports where to continue.
    final start = await _dao.beginIndexing(fileId);
    if (start.resumeFromPage > 0) {
      debugPrint(
        'PdfIndex[$fileId] resuming after page ${start.resumeFromPage} '
        'of ${start.previousPageCount}',
      );
    }

    if (useParallel && _canSafelyUseParallelWorkers) {
      return _indexPdfParallel(fileId, file, total, start, onProgress);
    }

    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    Isolate? isolate;
    Timer? watchdog;

    // The isolate decides which pages were read, but the main isolate decides
    // how the operation ended, so an isolate that dies without reporting (hard
    // OOM, process level kill) cannot leave the row stuck on `indexing`.
    var terminal = false;
    var totalPages = start.previousPageCount;
    var lastIndexedPage = start.resumeFromPage;
    var firstPageOfRun = 0;
    var pagesIndexed = 0;
    var failedPages = 0;
    var openMillis = 0;
    var extractMillis = 0;
    var databaseMillis = 0;
    var recycles = 0;
    var unsupported = false;

    final outcome = Completer<String?>(); // null == completed fine

    void finish(String? failure) {
      if (outcome.isCompleted) return;
      outcome.complete(failure);
    }

    try {
      isolate = await Isolate.spawn(
        _extractPagesIsolate,
        _ExtractionParams(
          filePath: file.path,
          sendPort: receivePort.sendPort,
          resumeFromPage: start.resumeFromPage,
          expectedPageCount: start.previousPageCount,
          memoryBudgetBytes: documentMemoryBudgetBytes,
        ),
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
          case _ExtractionStarted(
            :final pageCount,
            :final restarting,
            :final firstPage,
          ):
            totalPages = pageCount;
            firstPageOfRun = firstPage;
            if (pageCount == 0) {
              unsupported = true;
              terminal = true;
              await _dao.markAsUnsupported(fileId);
              finish(null);
              break;
            }
            if (restarting) {
              // The document no longer matches the stored index (different page
              // count), so the stored pages cannot be reused.
              debugPrint(
                'PdfIndex[$fileId] document changed ($pageCount pages vs '
                '$lastIndexedPage indexed), rebuilding from page 1',
              );
              final dbWatch = Stopwatch()..start();
              await _dao.deleteFilePages(fileId);
              dbWatch.stop();
              databaseMillis += dbWatch.elapsedMilliseconds;
              lastIndexedPage = 0;
            }
          case _ExtractionBatch(
            :final pages,
            :final lastPageAttempted,
            failedPages: final batchFailures,
            openMillis: final isolateOpenMillis,
            extractMillis: final isolateExtractMillis,
            :final pagesExtracted,
            recycles: final isolateRecycles,
          ):
            openMillis = isolateOpenMillis;
            extractMillis = isolateExtractMillis;
            recycles = isolateRecycles;
            if (batchFailures > 0) {
              failedPages += batchFailures;
              debugPrint(
                'PDF $fileId: $batchFailures page(s) could not be extracted '
                '(skipped, indexing continues)',
              );
            }
            // One transaction per batch: pages and the progress metadata that
            // describes them are written together, so an interruption resumes
            // exactly where the stored text ends.
            final dbWatch = Stopwatch()..start();
            await _dao.saveExtractedBatch(
              fileId,
              [
                for (final page in pages)
                  PdfExtractedPage(
                    pageNumber: page.pageNumber,
                    text: page.text,
                  ),
              ],
              lastPageIndexed: lastPageAttempted,
              totalPages: totalPages == 0 ? lastPageAttempted : totalPages,
            );
            dbWatch.stop();
            databaseMillis += dbWatch.elapsedMilliseconds;
            lastIndexedPage = lastPageAttempted;
            pagesIndexed = pagesExtracted;
            if (onProgress != null) {
              onProgress(
                lastIndexedPage,
                totalPages == 0 ? lastPageAttempted : totalPages,
              );
            }
            debugPrint(
              'PdfIndex[$fileId] $lastPageAttempted/$totalPages pages '
              '(open $openMillis ms, extract $extractMillis ms, '
              'db $databaseMillis ms)',
            );
          case _ExtractionComplete(
            :final pageCount,
            :final pagesExtracted,
            failedPages: final runFailures,
            openMillis: final isolateOpenMillis,
            extractMillis: final isolateExtractMillis,
            recycles: final isolateRecycles,
          ):
            terminal = true;
            openMillis = isolateOpenMillis;
            extractMillis = isolateExtractMillis;
            recycles = isolateRecycles;
            failedPages = runFailures;
            pagesIndexed = pagesExtracted;
            final completedPages = pageCount == 0 ? totalPages : pageCount;
            final dbWatch = Stopwatch()..start();
            await _dao.completeIndexing(fileId, completedPages);
            dbWatch.stop();
            databaseMillis += dbWatch.elapsedMilliseconds;
            lastIndexedPage = completedPages;
            totalPages = completedPages;
            finish(null);
          case _ExtractionFailure(:final reason):
            terminal = true;
            debugPrint('PDF extraction failed for $fileId: $reason');
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
        // Keep how far the run got so the next attempt can continue instead of
        // re-extracting pages that are already stored.
        await _dao.markAsError(
          fileId,
          pageCount: totalPages,
          lastIndexedPage: lastIndexedPage,
        );
      }
    } on OutOfMemoryError {
      debugPrint('Out of memory while indexing PDF $fileId');
      isolate?.kill(priority: Isolate.immediate);
      await _dao.markAsError(
        fileId,
        pageCount: totalPages,
        lastIndexedPage: lastIndexedPage,
      );
      finish('out of memory');
    } catch (e) {
      debugPrint('Error indexing PDF $fileId: $e');
      isolate?.kill(priority: Isolate.immediate);
      await _dao.markAsError(
        fileId,
        pageCount: totalPages,
        lastIndexedPage: lastIndexedPage,
      );
      finish(e.toString());
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

    total.stop();
    final failure = outcome.isCompleted ? await outcome.future : null;
    final result = PdfIndexReport(
      outcome: failure != null
          ? PdfIndexOutcome.failed
          : (unsupported
                ? PdfIndexOutcome.unsupported
                : PdfIndexOutcome.indexed),
      pageCount: totalPages,
      pagesIndexed: pagesIndexed,
      resumedFromPage: start.resumeFromPage,
      failedPages: failedPages,
      documentRecycles: recycles,
      openTime: Duration(milliseconds: openMillis),
      extractionTime: Duration(milliseconds: extractMillis),
      databaseTime: Duration(milliseconds: databaseMillis),
      totalTime: total.elapsed,
    );
    final seconds = total.elapsedMilliseconds / 1000;
    final rate = seconds <= 0
        ? 'n/a'
        : (pagesIndexed / seconds).toStringAsFixed(1);
    debugPrint(
      'PdfIndex[$fileId] ${result.outcome.name} in '
      '${total.elapsedMilliseconds} ms ($rate pages/s): '
      'open $openMillis ms, extract $extractMillis ms, '
      'database $databaseMillis ms, '
      'pages ${firstPageOfRun == 0 ? pagesIndexed : '$firstPageOfRun-$lastIndexedPage'} '
      'of $totalPages, resumed from ${start.resumeFromPage}'
      '${recycles > 0 ? ', document recycles $recycles' : ''}'
      '${failedPages > 0 ? ', failed pages $failedPages' : ''}',
    );
    return result;
  }

  /// Reads, extracts and reports pages from one open document.
  ///
  /// The isolate receives only the file path, never the PDF bytes, so no
  /// document buffer is ever serialised across isolates. Syncfusion's reader has
  /// no file backed or streaming constructor: it only accepts the complete
  /// document as a `List<int>` (`PdfDocument(inputBytes: ...)`), so one buffer
  /// for the whole file is the lowest memory input this package supports. The
  /// file is read exactly once, trimmed once and the same [Uint8List] is handed
  /// to every document instance (Syncfusion keeps the reference, it does not
  /// copy it).
  ///
  /// The document is opened once and its pages are then extracted in order, one
  /// page at a time, while the finished pages are handed to the database in
  /// batches. Measured on a 99 MB / 412 page text PDF the open itself is cheap
  /// (~10 ms), but the old per batch reopen paid it 21 times and, for a file
  /// carrying bytes after the last `%%EOF`, each of those opens also copied the
  /// whole document: 29.6 s of opens, 3.9 GB peak and a 1.77x slower run, which
  /// the single open removes.
  static Future<void> _extractPagesIsolate(_ExtractionParams params) async {
    final sendPort = params.sendPort;
    Uint8List? buffer;
    PdfDocument? document;
    var openMillis = 0;
    var extractMillis = 0;
    var recycles = 0;

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

      final (opened, initialOpenMillis) = _open(data);
      document = opened;
      openMillis += initialOpenMillis;

      final pageCount = document.pages.count;
      if (pageCount == 0) {
        sendPort.send(
          const _ExtractionStarted(
            pageCount: 0,
            restarting: false,
            firstPage: 0,
          ),
        );
        sendPort.send(
          _ExtractionComplete(
            pageCount: 0,
            pagesExtracted: 0,
            failedPages: 0,
            openMillis: openMillis,
            extractMillis: extractMillis,
            recycles: recycles,
          ),
        );
        return;
      }

      // Reuse the stored pages only when they were produced from this exact
      // document; a different page count means the file changed.
      final restarting =
          params.expectedPageCount != 0 &&
          params.expectedPageCount != pageCount;
      var index = restarting ? 0 : math.min(params.resumeFromPage, pageCount);
      sendPort.send(
        _ExtractionStarted(
          pageCount: pageCount,
          restarting: restarting,
          firstPage: index >= pageCount ? 0 : index + 1,
        ),
      );

      // Memory the open document may add on top of this baseline. The baseline
      // is re-measured after every recycle so the budget always describes one
      // document instance instead of triggering another reopen immediately.
      var memoryBaseline = ProcessInfo.currentRss;
      var extractor = PdfTextExtractor(document);
      final batch = <_PageText>[];
      var pagesExtracted = 0;
      var failedPages = 0;

      while (index < pageCount) {
        final pageWatch = Stopwatch()..start();
        try {
          final text = extractor.extractText(
            startPageIndex: index,
            endPageIndex: index,
          );
          batch.add(_PageText(index + 1, text));
        } catch (e) {
          failedPages++;
          debugPrint('Failed to extract page ${index + 1}: $e');
        }
        pageWatch.stop();
        extractMillis += pageWatch.elapsedMilliseconds;
        index++;
        pagesExtracted++;

        if (batch.length < kPagesPerDatabaseBatch && index < pageCount) {
          continue;
        }

        sendPort.send(
          _ExtractionBatch(
            pages: List<_PageText>.of(batch),
            lastPageAttempted: index,
            failedPages: failedPages,
            openMillis: openMillis,
            extractMillis: extractMillis,
            pagesExtracted: pagesExtracted,
            recycles: recycles,
          ),
        );
        batch.clear();
        failedPages = 0;

        if (index >= pageCount) break;

        // Only real memory pressure reopens the document. One long lived
        // document keeps every parsed page it has touched, so this is what caps
        // the isolate on very large files; small files never reach it.
        final retained = ProcessInfo.currentRss - memoryBaseline;
        if (!_shouldRecycleDocument(retained, params.memoryBudgetBytes)) {
          continue;
        }
        recycles++;
        debugPrint(
          'PdfIndex: recycling the open document at page $index '
          '(${retained ~/ (1024 * 1024)} MB retained, budget '
          '${params.memoryBudgetBytes ~/ (1024 * 1024)} MB)',
        );
        document!.dispose();
        final (reopened, reopenMillis) = _open(data);
        document = reopened;
        openMillis += reopenMillis;
        extractor = PdfTextExtractor(document);
        memoryBaseline = ProcessInfo.currentRss;
      }

      sendPort.send(
        _ExtractionComplete(
          pageCount: pageCount,
          pagesExtracted: pagesExtracted,
          failedPages: failedPages,
          openMillis: openMillis,
          extractMillis: extractMillis,
          recycles: recycles,
        ),
      );
    } on OutOfMemoryError {
      debugPrint('Out of memory extracting PDF ${params.filePath}');
      sendPort.send(const _ExtractionFailure('out of memory'));
    } catch (e) {
      debugPrint('Error in _extractPagesIsolate: $e');
      sendPort.send(_ExtractionFailure(e.toString()));
    } finally {
      document?.dispose();
      buffer = null;
    }
  }

  /// Whether the open document has to be recycled after [retainedBytes] of
  /// process growth against [budgetBytes]. A negative budget forces a recycle,
  /// which is how the tests exercise that path.
  static bool _shouldRecycleDocument(int retainedBytes, int budgetBytes) =>
      budgetBytes < 0 || retainedBytes >= budgetBytes;

  /// Opens the document and reports how long the open itself took.
  static (PdfDocument, int) _open(Uint8List data) {
    final watch = Stopwatch()..start();
    final document = PdfDocument(inputBytes: data);
    watch.stop();
    return (document, watch.elapsedMilliseconds);
  }

  /// Returns [bytes] ending exactly at the last `%%EOF` marker when anything
  /// other than trailing whitespace follows it.
  ///
  /// Syncfusion's cross table reader rereads the document tail and, if it finds
  /// a token after the final `%%EOF`, builds a *copy* of the entire file as a
  /// growable `List<int>` (about eight bytes of heap per byte of PDF) each time
  /// a document is constructed. On the measured 91 MB file that cost ~700 MB per
  /// `PdfDocument` creation, ~1.9 GB peak and a 2.7x slower run. The view
  /// returned here shares the existing buffer (no allocation) and covers exactly
  /// the byte range Syncfusion would otherwise have kept, so the extracted text
  /// is unchanged.
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

  Future<PdfIndexReport> _indexPdfParallel(
    int fileId,
    File file,
    Stopwatch totalWatch,
    PdfIndexStart start,
    void Function(int pagesIndexed, int totalPages)? onProgress,
  ) async {
    // 2-isolate parallel extraction implementation for benchmarking.
    // 1. Establish coordination state.
    var terminal = false;
    var totalPages = start.previousPageCount;
    var lastIndexedPage = start.resumeFromPage;
    var pagesIndexed = 0;
    var failedPages = 0;
    var openMillis = 0;
    var extractMillis = 0;
    var databaseMillis = 0;
    var recycles = 0;
    var unsupported = false;

    final outcome = Completer<String?>();

    // First, let's open the document in the main isolate to get page count and do db reset if needed.
    // Wait! Opening in main isolate blocks the UI. We'll spawn one "probe" isolate or just have workers do it.
    // Let's spawn 2 workers.
    final numWorkers = 2;
    final receivePorts = List.generate(numWorkers, (_) => ReceivePort());
    final exitPorts = List.generate(numWorkers, (_) => ReceivePort());
    final errorPorts = List.generate(numWorkers, (_) => ReceivePort());
    final isolates = <Isolate>[];
    final sendPorts = <SendPort>[];

    // Worker message definitions
    // These will be received as maps to simplify things without defining new global classes.

    void finish(String? failure) {
      if (!outcome.isCompleted) outcome.complete(failure);
    }

    final pageCountPort = ReceivePort();
    final batchPorts = <ReceivePort>[];
    try {
      for (int i = 0; i < numWorkers; i++) {
        final isolate = await Isolate.spawn(
          _parallelWorkerIsolate,
          {
            'filePath': file.path,
            'sendPort': receivePorts[i].sendPort,
            'memoryBudgetBytes': documentMemoryBudgetBytes,
          },
          onError: errorPorts[i].sendPort,
          onExit: exitPorts[i].sendPort,
          errorsAreFatal: false,
        );
        isolates.add(isolate);

        errorPorts[i].listen((err) {
          if (!terminal) finish('isolate error: $err');
        });
        exitPorts[i].listen((_) {
          if (!terminal && sendPorts.length < numWorkers) {
            finish('isolate exited early');
          }
        });
      }

      // Wait for both workers to send their SendPorts
      final sendPortsCompleter = Completer<void>();
      for (int i = 0; i < numWorkers; i++) {
        receivePorts[i].listen((msg) {
          if (msg is SendPort) {
            sendPorts.add(msg);
            if (sendPorts.length == numWorkers &&
                !sendPortsCompleter.isCompleted) {
              sendPortsCompleter.complete();
            }
          } else if (msg is Map && msg['type'] == 'error') {
            finish(msg['reason']);
          }
        });
      }

      await Future.any([
        sendPortsCompleter.future,
        outcome.future.then((v) => throw Exception(v ?? 'aborted')),
      ]);

      if (outcome.isCompleted) throw Exception(await outcome.future);

      // Ask worker 0 for the document page count

      sendPorts[0].send({
        'type': 'getPageCount',
        'replyTo': pageCountPort.sendPort,
      });
      final countMsg = await Future.any([
        pageCountPort.first,
        outcome.future.then((v) => throw Exception(v ?? 'aborted')),
      ]);
      if (countMsg is Map && countMsg['type'] == 'error') {
        finish(countMsg['reason']);
        throw Exception(countMsg['reason']);
      }
      final pageCount = (countMsg as Map)['pageCount'] as int;
      final workerOpenMillis = countMsg['openMillis'] as int;
      openMillis += workerOpenMillis;

      totalPages = pageCount;
      if (pageCount == 0) {
        unsupported = true;
        terminal = true;
        await _dao.markAsUnsupported(fileId);
        finish(null);
      } else {
        final restarting =
            start.previousPageCount != 0 &&
            start.previousPageCount != pageCount;
        if (restarting) {
          final dbWatch = Stopwatch()..start();
          await _dao.deleteFilePages(fileId);
          dbWatch.stop();
          databaseMillis += dbWatch.elapsedMilliseconds;
          lastIndexedPage = 0;
        }

        final startIndex = restarting
            ? 0
            : math.min(start.resumeFromPage, pageCount);
        int nextBatchStartIndex = startIndex;

        // We will assign batches to workers.
        final batchSize = kPagesPerDatabaseBatch;

        // Setup coordination variables
        int activeWorkers = numWorkers;
        Map<int, Map> completedBatches = {};
        int nextBatchToWrite = nextBatchStartIndex; // keyed by page start index

        // Create an event loop to handle worker messages. We will listen to all workers.
        // To simplify, we map each worker's stream into a unified stream with worker ID.
        final StreamController<Map> unifiedStream = StreamController<Map>();
        final subs = <StreamSubscription>[];
        for (int i = 0; i < numWorkers; i++) {
          final rp = ReceivePort();
          batchPorts.add(rp);
          // send new communication port for batches to worker
          sendPorts[i].send({'type': 'initStream', 'replyTo': rp.sendPort});
          subs.add(
            rp.listen((msg) {
              if (msg is Map) {
                final Map<String, dynamic> m = Map<String, dynamic>.from(msg);
                m['workerId'] = i;
                unifiedStream.add(m);
              }
            }),
          );
        }

        void assignBatch(int workerId) {
          if (nextBatchStartIndex >= pageCount) {
            // No more work
            sendPorts[workerId].send({'type': 'stop'});
            return;
          }
          final end = math.min(nextBatchStartIndex + batchSize, pageCount);
          sendPorts[workerId].send({
            'type': 'extract',
            'start': nextBatchStartIndex,
            'end': end,
          });
          nextBatchStartIndex = end;
        }

        // Initial assignment
        for (int i = 0; i < numWorkers; i++) {
          assignBatch(i);
        }

        // Event loop
        await for (final msg in unifiedStream.stream) {
          if (outcome.isCompleted) break;
          if (msg['type'] == 'error') {
            finish(msg['reason']);
            break;
          } else if (msg['type'] == 'stopped') {
            activeWorkers--;
            if (activeWorkers == 0) {
              finish(null);
              break;
            }
          } else if (msg['type'] == 'batch') {
            final workerId = msg['workerId'];
            final batchStart = msg['start'] as int;
            completedBatches[batchStart] = msg;

            // Try to write contiguous completed batches
            while (completedBatches.containsKey(nextBatchToWrite)) {
              final batchMsg = completedBatches.remove(nextBatchToWrite)!;
              final pagesData = batchMsg['pages'] as List; // list of maps
              final batchFailures = batchMsg['failedPages'] as int;
              final batchEnd =
                  batchMsg['end'] as int; // actually last attempted
              openMillis += batchMsg['openMillis'] as int;
              extractMillis += batchMsg['extractMillis'] as int;
              recycles += batchMsg['recycles'] as int;

              if (batchFailures > 0) failedPages += batchFailures;
              pagesIndexed += pagesData.length;

              final dbWatch = Stopwatch()..start();
              await _dao.saveExtractedBatch(
                fileId,
                [
                  for (final p in pagesData)
                    PdfExtractedPage(
                      pageNumber: p['pageNumber'],
                      text: p['text'],
                    ),
                ],
                lastPageIndexed: batchEnd,
                totalPages: pageCount,
              );
              dbWatch.stop();
              databaseMillis += dbWatch.elapsedMilliseconds;
              lastIndexedPage = batchEnd;
              nextBatchToWrite = batchEnd;
              if (onProgress != null) {
                onProgress(
                  lastIndexedPage,
                  pageCount == 0 ? batchEnd : pageCount,
                );
              }
            }

            // Assign next batch to this worker
            assignBatch(workerId);
          }
        }

        for (var sub in subs) {
          sub.cancel();
        }
        unifiedStream.close();
      }

      final failure = await outcome.future;
      if (failure != null) {
        terminal = true;
        for (var iso in isolates) {
          iso.kill(priority: Isolate.immediate);
        }
        await _dao.markAsError(
          fileId,
          pageCount: totalPages,
          lastIndexedPage: lastIndexedPage,
        );
      } else {
        terminal = true;
        final completedPages = pageCount == 0 ? totalPages : pageCount;
        final dbWatch = Stopwatch()..start();
        await _dao.completeIndexing(fileId, completedPages);
        dbWatch.stop();
        databaseMillis += dbWatch.elapsedMilliseconds;
        lastIndexedPage = completedPages;
        totalPages = completedPages;
      }
    } on OutOfMemoryError {
      finish('out of memory');
      for (var iso in isolates) {
        iso.kill(priority: Isolate.immediate);
      }
      await _dao.markAsError(
        fileId,
        pageCount: totalPages,
        lastIndexedPage: lastIndexedPage,
      );
    } catch (e) {
      finish(e.toString());
      for (var iso in isolates) {
        iso.kill(priority: Isolate.immediate);
      }
      await _dao.markAsError(
        fileId,
        pageCount: totalPages,
        lastIndexedPage: lastIndexedPage,
      );
    } finally {
      for (var iso in isolates) {
        iso.kill();
      }
      for (var p in receivePorts) {
        p.close();
      }
      for (var p in errorPorts) {
        p.close();
      }
      for (var p in exitPorts) {
        p.close();
      }
      pageCountPort.close();
      for (var p in batchPorts) {
        p.close();
      }
      if (!outcome.isCompleted) outcome.complete('aborted');
    }

    totalWatch.stop();
    final failure = outcome.isCompleted ? await outcome.future : null;
    return PdfIndexReport(
      outcome: failure != null
          ? PdfIndexOutcome.failed
          : (unsupported
                ? PdfIndexOutcome.unsupported
                : PdfIndexOutcome.indexed),
      pageCount: totalPages,
      pagesIndexed: pagesIndexed,
      resumedFromPage: start.resumeFromPage,
      failedPages: failedPages,
      documentRecycles: recycles,
      openTime: Duration(milliseconds: openMillis),
      extractionTime: Duration(milliseconds: extractMillis),
      databaseTime: Duration(milliseconds: databaseMillis),
      totalTime: totalWatch.elapsed,
      parallelWorkers: numWorkers,
    );
  }

  static Future<void> _parallelWorkerIsolate(
    Map<String, dynamic> params,
  ) async {
    final initSendPort = params['sendPort'] as SendPort;
    final filePath = params['filePath'] as String;
    final memoryBudget = params['memoryBudgetBytes'] as int;

    final workerReceivePort = ReceivePort();
    initSendPort.send(workerReceivePort.sendPort);

    Uint8List? buffer;
    PdfDocument? document;
    var openMillis = 0;
    var extractMillis = 0;
    var recycles = 0;
    var memoryBaseline = ProcessInfo.currentRss;
    PdfTextExtractor? extractor;

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        initSendPort.send({'type': 'error', 'reason': 'file missing'});
        return;
      }

      buffer = file.readAsBytesSync();
      final data = _trimTrailingBytesAfterEndOfFile(buffer);

      final (opened, ms) = _open(data);
      document = opened;
      openMillis += ms;
      extractor = PdfTextExtractor(document);
      memoryBaseline = ProcessInfo.currentRss;

      SendPort? streamPort;

      await for (final msg in workerReceivePort) {
        if (msg is Map) {
          if (msg['type'] == 'getPageCount') {
            final replyTo = msg['replyTo'] as SendPort;
            replyTo.send({
              'pageCount': document!.pages.count,
              'openMillis': openMillis,
            });
            openMillis = 0; // reset so we don't double count
          } else if (msg['type'] == 'initStream') {
            streamPort = msg['replyTo'] as SendPort;
          } else if (msg['type'] == 'extract') {
            final start = msg['start'] as int;
            final end = msg['end'] as int; // exclusive

            final pages = [];
            int failed = 0;
            for (int i = start; i < end; i++) {
              final watch = Stopwatch()..start();
              try {
                final text = extractor!.extractText(
                  startPageIndex: i,
                  endPageIndex: i,
                );
                pages.add({'pageNumber': i + 1, 'text': text});
              } catch (e) {
                failed++;
              }
              watch.stop();
              extractMillis += watch.elapsedMilliseconds;
            }

            streamPort!.send({
              'type': 'batch',
              'start': start,
              'end': end,
              'pages': pages,
              'failedPages': failed,
              'openMillis': openMillis,
              'extractMillis': extractMillis,
              'recycles': recycles,
            });
            openMillis = 0;
            extractMillis = 0;
            recycles = 0;

            // Check memory
            final retained = ProcessInfo.currentRss - memoryBaseline;
            if (_shouldRecycleDocument(retained, memoryBudget)) {
              document!.dispose();
              final (reopened, ms) = _open(data);
              document = reopened;
              openMillis += ms;
              extractor = PdfTextExtractor(document);
              memoryBaseline = ProcessInfo.currentRss;
              recycles++;
            }
          } else if (msg['type'] == 'stop') {
            streamPort?.send({'type': 'stopped'});
            break;
          }
        }
      }
    } catch (e) {
      initSendPort.send({'type': 'error', 'reason': e.toString()});
    } finally {
      document?.dispose();
      workerReceivePort.close();
    }
  }
}

// -- Isolate Messaging Classes --

class _ExtractionParams {
  const _ExtractionParams({
    required this.filePath,
    required this.sendPort,
    required this.resumeFromPage,
    required this.expectedPageCount,
    required this.memoryBudgetBytes,
  });

  final String filePath;
  final SendPort sendPort;

  /// Highest page a previous run stored; extraction continues at the next one.
  final int resumeFromPage;

  /// Page count that previous run recorded, `0` when unknown.
  final int expectedPageCount;

  /// Resident memory the open document may add before it is recycled.
  final int memoryBudgetBytes;
}

/// Reported once, right after the single document open, before any batch.
class _ExtractionStarted {
  const _ExtractionStarted({
    required this.pageCount,
    required this.restarting,
    required this.firstPage,
  });

  /// First page this run extracts, `0` when there is nothing left to do.
  final int firstPage;

  final int pageCount;

  /// True when the stored index belongs to a different document and has to be
  /// cleared before the first batch is written.
  final bool restarting;
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
    required this.openMillis,
    required this.extractMillis,
    required this.pagesExtracted,
    required this.recycles,
  });

  final List<_PageText> pages;
  final int lastPageAttempted;

  /// Pages of this batch that could not be extracted.
  final int failedPages;

  /// Cumulative timing of the run so far, so progress can be logged while it
  /// happens instead of only at the end.
  final int openMillis;
  final int extractMillis;

  /// Pages this run has walked so far.
  final int pagesExtracted;

  /// How often the open document had to be recycled for memory.
  final int recycles;
}

class _ExtractionComplete {
  const _ExtractionComplete({
    required this.pageCount,
    required this.pagesExtracted,
    required this.failedPages,
    required this.openMillis,
    required this.extractMillis,
    required this.recycles,
  });

  final int pageCount;
  final int pagesExtracted;
  final int failedPages;
  final int openMillis;
  final int extractMillis;
  final int recycles;
}

class _ExtractionFailure {
  const _ExtractionFailure(this.reason);
  final String reason;
}
