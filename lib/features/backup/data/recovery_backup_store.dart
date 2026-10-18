import 'dart:io';

import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class StoredRecoveryBackup {
  const StoredRecoveryBackup({
    required this.id,
    required this.fileName,
    required this.modifiedAt,
    required this.bytes,
  });

  final String id;
  final String fileName;
  final DateTime modifiedAt;
  final int bytes;
}

abstract interface class RecoveryBackupStore {
  Future<void> save(ExportedBackup backup, {int keep = 5});
  Future<List<StoredRecoveryBackup>> list();
  Future<List<int>> read(String id);
  Future<void> clear();
}

final class FileRecoveryBackupStore implements RecoveryBackupStore {
  FileRecoveryBackupStore({
    Future<Directory> Function()? directory,
    DateTime Function()? now,
  }) : _directory = directory ?? _defaultDirectory,
       _now = now ?? DateTime.now;

  final Future<Directory> Function() _directory;
  final DateTime Function() _now;

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'backup', 'recovery'));
  }

  @override
  Future<void> save(ExportedBackup backup, {int keep = 5}) async {
    if (keep < 1) {
      throw ArgumentError.value(
        keep,
        'keep',
        'Must retain at least one backup.',
      );
    }
    final directory = await _directory();
    await directory.create(recursive: true);
    final createdAt = _now().toUtc();
    final unique = createdAt.microsecondsSinceEpoch;
    final name = 'Recovery_${unique}_${backup.fileName}';
    final destination = File(p.join(directory.path, name));
    final partial = File('${destination.path}.part');
    await partial.writeAsBytes(
      await readExportedBackupBytes(backup),
      flush: true,
    );
    final saved = await partial.rename(destination.path);
    await saved.setLastModified(createdAt);
    final backups = await list();
    for (final stale in backups.skip(keep)) {
      final file = File(p.join(directory.path, stale.id));
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<List<StoredRecoveryBackup>> list() async {
    final directory = await _directory();
    if (!await directory.exists()) return const [];
    final entries = <StoredRecoveryBackup>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File ||
          !p.basename(entity.path).toLowerCase().endsWith('.collegeos')) {
        continue;
      }
      final stat = await entity.stat();
      entries.add(
        StoredRecoveryBackup(
          id: p.basename(entity.path),
          fileName: p.basename(entity.path),
          modifiedAt: stat.modified.toUtc(),
          bytes: stat.size,
        ),
      );
    }
    entries.sort((a, b) {
      final date = b.modifiedAt.compareTo(a.modifiedAt);
      return date != 0 ? date : b.id.compareTo(a.id);
    });
    return entries;
  }

  @override
  Future<List<int>> read(String id) async {
    if (id != p.basename(id) || !id.toLowerCase().endsWith('.collegeos')) {
      throw const BackupException(
        'invalid_recovery_id',
        'The selected local backup is invalid.',
      );
    }
    final directory = await _directory();
    final file = File(p.join(directory.path, id));
    if (!await file.exists()) {
      throw const BackupException(
        'recovery_not_found',
        'This local backup is no longer available.',
      );
    }
    return file.readAsBytes();
  }

  @override
  Future<void> clear() async {
    final directory = await _directory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) await entity.delete();
    }
  }
}
