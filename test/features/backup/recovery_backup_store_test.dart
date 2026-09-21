import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/features/backup/data/recovery_backup_store.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late DateTime clock;
  late FileRecoveryBackupStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('college_os_recovery_');
    clock = DateTime.utc(2026, 8, 13, 9);
    store = FileRecoveryBackupStore(
      directory: () async => directory,
      now: () {
        final value = clock;
        clock = clock.add(const Duration(minutes: 1));
        return value;
      },
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('retains exactly the newest five recovery backups', () async {
    for (var index = 1; index <= 7; index++) {
      await store.save(_backup(index), keep: 5);
    }

    final backups = await store.list();
    expect(backups, hasLength(5));
    expect(await Future.wait(backups.map((item) => store.read(item.id))), [
      [7],
      [6],
      [5],
      [4],
      [3],
    ]);
    expect(
      directory.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.collegeos'),
      ),
      hasLength(5),
    );
  });

  test('clear removes only files inside the recovery directory', () async {
    await store.save(_backup(1));
    await File('${directory.parent.path}/external.collegeos').writeAsBytes([9]);

    await store.clear();

    expect(await store.list(), isEmpty);
    expect(
      File('${directory.parent.path}/external.collegeos').existsSync(),
      isTrue,
    );
    await File('${directory.parent.path}/external.collegeos').delete();
  });

  test('rejects unsafe recovery identifiers', () async {
    await expectLater(
      store.read('../backup.collegeos'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_recovery_id',
        ),
      ),
    );
  });
}

ExportedBackup _backup(int index) => ExportedBackup(
  fileName: 'CollegeOS_Backup_2026-08-13_090$index.collegeos',
  bytes: Uint8List.fromList([index]),
  manifest: BackupManifest(
    backupFormatVersion: 1,
    appVersion: '1.0.0+1',
    databaseSchemaVersion: 3,
    createdAt: DateTime.utc(2026, 8, 13, 9, index),
    collegeName: 'Test College',
    activeSemester: 'Semester 1',
    recordCounts: const BackupRecordCounts(
      settings: 1,
      semesters: 1,
      subjects: 0,
      timetable: 0,
      attendance: 0,
      tasks: 0,
      exams: 0,
      marks: 0,
    ),
    dataSha256:
        '0000000000000000000000000000000000000000000000000000000000000000',
    dataBytes: 1,
  ),
);
