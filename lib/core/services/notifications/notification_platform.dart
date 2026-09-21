import 'package:college_os/core/services/notifications/notification_models.dart';

abstract interface class NotificationPlatform {
  Future<String?> initialize(void Function(String payload) onTap);
  Future<bool> notificationsEnabled();
  Future<bool> requestPermission();
  Future<bool> requestExactAlarmPermission();
  Future<void> openNotificationSettings();
  Future<void> openBatterySettings();
  Future<void> showTestNotification();
  Future<void> schedule(CollegeOsNotification notification);
  Future<void> cancel(NotificationEntityType type, int entityId);
  Future<List<PendingCollegeOsNotification>> pending();
}

/// Temporary release-diagnostics capability. It is intentionally separate from
/// [NotificationPlatform] so removing the testing UI later does not disturb the
/// scheduling contract or its fakes.
abstract interface class NotificationDiagnosticsPlatform {
  Future<NotificationDiagnostics> diagnostics();
}
