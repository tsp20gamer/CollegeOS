import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/services/notifications/android_notification_platform.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/features/notifications/application/notification_coordinator.dart';
import 'package:college_os/features/notifications/application/class_reminder_providers.dart';
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

typedef NotificationDeliveryStatus = ({
  bool enabledInCollegeOs,
  bool enabledByAndroid,
  int scheduledReminderCount,
});

final notificationDeliveryStatusProvider =
    FutureProvider<NotificationDeliveryStatus>((ref) async {
      final settings = await ref.watch(collegeSettingsProvider.future);
      final platform = ref.watch(notificationPlatformProvider);
      final androidEnabled = await platform.notificationsEnabled();
      final pending = await platform.pending();
      final reminderCount = pending
          .where((item) => parseNotificationPayload(item.payload) != null)
          .length;
      return (
        enabledInCollegeOs: settings.notificationsEnabled,
        enabledByAndroid: androidEnabled,
        scheduledReminderCount: reminderCount,
      );
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
    ref.invalidate(notificationDeliveryStatusProvider);
    return !state.hasError && granted;
  }

  Future<bool> disable() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(notificationCoordinatorProvider).disable,
    );
    ref.invalidate(notificationDeliveryStatusProvider);
    return !state.hasError;
  }

  Future<bool> repair() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final coordinator = ref.read(notificationCoordinatorProvider);
      await coordinator.reconcile();

      final settings = ref.read(collegeSettingsProvider).value;
      if (settings == null) return;

      // Class and attendance reminders have their own projections. Only sync
      // them when their inputs are ready, so an in-flight provider does not
      // look like an empty plan and cancel a valid reminder.
      final classReminders = ref.read(pendingClassRemindersProvider);
      if (classReminders != null) {
        await coordinator.syncClassReminders(classReminders);
      }
      final attendanceInputsReady =
          !settings.notificationsEnabled ||
          (ref.read(attendanceEngineProvider).hasValue &&
              ref.read(activeSemesterProvider).hasValue &&
              ref.read(localMinuteProvider).hasValue);
      if (attendanceInputsReady) {
        await coordinator.syncAttendanceReminder(
          ref.read(pendingAttendanceReminderProvider),
        );
      }
    });
    ref.invalidate(notificationDeliveryStatusProvider);
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
    ref.invalidate(notificationDeliveryStatusProvider);
    return !state.hasError && sent;
  }
}
