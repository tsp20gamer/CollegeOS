enum NotificationEntityType { task, exam, attendance }

typedef CollegeOsNotification = ({
  NotificationEntityType type,
  int entityId,
  String title,
  String body,
  DateTime scheduledAt,
});

typedef PendingCollegeOsNotification = ({int id, String? payload});

final class NotificationDiagnostics {
  const NotificationDiagnostics({
    required this.permissionEnabled,
    required this.channelExists,
    required this.channelEnabled,
    required this.channelImportance,
    required this.pendingReminderCount,
    required this.timezone,
    required this.androidSdk,
    required this.batteryOptimizationExempt,
    required this.exactAlarmAllowed,
  });

  final bool permissionEnabled;
  final bool channelExists;
  final bool channelEnabled;
  final String channelImportance;
  final int pendingReminderCount;
  final String timezone;
  final int? androidSdk;
  final bool? batteryOptimizationExempt;
  final bool? exactAlarmAllowed;
}

int notificationId(NotificationEntityType type, int entityId) {
  if (entityId <= 0) throw ArgumentError.value(entityId, 'entityId');
  if (type == NotificationEntityType.attendance) {
    if (entityId != 1) throw ArgumentError.value(entityId, 'entityId');
    return 0; // Tasks are positive and exams negative; zero is reserved.
  }
  return type == NotificationEntityType.task ? entityId : -entityId;
}

String notificationPayload(NotificationEntityType type, int entityId) =>
    '${type.name}:$entityId';

({NotificationEntityType type, int entityId})? parseNotificationPayload(
  String? payload,
) {
  if (payload == null) return null;
  final parts = payload.split(':');
  if (parts.length != 2) return null;
  final id = int.tryParse(parts[1]);
  if (id == null || id <= 0) return null;
  final type = switch (parts[0]) {
    'task' => NotificationEntityType.task,
    'exam' => NotificationEntityType.exam,
    'attendance' when id == 1 => NotificationEntityType.attendance,
    _ => null,
  };
  return type == null ? null : (type: type, entityId: id);
}
