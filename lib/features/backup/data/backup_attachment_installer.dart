import 'dart:io';

import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Places the staged attachments of a format-2 restore on disk around the
/// database transaction, so a failed restore leaves the previous files in
/// place.
abstract interface class BackupAttachmentInstaller {
  Future<void> install(List<StagedBackupAttachment> attachments);
  Future<void> rollback();
  Future<void> commit();
}

final class LocalBackupAttachmentInstaller
    implements BackupAttachmentInstaller {
  LocalBackupAttachmentInstaller({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  static const _filesFolder = 'subject_files';
  static const _backupFolder = 'subject_files.restore-backup';

  @override
  Future<void> install(List<StagedBackupAttachment> attachments) async {
    final support = await _directory();
    final filesDirectory = Directory(p.join(support.path, _filesFolder));
    final backupDirectory = Directory(p.join(support.path, _backupFolder));
    try {
      // An interrupted earlier restore leaves its previous files in the
      // backup folder; put them back before starting a fresh swap.
      if (!await filesDirectory.exists() && await backupDirectory.exists()) {
        await backupDirectory.rename(filesDirectory.path);
      }
      if (await backupDirectory.exists()) {
        await backupDirectory.delete(recursive: true);
      }
      if (await filesDirectory.exists()) {
        await filesDirectory.rename(backupDirectory.path);
      }
      for (final attachment in attachments) {
        final target = File(
          p.join(
            support.path,
            p.joinAll(attachment.targetRelativePath.split('/')),
          ),
        );
        if (!p.isWithin(support.path, target.path)) {
          throw const BackupException(
            'invalid_relationships',
            'An attached file points outside CollegeOS private storage.',
          );
        }
        await target.parent.create(recursive: true);
        await File(attachment.stagedPath).copy(target.path);
      }
    } catch (error) {
      await _swapBack(
        filesDirectory: filesDirectory,
        backupDirectory: backupDirectory,
      );
      if (error is BackupException && error.code == 'invalid_relationships') {
        rethrow;
      }
      throw BackupException(
        'restore_files',
        'CollegeOS could not place the attached files, so nothing was changed.',
        error,
      );
    }
  }

  @override
  Future<void> rollback() async {
    final support = await _directory();
    await _swapBack(
      filesDirectory: Directory(p.join(support.path, _filesFolder)),
      backupDirectory: Directory(p.join(support.path, _backupFolder)),
    );
  }

  @override
  Future<void> commit() async {
    final support = await _directory();
    final backupDirectory = Directory(p.join(support.path, _backupFolder));
    if (await backupDirectory.exists()) {
      await backupDirectory.delete(recursive: true);
    }
  }

  /// Removes the freshly placed files and moves any previous files back.
  Future<void> _swapBack({
    required Directory filesDirectory,
    required Directory backupDirectory,
  }) async {
    if (await filesDirectory.exists()) {
      await filesDirectory.delete(recursive: true);
    }
    if (await backupDirectory.exists()) {
      await backupDirectory.rename(filesDirectory.path);
    }
  }
}
