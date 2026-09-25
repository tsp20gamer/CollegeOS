

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

      final bytes = await file.readAsBytes();
      
      // Perform extraction in a background isolate to avoid blocking the UI
      final pages = await compute(_extractPages, bytes);

      if (pages.isEmpty) {
        await _dao.markAsUnsupported(fileId);
      } else {
        await _dao.saveExtractedPages(fileId, pages);
      }
    } catch (e) {
      debugPrint('Error indexing PDF $fileId: $e');
      await _dao.markAsError(fileId);
    }
  }

  static List<String> _extractPages(List<int> bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      
      final pages = <String>[];
      for (int i = 0; i < document.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        pages.add(text);
      }
      
      document.dispose();
      return pages;
    } catch (e) {
      debugPrint('Error in _extractPages: $e');
      return [];
    }
  }
}
