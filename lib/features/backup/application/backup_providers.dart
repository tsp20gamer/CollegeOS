import 'dart:io';

import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
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

  Future<bool> exportToFile() => _run(() async {
    final backup = await _create();
    return ref.read(backupFileGatewayProvider).save(backup);
  });

  Future<void> shareBackup() => _run(() async {
    final backup = await _create();
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

  Future<void> _tryReconcileNotifications() async {
    try {
      await ref.read(notificationCoordinatorProvider).reconcile();
    } catch (_) {
      // Restored reminder intent is durable; the next launch retries it.
    }
  }

  Future<ExportedBackup> _create() async {
    final version = await ref.read(appVersionProvider.future);
    return ref.read(backupServiceProvider).create(version);
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
