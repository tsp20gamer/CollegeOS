import 'dart:async';

import 'package:college_os/features/backup/application/automatic_backup_coordinator.dart';
import 'package:college_os/features/backup/data/recovery_backup_service.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:college_os/features/backup/domain/recovery_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'creates one baseline and avoids unchanged checkpoint duplicates',
    () async {
      final enabled = StreamController<bool>.broadcast();
      final changes = StreamController<Object?>.broadcast();
      final service = _FakeRecoveryBackupManager();
      final coordinator = AutomaticBackupCoordinator(
        recoveryService: service,
        enabledChanges: enabled.stream,
        dataChanges: changes.stream,
        appVersion: () async => '1.0.0+1',
        debounceDuration: const Duration(hours: 1),
      );
      addTearDown(() async {
        await coordinator.dispose();
        await enabled.close();
        await changes.close();
      });

      coordinator.start();
      enabled.add(true);
      await _settle();
      expect(service.createCalls, 1);

      await coordinator.checkpoint();
      expect(service.createCalls, 1);

      changes
        ..add(null)
        ..add(null)
        ..add(null);
      await _settle();
      await coordinator.checkpoint();
      expect(service.createCalls, 2);

      await coordinator.checkpoint();
      expect(service.createCalls, 2);
    },
  );

  test('does not create backups while disabled', () async {
    final enabled = StreamController<bool>.broadcast();
    final changes = StreamController<Object?>.broadcast();
    final service = _FakeRecoveryBackupManager();
    final coordinator = AutomaticBackupCoordinator(
      recoveryService: service,
      enabledChanges: enabled.stream,
      dataChanges: changes.stream,
      appVersion: () async => '1.0.0+1',
      debounceDuration: const Duration(hours: 1),
    );
    addTearDown(() async {
      await coordinator.dispose();
      await enabled.close();
      await changes.close();
    });

    coordinator.start();
    enabled.add(false);
    changes.add(null);
    await _settle();
    await coordinator.checkpoint();

    expect(service.createCalls, 0);
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeRecoveryBackupManager implements RecoveryBackupManager {
  int createCalls = 0;
  final List<RecoveryBackup> backups = [];

  @override
  Future<void> create(String appVersion) async {
    createCalls++;
    backups.insert(0, _backup);
  }

  @override
  Future<List<RecoveryBackup>> list() async => List.unmodifiable(backups);
}

final _backup = RecoveryBackup(
  id: 'recovery.collegeos',
  fileName: 'recovery.collegeos',
  bytes: 1,
  manifest: BackupManifest(
    backupFormatVersion: 1,
    appVersion: '1.0.0+1',
    databaseSchemaVersion: 3,
    createdAt: DateTime.utc(2026, 8, 13),
    collegeName: 'Test College',
    activeSemester: null,
    recordCounts: const BackupRecordCounts(
      settings: 1,
      semesters: 0,
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
