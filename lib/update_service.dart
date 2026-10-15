import 'package:college_os/features/updates/application/update_providers.dart';
import 'package:college_os/features/updates/data/update_repository.dart';
import 'package:college_os/features/updates/domain/update_info.dart';
import 'package:college_os/features/updates/presentation/widgets/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Checks whether a newer CollegeOS build has been published, and offers it.
///
/// This is the app's whole update story: a release lowers `version.json` on
/// `main`, and an installed build that reads it once per launch can offer
/// itself the newer APK. It stays a convenience, never a dependency:
///
/// - the only request is a public file that describes the newest build, with no
///   user data, identifiers or analytics attached;
/// - the APK is downloaded only after the student taps Update, and installed by
///   Android's own installer, so no data is replaced behind their back;
/// - every failure is swallowed on the automatic check and reported politely on
///   a manual one, because the app must be perfectly usable offline.
class UpdateService {
  const UpdateService({required this.repository, required this.currentVersion});

  /// Reads the published release manifest.
  final UpdateRepository repository;

  /// Answers which build is installed, as `1.11.0+32`.
  final Future<String> Function() currentVersion;

  /// The app-facing entry point.
  ///
  /// Reads the app's one version source and the injectable repository from the
  /// surrounding [ProviderScope], so screens only need the context they already
  /// have and tests only need to override a provider.
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool showNoUpdateMessage = false,
  }) {
    return ProviderScope.containerOf(context, listen: false)
        .read(updateServiceProvider)
        .check(context, showNoUpdateMessage: showNoUpdateMessage);
  }

  /// Reads the published release and, when it is newer, offers it in a dialog.
  ///
  /// [showNoUpdateMessage] is what separates a student asking ("Check for
  /// updates") from the automatic launch check: only the explicit ask is told
  /// that the app is already current, or that the check could not be made.
  Future<void> check(
    BuildContext context, {
    bool showNoUpdateMessage = false,
  }) async {
    // Captured before any await so a message can still be shown after one.
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      final installed = await currentVersion();
      final latest = await repository.fetchLatest();

      if (!context.mounted) return;
      if (latest.isNewerThan(installed)) {
        await UpdateDialog.show(context, info: latest);
        return;
      }
      if (showNoUpdateMessage) {
        messenger?.showSnackBar(
          SnackBar(content: Text('CollegeOS $installed is up to date.')),
        );
      }
    } on UpdateCheckFailure catch (failure) {
      debugPrint('[UpdateService] ${failure.message}');
      if (!showNoUpdateMessage || !context.mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (error) {
      // A missing package-info implementation is one realistic cause; either
      // way the app carries on, and only an explicit ask hears about it.
      debugPrint('[UpdateService] update check failed: $error');
      if (!showNoUpdateMessage || !context.mounted) return;
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not check for updates right now. Try again later.',
          ),
        ),
      );
    }
  }
}
