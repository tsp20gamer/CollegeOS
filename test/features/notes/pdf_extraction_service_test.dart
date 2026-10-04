import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/notes/domain/pdf_extraction_service.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  late AppDatabase database;
  late PdfSearchDao dao;
  late Directory tempDir;
  late _FakeStorage storage;
  late LocalPdfExtractionService service;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = database.pdfSearchDao;
    tempDir = await Directory.systemTemp.createTemp('pdf_index_test');
    storage = _FakeStorage(tempDir);
    service = LocalPdfExtractionService(dao, storage);
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('indexes every page in batches and finishes as indexed', () async {
    const pages = 25; // more than one batch, so batching is exercised
    final fileId = await _insertSubjectFile(database, 'notes/big.pdf');
    await _writePdf(storage, 'notes/big.pdf', pages: pages);

    final report = await service.indexPdf(fileId, 'notes/big.pdf');

    expect(report.outcome, PdfIndexOutcome.indexed);
    expect(report.pagesIndexed, pages);
    expect(report.resumedFromPage, 0);

    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, 'indexed');
    expect(meta?.pageCount, pages);

    // Every page was written to FTS5, exactly once.
    final rows = await dao.search('SEARCHTERM');
    expect(rows.length, pages);
    expect(rows.map((row) => row.pageNumber).toSet().length, pages);
  });

  test('search finds text on the first, middle and last page', () async {
    const pages = 30;
    final fileId = await _insertSubjectFile(database, 'notes/text.pdf');
    await _writePdf(storage, 'notes/text.pdf', pages: pages);

    await service.indexPdf(fileId, 'notes/text.pdf');

    for (final page in [1, 15, pages]) {
      final rows = await dao.search('UNIQUEPAGE$page');
      expect(rows, isNotEmpty, reason: 'page $page should be searchable');
      expect(rows.first.fileId, fileId);
      expect(rows.first.pageNumber, page);
      expect(rows.first.snippet, contains('UNIQUEPAGE$page'));
    }
  });

  test('indexes a PDF that carries bytes after the final %%EOF', () async {
    const pages = 12;
    final fileId = await _insertSubjectFile(database, 'notes/junk.pdf');
    final file = await _writePdf(storage, 'notes/junk.pdf', pages: pages);
    // Trailing junk after the last %%EOF makes Syncfusion's cross table reader
    // copy the whole file unless the buffer is trimmed to the marker.
    await file.writeAsString(
      'trailing-bytes-after-eof-that-are-not-whitespace',
      mode: FileMode.append,
    );

    await service.indexPdf(fileId, 'notes/junk.pdf');

    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, 'indexed');
    expect(meta?.pageCount, pages);
    expect(await dao.search('UNIQUEPAGE$pages'), isNotEmpty);
  });

  test('keeps the pages of an interrupted run and resumes after them',
      () async {
    const pages = 25;
    final fileId = await _insertSubjectFile(database, 'notes/resume.pdf');
    await _writePdf(storage, 'notes/resume.pdf', pages: pages);

    // A previous run stored pages 1..6 of 25 before the app was killed.
    final interrupted = await _storePages(
      dao,
      fileId,
      lastPage: 6,
      totalPages: pages,
    );
    expect(interrupted.status, 'indexing (6/$pages)');

    final report = await service.indexPdf(fileId, 'notes/resume.pdf');

    expect(report.outcome, PdfIndexOutcome.indexed);
    expect(report.resumedFromPage, 6);
    expect(
      report.pagesIndexed,
      pages - 6,
      reason: 'only pages 7..25 are extracted again',
    );

    // Pages 1..6 were neither deleted nor extracted a second time.
    final kept = await dao.search('STALEBATCH');
    expect(kept, hasLength(6));
    expect(kept.map((row) => row.pageNumber).toSet(), {1, 2, 3, 4, 5, 6});

    // The finished index covers every page exactly once.
    final all = await dao.search('SEARCHTERM');
    expect(all, hasLength(pages));
    expect(all.map((row) => row.pageNumber).toSet().length, pages);
    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, 'indexed');
    expect(meta?.pageCount, pages);
  });

  test('resumes a run that stopped with an error', () async {
    const pages = 20;
    final fileId = await _insertSubjectFile(database, 'notes/errored.pdf');
    await _writePdf(storage, 'notes/errored.pdf', pages: pages);

    await _storePages(dao, fileId, lastPage: 7, totalPages: pages);
    await dao.markAsError(fileId, pageCount: pages, lastIndexedPage: 7);

    final report = await service.indexPdf(fileId, 'notes/errored.pdf');

    expect(report.outcome, PdfIndexOutcome.indexed);
    expect(report.resumedFromPage, 7);
    expect(report.pagesIndexed, pages - 7);
    expect(await dao.search('STALEBATCH'), hasLength(7));
    expect((await dao.getMetadata(fileId))?.status, 'indexed');
  });

  test('does not read or rebuild a file that is already indexed', () async {
    const pages = 8;
    final fileId = await _insertSubjectFile(database, 'notes/done.pdf');
    final file = await _writePdf(storage, 'notes/done.pdf', pages: pages);

    final first = await service.indexPdf(fileId, 'notes/done.pdf');
    expect(first.outcome, PdfIndexOutcome.indexed);

    // Removing the file proves a second run never opens the document again.
    await file.delete();

    final second = await service.indexPdf(fileId, 'notes/done.pdf');

    expect(second.outcome, PdfIndexOutcome.skipped);
    expect(second.pagesIndexed, 0);
    expect(second.openTime, Duration.zero);
    expect(second.extractionTime, Duration.zero);
    expect(second.documentRecycles, 0);
    expect(second.pageCount, pages);
    expect((await dao.getMetadata(fileId))?.status, 'indexed');
    expect(await dao.search('SEARCHTERM'), hasLength(pages));
  });

  test('rebuilds when the stored index belongs to a different document',
      () async {
    const pages = 10;
    final fileId = await _insertSubjectFile(database, 'notes/swapped.pdf');
    await _writePdf(storage, 'notes/swapped.pdf', pages: pages);

    // Progress recorded for a 99 page document cannot describe this one.
    await _storePages(dao, fileId, lastPage: 4, totalPages: 99);

    final report = await service.indexPdf(fileId, 'notes/swapped.pdf');

    expect(report.outcome, PdfIndexOutcome.indexed);
    expect(report.pagesIndexed, pages);
    expect(await dao.search('STALEBATCH'), isEmpty);
    expect(await dao.search('SEARCHTERM'), hasLength(pages));
    expect((await dao.getMetadata(fileId))?.pageCount, pages);
  });

  test('opens the document once and never recycles it for a normal file',
      () async {
    const pages = 45; // spans three database batches
    final fileId = await _insertSubjectFile(database, 'notes/single.pdf');
    await _writePdf(storage, 'notes/single.pdf', pages: pages);

    final report = await service.indexPdf(fileId, 'notes/single.pdf');

    expect(report.outcome, PdfIndexOutcome.indexed);
    expect(report.pagesIndexed, pages);
    expect(
      report.documentRecycles,
      0,
      reason: 'a small document must be served by one open',
    );
    expect(await dao.search('SEARCHTERM'), hasLength(pages));
  });

  test('recycles the open document when memory actually grows', () async {
    const pages = 45;
    final fileId = await _insertSubjectFile(database, 'notes/pressure.pdf');
    await _writePdf(storage, 'notes/pressure.pdf', pages: pages);

    // A negative budget forces the recycle path without allocating gigabytes.
    final tightService = LocalPdfExtractionService(
      dao,
      storage,
      documentMemoryBudgetBytes: -1,
    );

    final report = await tightService.indexPdf(fileId, 'notes/pressure.pdf');

    expect(report.outcome, PdfIndexOutcome.indexed);
    expect(report.documentRecycles, greaterThanOrEqualTo(1));
    expect(
      await dao.search('SEARCHTERM'),
      hasLength(pages),
      reason: 'recycling the document must not lose or duplicate pages',
    );
  });

  test('reports the timings of every phase', () async {
    const pages = 60;
    final fileId = await _insertSubjectFile(database, 'notes/timed.pdf');
    await _writePdf(storage, 'notes/timed.pdf', pages: pages);

    final report = await service.indexPdf(fileId, 'notes/timed.pdf');

    expect(report.pageCount, pages);
    expect(report.pagesIndexed, pages);
    expect(report.totalTime, greaterThan(Duration.zero));
    expect(report.extractionTime, greaterThan(Duration.zero));
    expect(
      (report.openTime + report.extractionTime) ~/ report.parallelWorkers + report.databaseTime,
      lessThanOrEqualTo(report.totalTime),
      reason: 'the phases are measured inside the total, adjusted for parallel workers',
    );
  });

  test('marks a missing file as error and never stays on indexing', () async {
    final fileId = await _insertSubjectFile(database, 'notes/gone.pdf');

    final report = await service.indexPdf(fileId, 'notes/gone.pdf');

    expect(report.outcome, PdfIndexOutcome.failed);
    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, 'error');
  });

  test('marks an unreadable file as error without throwing', () async {
    final fileId = await _insertSubjectFile(database, 'notes/broken.pdf');
    await storage.writeText('notes/broken.pdf', 'this is not a pdf at all');

    final report = await service.indexPdf(fileId, 'notes/broken.pdf');

    expect(report.outcome, PdfIndexOutcome.failed);
    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, isNot(startsWith('indexing')));
  });
}

/// Simulates an interrupted run that stored `pages 1..lastPage` of a document
/// with [totalPages] pages, using text that later runs must not rewrite.
Future<PdfSearchMetadataData> _storePages(
  PdfSearchDao dao,
  int fileId, {
  required int lastPage,
  required int totalPages,
}) async {
  await dao.saveExtractedBatch(
    fileId,
    [
      for (int page = 1; page <= lastPage; page++)
        PdfExtractedPage(
          pageNumber: page,
          text: 'STALEBATCH SEARCHTERM UNIQUEPAGE$page page body $page',
        ),
    ],
    lastPageIndexed: lastPage,
    totalPages: totalPages,
  );
  return (await dao.getMetadata(fileId))!;
}

Future<File> _writePdf(
  _FakeStorage storage,
  String relativePath, {
  required int pages,
}) async {
  final document = PdfDocument();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
  for (int page = 1; page <= pages; page++) {
    document.pages.add().graphics.drawString(
      'SEARCHTERM UNIQUEPAGE$page page body $page',
      font,
      bounds: Rect.fromLTWH(0, 0, 400, 40),
    );
  }
  final bytes = await document.save();
  document.dispose();
  return storage.writeBytes(relativePath, Uint8List.fromList(bytes));
}

Future<int> _insertSubjectFile(AppDatabase database, String relativePath) async {
  final semesterId = await database.semestersDao.insertSemester(
    SemestersCompanion.insert(
      name: 'Semester 1',
      semesterNumber: 1,
      academicYear: '2026-2027',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 12, 20),
      isActive: const Value(true),
    ),
  );
  final subjectId = await database.subjectsDao.insertSubject(
    SubjectsCompanion.insert(
      semesterId: semesterId,
      name: 'Algorithms',
      displayColor: 0xFF6750A4,
    ),
  );
  return database.subjectFilesDao.insertFile(
    SubjectFilesCompanion.insert(
      subjectId: subjectId,
      semesterId: semesterId,
      title: const Value('Notes'),
      fileName: p.basename(relativePath),
      fileExtension: 'pdf',
      fileSizeBytes: 0,
      relativeFilePath: relativePath,
    ),
  );
}

class _FakeStorage implements SubjectFileStorageService {
  _FakeStorage(this.baseDir);

  final Directory baseDir;

  File _file(String relativePath) => File(p.join(baseDir.path, relativePath));

  Future<File> writeBytes(String relativePath, Uint8List bytes) async {
    final file = _file(relativePath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> writeText(String relativePath, String text) async {
    final file = _file(relativePath);
    await file.create(recursive: true);
    await file.writeAsString(text, flush: true);
    return file;
  }

  @override
  Future<File> resolveFile(String relativeFilePath) async =>
      _file(relativeFilePath);

  @override
  Future<void> deleteFile(String relativeFilePath) async {}

  @override
  Future<void> openOrShareFile(String relativeFilePath, String title) async {}

  @override
  Future<({String fileExtension, int fileSizeBytes, String relativeFilePath})>
  saveFile({
    required int subjectId,
    required String originalFileName,
    required Uint8List bytes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<({String fileExtension, int fileSizeBytes, String relativeFilePath})>
  saveFileFromPath({
    required int subjectId,
    required String originalFileName,
    required String sourceFilePath,
  }) async =>
      throw UnimplementedError();
}
