import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Streams the attached files of a format-2 backup to private storage while
/// the archive is inspected, so a preview never has to hold them in memory.
///
/// Every staged file is verified against the size and SHA-256 its manifest
/// declares before the backup is accepted.
final class BackupAttachmentStaging {
  BackupAttachmentStaging({Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'backup', 'staging'));
  }

  /// Removes every staged file, including anything left behind by an
  /// interrupted earlier operation.
  Future<void> reset() async {
    final directory = await _directory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  /// Writes one archive entry to private storage and returns its staged path.
  ///
  /// Throws a [BackupException] with code `corrupt_attachment` when the
  /// extracted bytes do not match the manifest, deleting the staged file.
  Future<String> write({
    required ArchiveFile entry,
    required int fileId,
    required int declaredBytes,
    required String declaredSha256,
  }) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final target = File(p.join(directory.path, '$fileId'));
    try {
      if (entry.size != declaredBytes) {
        throw const BackupException(
          'corrupt_attachment',
          'An attached file in the backup is damaged.',
        );
      }
      final output = OutputFileStream(target.path);
      try {
        entry.writeContent(output, freeMemory: true);
      } finally {
        await output.close();
      }
      if (await target.length() != declaredBytes) {
        throw const BackupException(
          'corrupt_attachment',
          'An attached file in the backup is damaged.',
        );
      }
      final digest = await sha256.bind(target.openRead()).first;
      if (digest.toString() != declaredSha256) {
        throw const BackupException(
          'corrupt_attachment',
          'An attached file in the backup is damaged.',
        );
      }
      return target.path;
    } catch (_) {
      try {
        if (await target.exists()) await target.delete();
      } catch (_) {
        // The next reset clears any leftovers.
      }
      rethrow;
    }
  }
}
