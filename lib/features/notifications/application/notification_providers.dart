import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/services/notifications/android_notification_platform.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/features/notifications/application/notification_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/notifications/domain/pending_attendance_reminder.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';

final pendingAttendanceReminderProvider = Provider<CollegeOsNotification?>((
  ref,
) {
  final settings = ref.watch(collegeSettingsProvider).value;
  final snapshot = ref.watch(attendanceEngineProvider).value;
  final semester = ref.watch(activeSemesterProvider).value;
  final now = ref.watch(localMinuteProvider).value ?? DateTime.now();
  if (settings?.notificationsEnabled != true ||
      snapshot == null ||
      semester == null) {
    return null;
  }
  return PendingAttendanceReminder.next(
    snapshot: snapshot,
    semester: semester,
    now: now,
  );
});

final notificationPlatformProvider = Provider<NotificationPlatform>(
  (ref) => AndroidNotificationPlatform(),
);

final notificationCoordinatorProvider = Provider<NotificationCoordinator>(
  (ref) => NotificationCoordinator(
    platform: ref.watch(notificationPlatformProvider),
    tasks: ref.watch(taskRepositoryProvider),
    exams: ref.watch(examRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  ),
);

final notificationDiagnosticsProvider =
    FutureProvider.autoDispose<NotificationDiagnostics>((ref) async {
      final platform = ref.watch(notificationPlatformProvider);
      if (platform case final NotificationDiagnosticsPlatform diagnostics) {
        return diagnostics.diagnostics();
      }
      throw UnsupportedError('Notification diagnostics are unavailable.');
    });

final notificationPermissionControllerProvider =
    AsyncNotifierProvider<NotificationPermissionController, void>(
      NotificationPermissionController.new,
    );

final class NotificationPermissionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> enable() async {
    state = const AsyncLoading();
    bool granted = false;
    state = await AsyncValue.guard(() async {
      granted = await ref
          .read(notificationCoordinatorProvider)
          .enableWithPermission();
    });
    return !state.hasError && granted;
  }

  Future<bool> disable() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(notificationCoordinatorProvider).disable,
    );
    return !state.hasError;
  }

  Future<bool> sendTest() async {
    state = const AsyncLoading();
    var sent = false;
    state = await AsyncValue.guard(() async {
      sent = await ref
          .read(notificationCoordinatorProvider)
          .sendTestNotification();
    });
    return !state.hasError && sent;
  }
}
