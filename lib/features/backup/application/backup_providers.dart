import 'dart:io';

import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_attachment_reader.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/data/backup_file_gateway.dart';
import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/data/recovery_backup_service.dart';
import 'package:college_os/features/backup/data/recovery_backup_store.dart';
import 'package:college_os/features/backup/domain/recovery_backup.dart';
import 'package:college_os/features/backup/application/automatic_backup_coordinator.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final backupCodecProvider = Provider<CollegeOsBackupCodec>(
  (ref) => CollegeOsBackupCodec(),
);

final backupDatabaseStoreProvider = Provider<BackupDatabaseStore>(
  (ref) => DriftBackupDatabaseStore(ref.watch(appDatabaseProvider)),
);

final emergencyBackupStoreProvider = Provider<EmergencyBackupStore>(
  (ref) => const FileEmergencyBackupStore(),
);

final backupFileGatewayProvider = Provider<BackupFileGateway>(
  (ref) => const AndroidBackupFileGateway(),
);

final backupAttachmentReaderProvider = Provider<BackupAttachmentReader>(
  (ref) => LocalBackupAttachmentReader(),
);

typedef BackupAttachmentSummary = ({int count, int bytes});

/// Sizes of the uploaded files a full backup would carry, taken from the
/// files that actually exist on disk.
final backupAttachmentSummaryProvider = StreamProvider<BackupAttachmentSummary>(
  (ref) {
    final reader = ref.watch(backupAttachmentReaderProvider);
    return ref.watch(appDatabaseProvider).subjectFilesDao.watchAll().asyncMap((
      rows,
    ) async {
      final resolved = await reader.resolve(rows);
      var bytes = 0;
      for (final attachment in resolved) {
        bytes += attachment.bytes;
      }
      return (count: resolved.length, bytes: bytes);
    });
  },
);

typedef IncomingBackupLoader = Future<List<int>> Function(String path);
typedef IncomingBackupCleanup = Future<void> Function(String path);

final incomingBackupLoaderProvider = Provider<IncomingBackupLoader>(
  (ref) =>
      (path) => File(path).readAsBytes(),
);

final incomingBackupCleanupProvider = Provider<IncomingBackupCleanup>(
  (ref) => (path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  },
);

final backupServiceProvider = Provider<CollegeOsBackupService>(
  (ref) => CollegeOsBackupService(
    ref.watch(backupDatabaseStoreProvider),
    ref.watch(backupCodecProvider),
    ref.watch(emergencyBackupStoreProvider),
    attachmentReader: ref.watch(backupAttachmentReaderProvider),
  ),
);

final recoveryBackupStoreProvider = Provider<RecoveryBackupStore>(
  (ref) => FileRecoveryBackupStore(),
);

final recoveryBackupServiceProvider = Provider<RecoveryBackupService>(
  (ref) => RecoveryBackupService(
    backupService: ref.watch(backupServiceProvider),
    codec: ref.watch(backupCodecProvider),
    store: ref.watch(recoveryBackupStoreProvider),
  ),
);

final recoveryBackupsProvider = FutureProvider<List<RecoveryBackup>>(
  (ref) => ref.watch(recoveryBackupServiceProvider).list(),
);

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

final automaticBackupCoordinatorProvider = Provider<AutomaticBackupCoordinator>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    final coordinator = AutomaticBackupCoordinator(
      recoveryService: ref.watch(recoveryBackupServiceProvider),
      enabledChanges: ref
          .watch(settingsRepositoryProvider)
          .watch()
          .map((settings) => settings.automaticLocalBackup),
      dataChanges: database.tableUpdates().map((_) => null),
      appVersion: () => ref.read(appVersionProvider.future),
      onCreated: () => ref.invalidate(recoveryBackupsProvider),
    );
    ref.onDispose(coordinator.dispose);
    return coordinator;
  },
);

final backupControllerProvider = AsyncNotifierProvider<BackupController, void>(
  BackupController.new,
);

final class BackupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Writes a backup and opens the platform save dialog.
  ///
  /// With [includeFiles] the uploaded subject files travel inside the
  /// archive; the temporary archive is deleted once it has been saved.
  Future<bool> exportToFile({bool includeFiles = false}) => _run(() async {
    final backup = await _create(includeFiles: includeFiles);
    try {
      return await ref.read(backupFileGatewayProvider).save(backup);
    } finally {
      await ref.read(backupServiceProvider).discardExport(backup);
    }
  });

  /// Shares a backup through the platform share sheet.
  ///
  /// A file-backed share keeps its scratch archive: the receiving app may
  /// read it after the share sheet closes. It is removed on the next export
  /// or on the next launch.
  Future<void> shareBackup({bool includeFiles = false}) => _run(() async {
    final backup = await _create(includeFiles: includeFiles);
    await ref.read(backupFileGatewayProvider).share(backup);
  });

  Future<PreparedBackup?> pickAndInspect() => _run(() async {
    final picked = await ref.read(backupFileGatewayProvider).pick();
    if (picked == null) return null;
    return ref
        .read(backupServiceProvider)
        .inspect(bytes: picked.bytes, sourceName: picked.name);
  });

  Future<PreparedBackup> inspectIncomingFile(String path) => _run(() async {
    final file = File(path);
    final load = ref.read(incomingBackupLoaderProvider);
    final cleanup = ref.read(incomingBackupCleanupProvider);
    try {
      final bytes = await load(path);
      final cachedName = file.uri.pathSegments.last;
      final sourceName = cachedName.replaceFirst(
        RegExp(r'^[0-9a-fA-F-]{36}_'),
        '',
      );
      return ref
          .read(backupServiceProvider)
          .inspect(bytes: bytes, sourceName: sourceName);
    } finally {
      try {
        await cleanup(path);
      } catch (_) {
        // Android cache cleanup must not hide the validation/preview result.
      }
    }
  });

  Future<void> restore(PreparedBackup backup) => _run(() async {
    final version = await ref.read(appVersionProvider.future);
    await ref.read(backupServiceProvider).restore(backup, version);
    await _tryReconcileNotifications();
  });

  Future<PreparedBackup> prepareRecovery(String id) =>
      _run(() => ref.read(recoveryBackupServiceProvider).prepare(id));

  Future<void> restoreRecovery(PreparedBackup backup) => _run(() async {
    final version = await ref.read(appVersionProvider.future);
    await ref.read(recoveryBackupServiceProvider).restore(backup, version);
    await _tryReconcileNotifications();
    ref.invalidate(recoveryBackupsProvider);
  });

  /// Throws away attachments staged by an inspect the student did not
  /// restore. Best-effort: the next inspect or launch cleans up anyway.
  Future<void> discardPrepared() async {
    try {
      await ref.read(backupServiceProvider).discardStaging();
    } catch (_) {
      // Stale staging never blocks the student.
    }
  }

  Future<void> _tryReconcileNotifications() async {
    try {
      await ref.read(notificationCoordinatorProvider).reconcile();
    } catch (_) {
      // Restored reminder intent is durable; the next launch retries it.
    }
  }

  Future<ExportedBackup> _create({bool includeFiles = false}) async {
    final version = await ref.read(appVersionProvider.future);
    return ref
        .read(backupServiceProvider)
        .create(version, includeFiles: includeFiles);
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
