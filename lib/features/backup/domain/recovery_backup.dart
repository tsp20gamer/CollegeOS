import 'package:college_os/features/backup/domain/backup_models.dart';

const automaticRecoveryBackupLimit = 5;

final class RecoveryBackup {
  const RecoveryBackup({
    required this.id,
    required this.fileName,
    required this.bytes,
    required this.manifest,
  });

  final String id;
  final String fileName;
  final int bytes;
  final BackupManifest manifest;
}
