import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';

final class AcademicCalendarImpact {
  const AcademicCalendarImpact({
    required this.calendarDays,
    required this.classDays,
    required this.scheduledClasses,
  });

  final int calendarDays;
  final int classDays;
  final int scheduledClasses;
}

abstract final class AcademicCalendarImpactService {
  static AcademicCalendarImpact calculate({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _later(_dateOnly(startDate), _dateOnly(semester.startDate));
    final end = _earlier(_dateOnly(endDate), _dateOnly(semester.endDate));
    if (end.isBefore(start)) {
      return const AcademicCalendarImpact(
        calendarDays: 0,
        classDays: 0,
        scheduledClasses: 0,
      );
    }
    final scheduleOnly = AttendanceEngineSnapshot(
      subjects: snapshot.subjects,
      timetable: snapshot.timetable,
      attendance: const [],
      overrides: const [],
      calendarEvents: const [],
    );
    var calendarDays = 0;
    var classDays = 0;
    var classes = 0;
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      calendarDays++;
      final sessions = AttendanceScheduleEngine.day(
        snapshot: scheduleOnly,
        semester: semester,
        date: date,
      ).sessions;
      if (sessions.isNotEmpty) classDays++;
      classes += sessions.length;
    }
    return AcademicCalendarImpact(
      calendarDays: calendarDays,
      classDays: classDays,
      scheduledClasses: classes,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
