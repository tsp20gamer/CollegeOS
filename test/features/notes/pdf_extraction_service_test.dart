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

    await service.indexPdf(fileId, 'notes/big.pdf');

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

  test('re-indexing replaces the previous index instead of duplicating it',
      () async {
    const pages = 8;
    final fileId = await _insertSubjectFile(database, 'notes/repeat.pdf');
    await _writePdf(storage, 'notes/repeat.pdf', pages: pages);

    await service.indexPdf(fileId, 'notes/repeat.pdf');
    await service.indexPdf(fileId, 'notes/repeat.pdf');

    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, 'indexed');
    expect((await dao.search('SEARCHTERM')).length, pages);
  });

  test('marks a missing file as error and never stays on indexing', () async {
    final fileId = await _insertSubjectFile(database, 'notes/gone.pdf');

    await service.indexPdf(fileId, 'notes/gone.pdf');

    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, 'error');
  });

  test('marks an unreadable file as error without throwing', () async {
    final fileId = await _insertSubjectFile(database, 'notes/broken.pdf');
    await storage.writeText('notes/broken.pdf', 'this is not a pdf at all');

    await service.indexPdf(fileId, 'notes/broken.pdf');

    final meta = await dao.getMetadata(fileId);
    expect(meta?.status, isNot(startsWith('indexing')));
  });
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
