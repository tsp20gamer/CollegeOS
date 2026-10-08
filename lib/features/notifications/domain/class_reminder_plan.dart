import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:intl/intl.dart';

/// Projects each class's reminder into exactly one Android alarm: its next
/// eligible occurrence.
///
/// The projection reads the same day model attendance uses, so holidays,
/// college-closed days, cancelled classes, one-day exceptions, archived
/// subjects and semester breaks are all respected without a second calendar.
/// Every alarm is rebuilt whenever the app runs, which is what keeps a stale
/// projection from firing after the timetable changes.
abstract final class ClassReminderPlan {
  static List<CollegeOsNotification> next({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required Iterable<TimetableEntry> entries,
    required DateTime now,
  }) {
    final entryById = <int, TimetableEntry>{};
    for (final entry in entries) {
      if (entry.reminderMinutesBefore == null) continue;
      entryById[entry.id] = entry;
    }
    if (entryById.isEmpty) return const [];

    final subjectsById = {
      for (final subject in snapshot.subjects)
        if (!subject.isArchived) subject.id: subject,
    };
    final today = DateTime(now.year, now.month, now.day);
    final semesterStart = DateTime(
      semester.startDate.year,
      semester.startDate.month,
      semester.startDate.day,
    );
    final semesterEnd = DateTime(
      semester.endDate.year,
      semester.endDate.month,
      semester.endDate.day,
    );
    final horizon = today.add(
      const Duration(days: maxClassReminderLookaheadDays),
    );
    final lastDay = horizon.isBefore(semesterEnd) ? horizon : semesterEnd;
    final firstDay = today.isBefore(semesterStart) ? semesterStart : today;
    if (firstDay.isAfter(lastDay)) return const [];

    final scheduled = <int, CollegeOsNotification>{};
    for (
      var date = firstDay;
      !date.isAfter(lastDay);
      date = date.add(const Duration(days: 1))
    ) {
      if (scheduled.length == entryById.length) break;
      final day = AttendanceScheduleEngine.day(
        snapshot: snapshot,
        semester: semester,
        date: date,
      );
      // A holiday or college-closed day has no class to remind about.
      if (day.state == AttendanceDayState.holiday ||
          day.state == AttendanceDayState.collegeClosed) {
        continue;
      }
      for (final session in day.sessions) {
        final entryId = session.timetableEntryId;
        if (entryId == null ||
            scheduled.containsKey(entryId) ||
            session.status == ClassAttendanceStatus.cancelled) {
          continue;
        }
        final entry = entryById[entryId];
        if (entry == null) continue;
        final subject = subjectsById[session.subject.id];
        if (subject == null) continue;
        final delivery = DateTime(
          date.year,
          date.month,
          date.day,
          0,
          session.startTime - entry.reminderMinutesBefore!,
        );
        // A reminder that already passed today does not block the next
        // occurrence.
        if (!delivery.isAfter(now)) continue;
        scheduled[entryId] = (
          type: NotificationEntityType.classReminder,
          entityId: entryId,
          title: subject.name,
          body: _body(session, entry, subject),
          scheduledAt: delivery,
        );
      }
    }
    final notifications = scheduled.values.toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return notifications;
  }

  static String _body(
    ProjectedClassSession session,
    TimetableEntry entry,
    Subject subject,
  ) {
    final start = DateFormat.jm().format(
      DateTime(2000, 1, 1, session.startTime ~/ 60, session.startTime % 60),
    );
    final room = (entry.room.trim().isNotEmpty ? entry.room : subject.room)
        .trim();
    return room.isEmpty ? 'Starts at $start' : 'Starts at $start • $room';
  }
}
