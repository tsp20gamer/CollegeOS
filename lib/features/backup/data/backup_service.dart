import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_attachment_installer.dart';
import 'package:college_os/features/backup/data/backup_attachment_reader.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class EmergencyBackupStore {
  Future<void> save(ExportedBackup backup);
  Future<void> clear();
}

/// Reads a backup's archive bytes whether it is held in memory or on disk.
Future<Uint8List> readExportedBackupBytes(ExportedBackup backup) async {
  final bytes = backup.bytes;
  if (bytes != null) return bytes;
  return File(backup.filePath!).readAsBytes();
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
    await temporary.writeAsBytes(
      await readExportedBackupBytes(backup),
      flush: true,
    );
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
    BackupAttachmentReader? attachmentReader,
    BackupAttachmentInstaller? attachmentInstaller,
    Future<Directory> Function()? scratchDirectory,
  }) : _now = now ?? DateTime.now,
       _attachmentReader = attachmentReader ?? LocalBackupAttachmentReader(),
       _attachmentInstaller =
           attachmentInstaller ?? LocalBackupAttachmentInstaller(),
       _scratchDirectory = scratchDirectory ?? _defaultScratchDirectory;

  final BackupDatabaseStore _database;
  final CollegeOsBackupCodec _codec;
  final EmergencyBackupStore _emergencyStore;
  final BackupAttachmentReader _attachmentReader;
  final BackupAttachmentInstaller _attachmentInstaller;
  final Future<Directory> Function() _scratchDirectory;
  final DateTime Function() _now;
  bool _busy = false;

  static Future<Directory> _defaultScratchDirectory() async {
    final temporary = await getTemporaryDirectory();
    return Directory(p.join(temporary.path, 'collegeos_backup'));
  }

  /// Writes a backup of every CollegeOS record.
  ///
  /// With [includeFiles] the uploaded subject files travel inside the archive
  /// as well, and the archive is streamed to private scratch storage instead
  /// of being held in memory.
  Future<ExportedBackup> create(
    String appVersion, {
    bool includeFiles = false,
  }) => _exclusive(() => _create(appVersion, includeFiles: includeFiles));

  Future<PreparedBackup> inspect({
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
    if (!backup.hasAttachments) {
      await _database.restore(backup.data);
      return;
    }
    // The database transaction is the point of no return: files are placed
    // first, so a failed or rolled-back restore puts the previous files back.
    await _attachmentInstaller.install(backup.attachments);
    try {
      await _database.restore(backup.data);
    } catch (error) {
      try {
        await _attachmentInstaller.rollback();
      } catch (_) {
        // The previous files stay in the restore-backup folder and the next
        // install moves them back before trying again.
      }
      rethrow;
    }
    try {
      await _attachmentInstaller.commit();
    } catch (_) {
      // Cleanup only; the restore itself succeeded.
    }
    try {
      await _codec.discardStaging();
    } catch (_) {
      // Cleanup only; stale staged files are wiped before the next inspect.
    }
  });

  /// Deletes the temporary archive a file-backed export wrote to disk.
  Future<void> discardExport(ExportedBackup backup) async {
    final path = backup.filePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The scratch folder is wiped before the next export.
    }
  }

  /// Removes the attachments staged by the last [inspect].
  Future<void> discardStaging() => _codec.discardStaging();

  /// Wipes scratch archives and staged attachments left behind by an
  /// interrupted export, restore, or share.
  Future<void> discardTemporaryData() async {
    try {
      await _wipeScratch(await _scratchDirectory());
    } catch (_) {
      // Scratch cleanup must never block startup.
    }
    try {
      await _codec.discardStaging();
    } catch (_) {
      // Staging cleanup must never block startup.
    }
  }

  Future<ExportedBackup> _create(
    String appVersion, {
    bool includeFiles = false,
  }) async {
    final snapshot = await _database.capture();
    final createdAt = _now();
    if (includeFiles) {
      final sources = await _attachmentReader.resolve(snapshot.subjectFiles);
      if (sources.isNotEmpty) {
        final scratch = await _scratchDirectory();
        await _wipeScratch(scratch);
        await scratch.create(recursive: true);
        return _codec.encodeWithFiles(
          data: snapshot,
          appVersion: appVersion,
          createdAt: createdAt,
          attachments: sources,
          outputPath: p.join(scratch.path, backupFileName(createdAt.toLocal())),
        );
      }
    }
    final backup = _codec.encode(
      data: snapshot,
      appVersion: appVersion,
      createdAt: createdAt,
    );
    // Verify the archive before it leaves the app. Data-only backups are
    // small by construction; a file-backed archive is covered by its
    // attachments' own checksums and the round-trip tests.
    await _codec.decode(bytes: backup.bytes!, sourceName: backup.fileName);
    return backup;
  }

  Future<void> _wipeScratch(Directory scratch) async {
    if (await scratch.exists()) {
      await scratch.delete(recursive: true);
    }
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
