

import 'dart:io';
import 'dart:isolate';

import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

abstract interface class PdfExtractionService {
  Future<void> indexPdf(int fileId, String relativeFilePath);
}

final class LocalPdfExtractionService implements PdfExtractionService {
  LocalPdfExtractionService(this._dao, this._storageService);

  final PdfSearchDao _dao;
  final SubjectFileStorageService _storageService;

  @override
  Future<void> indexPdf(int fileId, String relativeFilePath) async {
    try {
      final file = await _storageService.resolveFile(relativeFilePath);
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
      await Isolate.spawn(
        _extractPagesIsolate,
        _ExtractionParams(file.path, receivePort.sendPort),
      );

      int totalPages = 0;

      await for (final message in receivePort) {
        if (message is _ExtractionPageCount) {
          totalPages = message.count;
          if (totalPages == 0) {
            await _dao.markAsUnsupported(fileId);
            receivePort.close();
          }
        } else if (message is _ExtractionProgress) {
          // Wrap in a transaction for better performance
          await _dao.transaction(() async {
            for (final page in message.pages) {
              await _dao.saveExtractedPage(fileId, page.pageNumber, page.text);
            }
          });
          
          await _dao.updateProgress(fileId, message.pages.last.pageNumber, totalPages);
        } else if (message is _ExtractionComplete) {
          await _dao.completeIndexing(fileId, totalPages);
          receivePort.close();
        } else if (message is _ExtractionError) {
          await _dao.markAsError(fileId);
          receivePort.close();
        }
      }
    } catch (e) {
      debugPrint('Error indexing PDF $fileId: $e');
      await _dao.markAsError(fileId);
    }
  }

  static void _extractPagesIsolate(_ExtractionParams params) {
    try {
      final file = File(params.filePath);
      if (!file.existsSync()) {
        params.sendPort.send(const _ExtractionError());
        return;
      }

      // Load bytes strictly inside the isolate
      final bytes = file.readAsBytesSync();
      
      int pageCount = 0;
      {
        // First pass: just get the page count
        final document = PdfDocument(inputBytes: bytes);
        pageCount = document.pages.count;
        document.dispose();
      }

      params.sendPort.send(_ExtractionPageCount(pageCount));
      if (pageCount == 0) return;

      // Extract in chunks to strictly bound memory usage
      // Syncfusion caches objects internally. Disposing and recreating
      // the document periodically ensures the cache is flushed.
      const chunkSize = 20;
      for (int i = 0; i < pageCount; i += chunkSize) {
        final document = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(document);
        
        final end = (i + chunkSize - 1 < pageCount) ? i + chunkSize - 1 : pageCount - 1;
        
        final chunkPages = <_PageText>[];
        for (int j = i; j <= end; j++) {
          try {
            final text = extractor.extractText(startPageIndex: j, endPageIndex: j);
            chunkPages.add(_PageText(j + 1, text));
          } catch (e) {
            // Ignore extraction failure for a single page
            debugPrint('Failed to extract page $j: $e');
          }
        }
        
        // Send back the batch of pages
        if (chunkPages.isNotEmpty) {
          params.sendPort.send(_ExtractionProgress(chunkPages));
        }
        
        document.dispose();
      }

      params.sendPort.send(const _ExtractionComplete());
    } on OutOfMemoryError {
      debugPrint('OOM extracting PDF in isolate: ${params.filePath}');
      params.sendPort.send(const _ExtractionError());
    } catch (e) {
      debugPrint('Error in _extractPagesIsolate: $e');
      params.sendPort.send(const _ExtractionError());
    }
  }
}

// -- Isolate Messaging Classes --

class _ExtractionParams {
  const _ExtractionParams(this.filePath, this.sendPort);
  final String filePath;
  final SendPort sendPort;
}

class _ExtractionPageCount {
  const _ExtractionPageCount(this.count);
  final int count;
}

class _PageText {
  const _PageText(this.pageNumber, this.text);
  final int pageNumber;
  final String text;
}

class _ExtractionProgress {
  const _ExtractionProgress(this.pages);
  final List<_PageText> pages;
}

class _ExtractionComplete {
  const _ExtractionComplete();
}

class _ExtractionError {
  const _ExtractionError();
}
