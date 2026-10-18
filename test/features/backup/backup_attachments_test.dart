import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_attachment_installer.dart';
import 'package:college_os/features/backup/data/backup_attachment_reader.dart';
import 'package:college_os/features/backup/data/backup_attachment_staging.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory support;
  late Directory staging;
  late Directory scratch;
  late AppDatabase database;
  late DriftBackupDatabaseStore store;
  late _MemoryEmergencyStore emergency;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('collegeos_backup_files');
    support = Directory(p.join(root.path, 'support'));
    staging = Directory(p.join(root.path, 'staging'));
    scratch = Directory(p.join(root.path, 'scratch'));
    await support.create(recursive: true);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftBackupDatabaseStore(database);
    emergency = _MemoryEmergencyStore();
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  CollegeOsBackupCodec buildCodec() => CollegeOsBackupCodec(
    staging: BackupAttachmentStaging(directory: () async => staging),
  );

  CollegeOsBackupService buildService({
    BackupDatabaseStore? databaseStore,
    CollegeOsBackupCodec? codec,
  }) => CollegeOsBackupService(
    databaseStore ?? store,
    codec ?? buildCodec(),
    emergency,
    attachmentReader: LocalBackupAttachmentReader(
      directory: () async => support,
    ),
    attachmentInstaller: LocalBackupAttachmentInstaller(
      directory: () async => support,
    ),
    scratchDirectory: () async => scratch,
    now: () => DateTime(2026, 8, 12, 15),
  );

  test(
    'format-2 backup carries uploaded files and restore puts them back',
    () async {
      await _seedSourceDatabase(database);
      final syllabusBytes = Uint8List.fromList(utf8.encode('syllabus-pdf'));
      final notesBytes = Uint8List.fromList(
        List<int>.generate(4096, (index) => index % 251),
      );
      await _writeSupportFile(
        support,
        'subject_files/21/1000_syllabus.pdf',
        syllabusBytes,
      );
      await _writeSupportFile(
        support,
        'subject_files/21/1001_notes.pdf',
        notesBytes,
      );
      await _insertFileRow(
        database,
        id: 7,
        relativePath: 'subject_files/21/1000_syllabus.pdf',
        fileName: 'syllabus.pdf',
        bytes: syllabusBytes.length,
      );
      await _insertFileRow(
        database,
        id: 8,
        relativePath: 'subject_files/21/1001_notes.pdf',
        fileName: 'notes.pdf',
        bytes: notesBytes.length,
      );

      final expected = await store.capture();
      final service = buildService();
      final backup = await service.create('1.0.0+1', includeFiles: true);

      expect(backup.bytes, isNull);
      expect(backup.filePath, isNotNull);
      expect(backup.manifest.backupFormatVersion, 2);
      expect(backup.manifest.attachments.map((a) => a.fileId), [7, 8]);
      expect(
        backup.manifest.attachments.first.sha256,
        sha256.convert(syllabusBytes).toString(),
      );

      final archiveBytes = await File(backup.filePath!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(archiveBytes, verify: true);
      expect(archive.find('attachments/7'), isNotNull);
      expect(archive.find('attachments/8'), isNotNull);

      await _wipe(database);
      await Directory(
        p.join(support.path, 'subject_files'),
      ).delete(recursive: true);

      final prepared = await service.inspect(
        bytes: archiveBytes,
        sourceName: backup.fileName,
      );
      expect(prepared.hasAttachments, isTrue);
      expect(prepared.attachments.map((a) => a.targetRelativePath), [
        'subject_files/21/1000_syllabus.pdf',
        'subject_files/21/1001_notes.pdf',
      ]);

      await service.restore(prepared, '1.0.0+1');

      expect((await store.capture()).toJson(), expected.toJson());
      expect(
        await _readSupportFile(support, 'subject_files/21/1000_syllabus.pdf'),
        syllabusBytes,
      );
      expect(
        await _readSupportFile(support, 'subject_files/21/1001_notes.pdf'),
        notesBytes,
      );
      expect(
        await Directory(
          p.join(support.path, 'subject_files.restore-backup'),
        ).exists(),
        isFalse,
      );
      expect(await staging.exists(), isFalse);
      expect(emergency.saved, isNotNull);
    },
  );

  test(
    'data-only backup restores records without touching uploaded files',
    () async {
      await _seedSourceDatabase(database);
      final originalBytes = Uint8List.fromList(utf8.encode('original-file'));
      await _writeSupportFile(
        support,
        'subject_files/21/1000_syllabus.pdf',
        originalBytes,
      );
      await _insertFileRow(
        database,
        id: 7,
        relativePath: 'subject_files/21/1000_syllabus.pdf',
        fileName: 'syllabus.pdf',
        bytes: originalBytes.length,
      );

      final expected = await store.capture();
      final service = buildService();
      final backup = await service.create('1.0.0+1');

      expect(backup.bytes, isNotNull);
      expect(backup.filePath, isNull);
      expect(backup.manifest.backupFormatVersion, 1);
      expect(backup.manifest.attachments, isEmpty);

      await _wipe(database);
      final keptPath = 'subject_files/21/9999_kept.pdf';
      await _writeSupportFile(
        support,
        keptPath,
        Uint8List.fromList(utf8.encode('kept-while-restoring')),
      );

      final prepared = await service.inspect(
        bytes: backup.bytes!,
        sourceName: backup.fileName,
      );
      expect(prepared.hasAttachments, isFalse);
      await service.restore(prepared, '1.0.0+1');

      expect((await store.capture()).toJson(), expected.toJson());
      expect(
        await _readSupportFile(support, keptPath),
        Uint8List.fromList(utf8.encode('kept-while-restoring')),
      );
      expect(
        await _readSupportFile(support, 'subject_files/21/1000_syllabus.pdf'),
        originalBytes,
      );
    },
  );

  test('a tampered attached file is rejected and staging is cleared', () async {
    await _seedSourceDatabase(database);
    final service = buildService();
    final backup = await _createSampleBackup(database, support, service);
    final bytes = await File(backup.filePath!).readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final original = Uint8List.fromList(archive.find('attachments/7')!.content);
    final tampered = Uint8List.fromList(original);
    tampered[0] ^= 0x5A;
    archive.add(ArchiveFile.bytes('attachments/7', tampered));
    final changed = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.inspect(bytes: changed, sourceName: backup.fileName),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'corrupt_attachment',
        ),
      ),
    );
    expect(await staging.exists(), isFalse);
  });

  test('an attachment the manifest does not declare is rejected', () async {
    await _seedSourceDatabase(database);
    final service = buildService();
    final backup = await _createSampleBackup(database, support, service);
    final bytes = await File(backup.filePath!).readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    archive.add(ArchiveFile.bytes('attachments/999', Uint8List(4)));
    final changed = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.inspect(bytes: changed, sourceName: backup.fileName),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_archive',
        ),
      ),
    );
  });

  test('a declared attachment missing from the archive is rejected', () async {
    await _seedSourceDatabase(database);
    final service = buildService();
    final backup = await _createSampleBackup(database, support, service);
    final bytes = await File(backup.filePath!).readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    archive.removeFile(archive.find('attachments/7')!);
    final changed = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.inspect(bytes: changed, sourceName: backup.fileName),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_archive',
        ),
      ),
    );
  });

  test('an attachment entry that escapes the archive is rejected', () async {
    await _seedSourceDatabase(database);
    final service = buildService();
    final backup = await _createSampleBackup(database, support, service);
    final bytes = await File(backup.filePath!).readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    archive.add(ArchiveFile.bytes('attachments/../7', Uint8List(4)));
    final changed = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.inspect(bytes: changed, sourceName: backup.fileName),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'unsafe_archive',
        ),
      ),
    );
  });

  test('a data-only archive that smuggles an attachment is rejected', () async {
    await _seedSourceDatabase(database);
    final service = buildService();
    final backup = await service.create('1.0.0+1');
    expect(backup.manifest.backupFormatVersion, 1);

    final archive = ZipDecoder().decodeBytes(backup.bytes!, verify: true);
    archive.add(ArchiveFile.bytes('attachments/7', Uint8List(4)));
    final changed = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.inspect(bytes: changed, sourceName: backup.fileName),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_archive',
        ),
      ),
    );
  });

  test('an attachment without a matching subject file is rejected', () async {
    await _seedSourceDatabase(database);
    final service = buildService();
    final backup = await _createSampleBackup(database, support, service);
    final bytes = await File(backup.filePath!).readAsBytes();

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final entry = archive.find('attachments/7')!;
    final content = Uint8List.fromList(entry.content);
    archive.removeFile(entry);
    archive.add(ArchiveFile.bytes('attachments/9999', content));
    final manifest =
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
            as Map<String, dynamic>;
    final attachments = manifest['attachments'] as List<dynamic>;
    (attachments.first as Map<String, dynamic>)['fileId'] = 9999;
    archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    final changed = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

    await expectLater(
      service.inspect(bytes: changed, sourceName: backup.fileName),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_relationships',
        ),
      ),
    );
  });

  test(
    'a subject file path that escapes private storage is rejected',
    () async {
      await _seedSourceDatabase(database);
      final service = buildService();
      final backup = await _createSampleBackup(database, support, service);
      final bytes = await File(backup.filePath!).readAsBytes();

      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final data =
          jsonDecode(utf8.decode(archive.find('data.json')!.content))
              as Map<String, dynamic>;
      final files = data['subjectFiles'] as List<dynamic>;
      (files.first as Map<String, dynamic>)['relativeFilePath'] =
          'subject_files/21/../../../escape.pdf';
      final changed = _replaceDataAndHash(bytes, data);

      await expectLater(
        service.inspect(bytes: changed, sourceName: backup.fileName),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            'invalid_relationships',
          ),
        ),
      );
    },
  );

  test('an export over the attachment size cap is rejected', () async {
    await _seedSourceDatabase(database);
    const relativePath = 'subject_files/21/2000_big.pdf';
    final bigFile = File(
      p.join(support.path, p.joinAll(relativePath.split('/'))),
    );
    await bigFile.parent.create(recursive: true);
    final handle = await bigFile.open(mode: FileMode.write);
    await handle.setPosition(maxBackupAttachmentTotalBytes);
    await handle.writeByte(0);
    await handle.close();
    await _insertFileRow(
      database,
      id: 9,
      relativePath: relativePath,
      fileName: 'big.pdf',
      bytes: maxBackupAttachmentTotalBytes + 1,
    );

    final service = buildService();
    await expectLater(
      service.create('1.0.0+1', includeFiles: true),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'attachments_too_large',
        ),
      ),
    );
  });

  test(
    'a failed database restore puts the previous uploaded files back',
    () async {
      await _seedSourceDatabase(database);
      final service = buildService();
      final backup = await _createSampleBackup(database, support, service);
      final bytes = await File(backup.filePath!).readAsBytes();

      // The device keeps a different file that must survive a failed restore.
      await Directory(
        p.join(support.path, 'subject_files'),
      ).delete(recursive: true);
      await _writeSupportFile(
        support,
        'subject_files/21/5000_current.pdf',
        Uint8List.fromList(utf8.encode('current-content')),
      );

      final failing = buildService(
        databaseStore: DriftBackupDatabaseStore(
          database,
          beforeRestoreCommit: () => throw StateError('injected failure'),
        ),
      );
      final prepared = await failing.inspect(
        bytes: bytes,
        sourceName: backup.fileName,
      );
      await expectLater(
        failing.restore(prepared, '1.0.0+1'),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            'restore_failed',
          ),
        ),
      );

      expect(
        await _readSupportFile(support, 'subject_files/21/5000_current.pdf'),
        Uint8List.fromList(utf8.encode('current-content')),
      );
      expect(
        await File(
          p.join(support.path, 'subject_files', '21', '1000_syllabus.pdf'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(
          p.join(support.path, 'subject_files.restore-backup'),
        ).exists(),
        isFalse,
      );
      final rows = await database.select(database.subjectFiles).get();
      expect(rows.map((row) => row.id), [7]);
    },
  );

  test(
    'an interrupted restore swap is recovered before the next attempt',
    () async {
      // The old folder was renamed but the copy never started; the next install
      // must put the student's files back before swapping again.
      await _writeSupportFile(
        support,
        'subject_files.restore-backup/21/old.pdf',
        Uint8List.fromList(utf8.encode('old')),
      );
      final staged = File(p.join(staging.path, '7'));
      await staged.parent.create(recursive: true);
      await staged.writeAsBytes(utf8.encode('new'));

      final installer = LocalBackupAttachmentInstaller(
        directory: () async => support,
      );
      await expectLater(
        installer.install([
          StagedBackupAttachment(
            fileId: 7,
            stagedPath: p.join(staging.path, 'missing'),
            bytes: 3,
            sha256: 'x',
            targetRelativePath: 'subject_files/21/new.pdf',
          ),
        ]),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            'restore_files',
          ),
        ),
      );

      expect(
        await _readSupportFile(support, 'subject_files/21/old.pdf'),
        Uint8List.fromList(utf8.encode('old')),
      );
      expect(
        await Directory(
          p.join(support.path, 'subject_files.restore-backup'),
        ).exists(),
        isFalse,
      );

      await installer.install([
        StagedBackupAttachment(
          fileId: 7,
          stagedPath: staged.path,
          bytes: 3,
          sha256: 'x',
          targetRelativePath: 'subject_files/21/new.pdf',
        ),
      ]);
      expect(
        await _readSupportFile(support, 'subject_files/21/new.pdf'),
        Uint8List.fromList(utf8.encode('new')),
      );
      expect(
        await File(
          p.join(support.path, 'subject_files', '21', 'old.pdf'),
        ).exists(),
        isFalse,
      );
      await installer.commit();
      expect(
        await Directory(
          p.join(support.path, 'subject_files.restore-backup'),
        ).exists(),
        isFalse,
      );
    },
  );
}

final class _MemoryEmergencyStore implements EmergencyBackupStore {
  ExportedBackup? saved;

  @override
  Future<void> clear() async => saved = null;

  @override
  Future<void> save(ExportedBackup backup) async => saved = backup;
}

/// Seeds one uploaded file the tests can back up, and returns the created
/// format-2 backup.
Future<ExportedBackup> _createSampleBackup(
  AppDatabase database,
  Directory support,
  CollegeOsBackupService service,
) async {
  final contents = Uint8List.fromList(utf8.encode('sample-file'));
  await _writeSupportFile(
    support,
    'subject_files/21/1000_syllabus.pdf',
    contents,
  );
  await _insertFileRow(
    database,
    id: 7,
    relativePath: 'subject_files/21/1000_syllabus.pdf',
    fileName: 'syllabus.pdf',
    bytes: contents.length,
  );
  return service.create('1.0.0+1', includeFiles: true);
}

Future<void> _seedSourceDatabase(AppDatabase database) async {
  final created = DateTime.utc(2026, 8, 1, 10);
  await database
      .update(database.appSettings)
      .write(
        AppSettingsCompanion(
          collegeName: Value('City College'),
          onboardingCompleted: Value(true),
        ),
      );
  await database
      .into(database.semesters)
      .insert(
        SemesterRow(
          id: 11,
          name: 'Semester 3',
          semesterNumber: 3,
          academicYear: '2026-2027',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 12, 20),
          isActive: true,
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.subjects)
      .insert(
        SubjectRow(
          id: 21,
          semesterId: 11,
          name: 'Operating Systems',
          shortCode: 'OS',
          professor: 'Dr Rao',
          room: 'A-101',
          attendanceTarget: 0.8,
          displayColor: 0xFF2563EB,
          isArchived: false,
          createdAt: created,
          updatedAt: created,
        ),
      );
}

Future<void> _insertFileRow(
  AppDatabase database, {
  required int id,
  required String relativePath,
  required String fileName,
  required int bytes,
}) async {
  final created = DateTime.utc(2026, 8, 1, 10);
  await database
      .into(database.subjectFiles)
      .insert(
        SubjectFilesCompanion.insert(
          id: Value(id),
          subjectId: 21,
          semesterId: 11,
          title: Value('Material'),
          fileName: fileName,
          fileExtension: 'pdf',
          fileSizeBytes: bytes,
          mimeType: const Value('application/pdf'),
          relativeFilePath: relativePath,
          createdAt: Value(created),
          updatedAt: Value(created),
        ),
      );
}

Future<void> _wipe(AppDatabase database) => database.transaction(() async {
  await database.delete(database.subjectFiles).go();
  await database.delete(database.subjects).go();
  await database.delete(database.semesters).go();
  await database.delete(database.appSettings).go();
  await database
      .into(database.appSettings)
      .insert(const AppSettingsCompanion());
});

Future<void> _writeSupportFile(
  Directory support,
  String relativePath,
  List<int> bytes,
) async {
  final file = File(p.join(support.path, p.joinAll(relativePath.split('/'))));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Future<Uint8List> _readSupportFile(Directory support, String relativePath) =>
    File(
      p.join(support.path, p.joinAll(relativePath.split('/'))),
    ).readAsBytes();

Uint8List _replaceDataAndHash(Uint8List source, Map<String, dynamic> data) {
  final archive = ZipDecoder().decodeBytes(source, verify: true);
  final dataBytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  final manifest =
      jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
          as Map<String, dynamic>;
  manifest['dataBytes'] = dataBytes.length;
  manifest['dataSha256'] = sha256.convert(dataBytes).toString();
  archive.add(ArchiveFile.bytes('data.json', dataBytes));
  archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}
