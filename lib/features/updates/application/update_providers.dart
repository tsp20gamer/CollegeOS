import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/updates/data/update_repository.dart';
import 'package:college_os/update_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads the published release manifest.
///
/// Overridden in tests with an `http.Client` that answers locally, so no test
/// ever leaves the device.
final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => UpdateRepository(),
);

/// The update check, wired to the app's one version source.
///
/// [appVersionProvider] already answers "which build is installed" for the
/// backup metadata and Settings, so the updater reads it instead of asking the
/// platform a second time — one definition of the installed version, one place
/// to override in tests.
final updateServiceProvider = Provider<UpdateService>(
  (ref) => UpdateService(
    repository: ref.watch(updateRepositoryProvider),
    currentVersion: () => ref.read(appVersionProvider.future),
  ),
);
