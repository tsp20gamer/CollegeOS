import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class EmergencyBackupStore {
  Future<void> save(ExportedBackup backup);
  Future<void> clear();
}

final class FileEmergencyBackupStore implements EmergencyBackupStore {
  const FileEmergencyBackupStore();

  @override
  Future<void> save(ExportedBackup backup) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'backup', 'emergency'));
    await directory.create(recursive: true);
    final unique = DateTime.now().toUtc().microsecondsSinceEpoch;
    final finalFile = File(
      p.join(directory.path, 'PreRestore_${unique}_${backup.fileName}'),
    );
    final temporary = File('${finalFile.path}.part');
    await temporary.writeAsBytes(backup.bytes, flush: true);
    await temporary.rename(finalFile.path);
    await for (final entity in directory.list()) {
      if (entity is File && entity.path != finalFile.path) {
        await entity.delete();
      }
    }
  }

  @override
  Future<void> clear() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'backup', 'emergency'));
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) await entity.delete();
    }
  }
}

final class CollegeOsBackupService {
  CollegeOsBackupService(
    this._database,
    this._codec,
    this._emergencyStore, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BackupDatabaseStore _database;
  final CollegeOsBackupCodec _codec;
  final EmergencyBackupStore _emergencyStore;
  final DateTime Function() _now;
  bool _busy = false;

  Future<ExportedBackup> create(String appVersion) =>
      _exclusive(() => _create(appVersion));

  PreparedBackup inspect({
    required List<int> bytes,
    required String sourceName,
  }) => _codec.decode(
    bytes: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    sourceName: sourceName,
  );

  Future<void> restore(
    PreparedBackup backup,
    String appVersion,
  ) => _exclusive(() async {
    final emergency = await _create(appVersion);
    try {
      await _emergencyStore.save(emergency);
    } catch (error) {
      throw BackupException(
        'emergency_backup_failed',
        'CollegeOS could not create the emergency backup, so restore was cancelled.',
        error,
      );
    }
    await _database.restore(backup.data);
  });

  Future<ExportedBackup> _create(String appVersion) async {
    final snapshot = await _database.capture();
    final backup = _codec.encode(
      data: snapshot,
      appVersion: appVersion,
      createdAt: _now(),
    );
    _codec.decode(bytes: backup.bytes, sourceName: backup.fileName);
    return backup;
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const BackupException(
        'backup_busy',
        'Another backup or restore operation is already running.',
      );
    }
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }
}
