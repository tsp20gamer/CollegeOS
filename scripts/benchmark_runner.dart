import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:college_os/features/notes/domain/pdf_extraction_service.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

class DummyStorageService implements SubjectFileStorageService {
  @override
  Future<File> resolveFile(String relativePath) async {
    return File(relativePath);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('run benchmarks', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final dao = PdfSearchDao(db);
    final storage = DummyStorageService();
    
    // Create a dummy file in the database
    // We need to bypass the file insertion if it's complex, or just use the dao
    // Wait, the file needs to be in `subject_files` table due to foreign keys.
    await db.into(db.semesters).insert(SemestersCompanion.insert(id: const Value(1), name: 'S1', startDate: DateTime.now(), endDate: DateTime.now(), semesterNumber: 1, academicYear: '2026'));
    await db.into(db.subjects).insert(SubjectsCompanion.insert(id: const Value(1), semesterId: 1, name: 'S1', displayColor: 0));
    await db.into(db.subjectFiles).insert(SubjectFilesCompanion.insert(id: const Value(1), subjectId: 1, semesterId: 1, fileName: 'test.pdf', fileExtension: 'pdf', fileSizeBytes: 100, relativeFilePath: 'scripts/benchmark_heavy.pdf'));
    await db.into(db.subjectFiles).insert(SubjectFilesCompanion.insert(id: const Value(2), subjectId: 1, semesterId: 1, fileName: 'test2.pdf', fileExtension: 'pdf', fileSizeBytes: 100, relativeFilePath: 'scripts/benchmark_heavy_malformed.pdf'));
    
    Future<void> runTest(int fileId, String path, bool parallel, int resumePage, String name) async {
      print('\n--- Running $name ---');
      await db.customStatement('DELETE FROM pdf_search_metadata WHERE file_id = ?', [fileId]);
      await db.customStatement('DELETE FROM pdf_page_fts WHERE file_id = ?', [fileId]);
      
      if (resumePage > 0) {
        await db.customStatement('INSERT INTO pdf_search_metadata (file_id, status, page_count, last_indexed_page, indexed_at) VALUES (?, \'indexing\', 412, ?, 0)', [fileId, resumePage]);
        // Insert dummy pages for 1..resumePage
        for (int i=1; i<=resumePage; i++) {
           await db.customStatement('INSERT INTO pdf_page_fts (file_id, page_number, page_text) VALUES (?, ?, ?)', [fileId, i, 'dummy text']);
        }
      } else {
        await db.customStatement('INSERT INTO pdf_search_metadata (file_id, status, page_count, last_indexed_page, indexed_at) VALUES (?, \'pending\', 0, 0, 0)', [fileId]);
      }
      
      final service = LocalPdfExtractionService(dao, storage, useParallel: parallel);
      final initialRss = ProcessInfo.currentRss;
      
      final report = await service.indexPdf(fileId, path);
      
      final peakRss = ProcessInfo.currentRss; // Rough approximation, true peak requires continuous polling
      
      print('Result: ${report.outcome.name}');
      print('Pages Indexed: ${report.pagesIndexed}/${report.pageCount}');
      print('Total Time: ${report.totalTime.inMilliseconds} ms');
      print('Open Time: ${report.openTime.inMilliseconds} ms');
      print('Extraction Time: ${report.extractionTime.inMilliseconds} ms');
      print('DB Time: ${report.databaseTime.inMilliseconds} ms');
      print('Recycles: ${report.documentRecycles}');
      print('RSS Growth: ${(peakRss - initialRss) ~/ (1024 * 1024)} MB');
    }

    await runTest(1, 'scripts/benchmark_heavy.pdf', false, 0, '1-Isolate Clean (Control)');
    await runTest(1, 'scripts/benchmark_heavy.pdf', true, 0, '2-Isolate Clean (Experimental)');
    await runTest(2, 'scripts/benchmark_heavy_malformed.pdf', false, 0, '1-Isolate Malformed (Control)');
    await runTest(2, 'scripts/benchmark_heavy_malformed.pdf', true, 0, '2-Isolate Malformed (Experimental)');
    
    // Resume tests
    await runTest(1, 'scripts/benchmark_heavy.pdf', false, 200, '1-Isolate Resume from 200');
    await runTest(1, 'scripts/benchmark_heavy.pdf', true, 200, '2-Isolate Resume from 200');
  });
}
