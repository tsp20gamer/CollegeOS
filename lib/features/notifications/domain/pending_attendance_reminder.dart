import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';

abstract final class PendingAttendanceReminder {
  /// Keep one OS alarm for the next eligible day. Recomputed on local changes.
  static CollegeOsNotification? next({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime now,
  }) {
    for (var offset = 0; offset < 14; offset++) {
      final date = DateTime(now.year, now.month, now.day + offset);
      if (date.isAfter(semester.endDate)) break;
      final day = AttendanceScheduleEngine.day(
        snapshot: snapshot,
        semester: semester,
        date: date,
      );
      final classes = day.sessions
          .where(
            (session) =>
                !session.subject.isArchived &&
                session.status != ClassAttendanceStatus.cancelled,
          )
          .toList();
      final pending = classes
          .where((session) => session.status == ClassAttendanceStatus.unmarked)
          .length;
      if (pending == 0) continue;
      final lastEnd = classes
          .map((session) => session.endTime)
          .reduce((a, b) => a > b ? a : b);
      final delivery = DateTime(
        date.year,
        date.month,
        date.day,
        0,
        lastEnd + 15,
      );
      // Past alarms are never rolled forward repeatedly by the minute clock.
      if (!delivery.isAfter(now)) continue;
      return (
        type: NotificationEntityType.attendance,
        entityId: 1,
        title: 'Finish today’s attendance',
        body:
            '$pending ${pending == 1 ? 'class needs' : 'classes need'} attendance. Tap to review.',
        scheduledAt: delivery,
      );
    }
    return null;
  }
}
