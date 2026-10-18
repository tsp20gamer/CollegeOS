import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

final class PickedBackupFile {
  const PickedBackupFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

abstract interface class BackupFileGateway {
  Future<bool> save(ExportedBackup backup);
  Future<void> share(ExportedBackup backup);
  Future<PickedBackupFile?> pick();
}

final class AndroidBackupFileGateway implements BackupFileGateway {
  const AndroidBackupFileGateway();

  @override
  Future<bool> save(ExportedBackup backup) async {
    // The platform save dialog needs the whole file in memory, so a backup
    // that carries attached files is read back from its scratch file first.
    // The 200 MB attachment limit keeps that a bounded, one-time cost.
    final bytes = await readExportedBackupBytes(backup);
    final destination = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CollegeOS backup',
      fileName: backup.fileName,
      type: FileType.custom,
      allowedExtensions: const [collegeOsBackupExtension],
      bytes: bytes,
    );
    return destination != null;
  }

  @override
  Future<void> share(ExportedBackup backup) async {
    final filePath = backup.filePath;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          filePath != null
              ? XFile(
                  filePath,
                  mimeType: collegeOsBackupMimeType,
                  name: backup.fileName,
                )
              : XFile.fromData(
                  backup.bytes!,
                  mimeType: collegeOsBackupMimeType,
                  name: backup.fileName,
                ),
        ],
        fileNameOverrides: [backup.fileName],
        subject: 'CollegeOS backup',
        text: 'Full offline CollegeOS backup. Keep this file private.',
      ),
    );
  }

  @override
  Future<PickedBackupFile?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose CollegeOS backup',
      type: FileType.custom,
      allowedExtensions: const [collegeOsBackupExtension],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const BackupException(
        'file_read_failed',
        'CollegeOS could not read the selected backup file.',
      );
    }
    // Some platforms also copy the picked file to a cache path; it is no
    // longer needed once the bytes are in memory.
    final cachePath = file.path;
    if (cachePath != null) {
      try {
        final cached = File(cachePath);
        if (await cached.exists()) await cached.delete();
      } catch (_) {
        // The system clears its own cache folder eventually.
      }
    }
    return PickedBackupFile(name: file.name, bytes: bytes);
  }
}
