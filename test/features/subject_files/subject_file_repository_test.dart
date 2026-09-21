import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/subject_files/data/drift_subject_file_repository.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeSubjectFileStorageService implements SubjectFileStorageService {
  final Set<String> savedPaths = {};

  @override
  Future<({String relativeFilePath, int fileSizeBytes, String fileExtension})>
  saveFile({
    required int subjectId,
    required String originalFileName,
    required Uint8List bytes,
  }) async {
    final path = 'subject_files/$subjectId/test_$originalFileName';
    savedPaths.add(path);
    return (
      relativeFilePath: path,
      fileSizeBytes: bytes.length,
      fileExtension: originalFileName.split('.').last.toLowerCase(),
    );
  }

  @override
  Future<File> resolveFile(String relativeFilePath) async {
    return File(relativeFilePath);
  }

  @override
  Future<void> deleteFile(String relativeFilePath) async {
    savedPaths.remove(relativeFilePath);
  }

  @override
  Future<void> openOrShareFile(String relativeFilePath, String title) async {}
}

void main() {
  late AppDatabase database;
  late FakeSubjectFileStorageService storageService;
  late DriftSubjectFileRepository repository;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    storageService = FakeSubjectFileStorageService();
    repository = DriftSubjectFileRepository(
      database.subjectFilesDao,
      storageService,
    );
    semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
      ),
    );
    subjectId = await database.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semesterId,
        name: 'Operating Systems',
        displayColor: 0xFF10B981,
      ),
    );
  });

  tearDown(() => database.close());

  test('creates, reads, and deletes subject files with storage cleanup', () async {
    final fileId1 = await repository.create((
      subjectId: subjectId,
      semesterId: semesterId,
      title: 'Lecture 1 Slides',
      fileName: 'lecture_1.pptx',
      fileExtension: 'pptx',
      fileSizeBytes: 2048576,
      mimeType: 'application/vnd.ms-powerpoint',
      relativeFilePath: 'subject_files/$subjectId/test_lecture_1.pptx',
    ));
    storageService.savedPaths.add('subject_files/$subjectId/test_lecture_1.pptx');

    final fileId2 = await repository.create((
      subjectId: subjectId,
      semesterId: semesterId,
      title: 'Syllabus PDF',
      fileName: 'syllabus.pdf',
      fileExtension: 'pdf',
      fileSizeBytes: 524288,
      mimeType: 'application/pdf',
      relativeFilePath: 'subject_files/$subjectId/test_syllabus.pdf',
    ));
    storageService.savedPaths.add('subject_files/$subjectId/test_syllabus.pdf');

    var files = await repository.watchBySubject(subjectId).first;
    expect(files.length, 2);
    // Newest first
    expect(files[0].id, fileId2);
    expect(files[0].title, 'Syllabus PDF');
    expect(files[0].fileExtension, 'pdf');
    expect(files[1].id, fileId1);
    expect(files[1].title, 'Lecture 1 Slides');
    expect(files[1].fileSizeBytes, 2048576);

    // Delete file 1 and verify storage cleanup
    await repository.delete(fileId1);
    expect(storageService.savedPaths.contains('subject_files/$subjectId/test_lecture_1.pptx'), isFalse);

    files = await repository.watchBySubject(subjectId).first;
    expect(files.length, 1);
    expect(files.single.id, fileId2);
  });

  test('backup store captures and restores subject files cleanly', () async {
    final store = DriftBackupDatabaseStore(database);

    await repository.create((
      subjectId: subjectId,
      semesterId: semesterId,
      title: 'Lab Manual',
      fileName: 'lab_manual.pdf',
      fileExtension: 'pdf',
      fileSizeBytes: 1048576,
      mimeType: 'application/pdf',
      relativeFilePath: 'subject_files/$subjectId/lab_manual.pdf',
    ));

    final snapshot = await store.capture();
    expect(snapshot.subjectFiles.length, 1);
    expect(snapshot.counts.files, 1);
    expect(snapshot.subjectFiles.single.title, 'Lab Manual');

    // Create a new in-memory database and restore
    final newDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(newDb.close);
    final newStore = DriftBackupDatabaseStore(newDb);

    await newStore.restore(snapshot);

    final restoredFiles = await DriftSubjectFileRepository(
      newDb.subjectFilesDao,
      storageService,
    ).watchBySubject(subjectId).first;

    expect(restoredFiles.length, 1);
    expect(restoredFiles.single.title, 'Lab Manual');
    expect(restoredFiles.single.fileExtension, 'pdf');
    expect(await newDb.passesForeignKeyCheck(), isTrue);
    expect(await newDb.passesIntegrityCheck(), isTrue);
  });
}
