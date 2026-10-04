

import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/notes/domain/pdf_extraction_service.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../core/database/app_database.dart';

@pragma('vm:entry-point')
void pdfIndexingStartCallback() {
  FlutterForegroundTask.setTaskHandler(PdfIndexingTaskHandler());
}

class PdfIndexingTaskHandler extends TaskHandler {
  AppDatabase? _database;
  LocalPdfExtractionService? _extractionService;
  int? _fileId;
  String? _filePath;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('PdfIndexingTaskHandler.onStart() in background isolate');

    // Extract file details passed via FlutterForegroundTask.saveData
    final fileIdStr = await FlutterForegroundTask.getData<String>(key: 'pdf_file_id');
    final filePath = await FlutterForegroundTask.getData<String>(key: 'pdf_file_path');

    if (fileIdStr == null || filePath == null) {
      debugPrint('Missing file info, stopping task');
      await FlutterForegroundTask.stopService();
      return;
    }

    _fileId = int.tryParse(fileIdStr);
    _filePath = filePath;

    if (_fileId == null) {
      debugPrint('Invalid fileId, stopping task');
      await FlutterForegroundTask.stopService();
      return;
    }

    try {
      // Initialize a new database connection inside this isolate
      _database = AppDatabase();
      final dao = PdfSearchDao(_database!);
      const storageService = LocalSubjectFileStorageService();

      _extractionService = LocalPdfExtractionService(dao, storageService);

      // We start indexing asynchronously but don't await it here, because onStart 
      // should return to allow event loops.
      // We will perform the indexing in an unawaited Future.
      _performIndexing();
    } catch (e, st) {
      debugPrint('Failed to start PDF extraction in background: $e\n$st');
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _performIndexing() async {
    try {
      await _extractionService?.indexPdf(
        _fileId!,
        _filePath!,
        onProgress: (pagesIndexed, totalPages) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'CollegeOS',
            notificationText: 'Indexing PDF — $pagesIndexed / $totalPages pages',
          );
          // Send progress back to the main UI isolate
          FlutterForegroundTask.sendDataToMain({
            'event': 'progress',
            'fileId': _fileId,
            'pagesIndexed': pagesIndexed,
            'totalPages': totalPages,
          });
        },
      );
      
      // Indexing complete
      FlutterForegroundTask.sendDataToMain({
        'event': 'complete',
        'fileId': _fileId,
      });
    } catch (e, st) {
      debugPrint('Error indexing in background: $e\n$st');
      FlutterForegroundTask.sendDataToMain({
        'event': 'error',
        'fileId': _fileId,
        'error': e.toString(),
      });
    } finally {
      // Regardless of success or failure, we stop the foreground service
      await FlutterForegroundTask.stopService();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // We don't use periodic repeat events
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('PdfIndexingTaskHandler.onDestroy() in background isolate');
    await _database?.close();
    _database = null;
    _extractionService = null;
  }
}
