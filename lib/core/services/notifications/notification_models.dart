enum NotificationEntityType { task, exam, attendance, classReminder }

typedef CollegeOsNotification = ({
  NotificationEntityType type,
  int entityId,
  String title,
  String body,
  DateTime scheduledAt,
});

typedef PendingCollegeOsNotification = ({int id, String? payload});

/// Lowest id of the class-reminder band.
///
/// Tasks use their local record id, exams use it negated, attendance is
/// reserved as zero, and class reminders sit in a band above every realistic
/// record id, so all four namespaces stay disjoint at any scale.
const int classReminderNotificationIdBase = 1000000000;

/// Largest record id any namespace accepts.
///
/// Trailing reminders must also stay positive inside Android's signed 32-bit
/// notification ids, which `classReminderNotificationIdBase * 2` still does.
const int _maxNotificationEntityId = classReminderNotificationIdBase;

int notificationId(NotificationEntityType type, int entityId) {
  if (entityId <= 0 || entityId > _maxNotificationEntityId) {
    throw ArgumentError.value(entityId, 'entityId');
  }
  return switch (type) {
    NotificationEntityType.attendance => entityId == 1
        ? 0 // Tasks are positive and exams negative; zero is reserved.
        : throw ArgumentError.value(entityId, 'entityId'),
    NotificationEntityType.task => entityId,
    NotificationEntityType.exam => -entityId,
    NotificationEntityType.classReminder =>
      classReminderNotificationIdBase + entityId,
  };
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
    'classReminder' => NotificationEntityType.classReminder,
    _ => null,
  };
  return type == null ? null : (type: type, entityId: id);
}
