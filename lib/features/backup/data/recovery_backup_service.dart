// Named public constructor parameters intentionally initialize private fields.
// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/data/recovery_backup_store.dart';
import 'package:college_os/features/backup/domain/recovery_backup.dart';

abstract interface class RecoveryBackupManager {
  Future<void> create(String appVersion);
  Future<List<RecoveryBackup>> list();
}

final class RecoveryBackupService implements RecoveryBackupManager {
  const RecoveryBackupService({
    required CollegeOsBackupService backupService,
    required CollegeOsBackupCodec codec,
    required RecoveryBackupStore store,
  }) : _backupService = backupService,
       _codec = codec,
       _store = store;

  final CollegeOsBackupService _backupService;
  final CollegeOsBackupCodec _codec;
  final RecoveryBackupStore _store;

  @override
  Future<void> create(String appVersion) async {
    final backup = await _backupService.create(appVersion);
    await _store.save(backup, keep: automaticRecoveryBackupLimit);
  }

  @override
  Future<List<RecoveryBackup>> list() async {
    final stored = await _store.list();
    final result = <RecoveryBackup>[];
    for (final item in stored) {
      try {
        final bytes = await _store.read(item.id);
        final prepared = _codec.decode(
          bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          sourceName: item.fileName,
        );
        result.add(
          RecoveryBackup(
            id: item.id,
            fileName: item.fileName,
            bytes: item.bytes,
            manifest: prepared.manifest,
          ),
        );
      } catch (_) {
        // A damaged private recovery file is ignored; other valid snapshots
        // remain available and the live database is never touched.
      }
    }
    return result;
  }

  Future<PreparedBackup> prepare(String id) async {
    final bytes = await _store.read(id);
    return _codec.decode(
      bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      sourceName: id,
    );
  }

  Future<void> restore(PreparedBackup backup, String appVersion) =>
      _backupService.restore(backup, appVersion);
}
