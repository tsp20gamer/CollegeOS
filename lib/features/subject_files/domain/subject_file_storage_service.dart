import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class SubjectFileStorageService {
  Future<({String relativeFilePath, int fileSizeBytes, String fileExtension})>
  saveFile({
    required int subjectId,
    required String originalFileName,
    required Uint8List bytes,
  });

  Future<({String relativeFilePath, int fileSizeBytes, String fileExtension})>
  saveFileFromPath({
    required int subjectId,
    required String originalFileName,
    required String sourceFilePath,
  });

  Future<File> resolveFile(String relativeFilePath);

  Future<void> deleteFile(String relativeFilePath);

  Future<void> openOrShareFile(String relativeFilePath, String title);
}

final class LocalSubjectFileStorageService
    implements SubjectFileStorageService {
  const LocalSubjectFileStorageService();

  static const _baseFolderName = 'subject_files';

  @override
  Future<({String relativeFilePath, int fileSizeBytes, String fileExtension})>
  saveFile({
    required int subjectId,
    required String originalFileName,
    required Uint8List bytes,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final subjectDir = Directory(
      p.join(supportDir.path, _baseFolderName, '$subjectId'),
    );
    await subjectDir.create(recursive: true);

    final cleanName = p
        .basename(originalFileName)
        .replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final extension = p
        .extension(cleanName)
        .replaceFirst('.', '')
        .toLowerCase();
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    final targetFile = File(p.join(subjectDir.path, uniqueName));

    await targetFile.writeAsBytes(bytes, flush: true);

    final relative = p
        .join(_baseFolderName, '$subjectId', uniqueName)
        .replaceAll('\\', '/');

    return (
      relativeFilePath: relative,
      fileSizeBytes: bytes.length,
      fileExtension: extension,
    );
  }

  @override
  Future<({String relativeFilePath, int fileSizeBytes, String fileExtension})>
  saveFileFromPath({
    required int subjectId,
    required String originalFileName,
    required String sourceFilePath,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final subjectDir = Directory(
      p.join(supportDir.path, _baseFolderName, '$subjectId'),
    );
    await subjectDir.create(recursive: true);

    final cleanName = p
        .basename(originalFileName)
        .replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final extension = p
        .extension(cleanName)
        .replaceFirst('.', '')
        .toLowerCase();
    final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';
    final targetFile = File(p.join(subjectDir.path, uniqueName));

    final sourceFile = File(sourceFilePath);
    await sourceFile.copy(targetFile.path);
    final fileSizeBytes = await sourceFile.length();

    final relative = p
        .join(_baseFolderName, '$subjectId', uniqueName)
        .replaceAll('\\', '/');

    return (
      relativeFilePath: relative,
      fileSizeBytes: fileSizeBytes,
      fileExtension: extension,
    );
  }

  @override
  Future<File> resolveFile(String relativeFilePath) async {
    final supportDir = await getApplicationSupportDirectory();
    return File(p.join(supportDir.path, relativeFilePath));
  }

  @override
  Future<void> deleteFile(String relativeFilePath) async {
    try {
      final file = await resolveFile(relativeFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort local cleanup
    }
  }

  @override
  Future<void> openOrShareFile(String relativeFilePath, String title) async {
    final file = await resolveFile(relativeFilePath);
    if (!await file.exists()) {
      throw StateError('The file no longer exists on this device.');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: title)],
        subject: title,
        text: title,
      ),
    );
  }
}
