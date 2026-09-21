import 'dart:typed_data';

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
    final destination = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CollegeOS backup',
      fileName: backup.fileName,
      type: FileType.custom,
      allowedExtensions: const [collegeOsBackupExtension],
      bytes: backup.bytes,
    );
    return destination != null;
  }

  @override
  Future<void> share(ExportedBackup backup) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            backup.bytes,
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
    return PickedBackupFile(name: file.name, bytes: bytes);
  }
}
