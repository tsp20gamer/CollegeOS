import 'dart:io';

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves the uploaded files an export should copy into the archive.
///
/// Rows whose stored path is unsafe or whose file vanished are skipped so a
/// backup never fails because of a file the student already deleted.
abstract interface class BackupAttachmentReader {
  Future<List<BackupEncodeAttachment>> resolve(List<SubjectFileRow> rows);
}

final class LocalBackupAttachmentReader implements BackupAttachmentReader {
  LocalBackupAttachmentReader({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  @override
  Future<List<BackupEncodeAttachment>> resolve(
    List<SubjectFileRow> rows,
  ) async {
    if (rows.isEmpty) return const [];
    final support = await _directory();
    final result = <BackupEncodeAttachment>[];
    for (final row in rows) {
      final relativePath = row.relativeFilePath;
      if (!isSafeSubjectFileRelativePath(relativePath)) continue;
      final file = File(
        p.join(support.path, p.joinAll(relativePath.split('/'))),
      );
      try {
        final stat = await file.stat();
        if (stat.type != FileSystemEntityType.file) continue;
        result.add(
          BackupEncodeAttachment(
            fileId: row.id,
            filePath: file.path,
            bytes: stat.size,
          ),
        );
      } on FileSystemException {
        continue;
      }
    }
    return result;
  }
}
