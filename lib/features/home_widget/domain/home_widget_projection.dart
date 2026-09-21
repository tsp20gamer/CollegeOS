import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';

final class HomeWidgetProjection {
  const HomeWidgetProjection({
    required this.classLabel,
    required this.classTitle,
    required this.classTime,
    required this.classMeta,
    required this.attendanceTitle,
    required this.attendanceSummary,
    required this.attendanceMeta,
    required this.attendanceStatus,
    required this.attendanceProgress,
    required this.dateKey,
  });

  final String classLabel;
  final String classTitle;
  final String classTime;
  final String classMeta;
  final String attendanceTitle;
  final String attendanceSummary;
  final String attendanceMeta;
  final String attendanceStatus;
  final int attendanceProgress;
  final String dateKey;

  Map<String, String> get values => {
    'widget_class_label': classLabel,
    'widget_class_title': classTitle,
    'widget_class_time': classTime,
    'widget_class_meta': classMeta,
    'widget_attendance_title': attendanceTitle,
    'widget_attendance_summary': attendanceSummary,
    'widget_attendance_meta': attendanceMeta,
    'widget_attendance_status': attendanceStatus,
    'widget_attendance_progress': '$attendanceProgress',
    'widget_date_key': dateKey,
  };

  String get fingerprint =>
      values.entries.map((entry) => '${entry.key}=${entry.value}').join('|');
}

abstract final class HomeWidgetProjectionBuilder {
  static HomeWidgetProjection build({
    required DateTime now,
    required NextClassResult nextClass,
    required AttendanceDay? attendanceDay,
  }) {
    final excludedToday =
        attendanceDay?.state == AttendanceDayState.holiday ||
        attendanceDay?.state == AttendanceDayState.collegeClosed;
    final current = nextClass.currentClass;
    final upcoming = nextClass.nextClass;
    final selected = excludedToday ? null : current ?? upcoming;
    final classLabel = excludedToday
        ? 'TODAY'
        : current == null
        ? 'NEXT CLASS'
        : 'HAPPENING NOW';
    final classTitle = excludedToday
        ? attendanceDay!.state == AttendanceDayState.holiday
              ? 'Holiday'
              : 'College closed'
        : selected?.subject.name ?? 'No upcoming class';
    final classTime = excludedToday
        ? 'No classes scheduled'
        : switch ((current, upcoming, nextClass.daysUntilNext)) {
            (final value?, _, _) => 'Until ${_formatTime(value.entry.endTime)}',
            (_, final value?, 0) =>
              'Today · ${_formatTime(value.entry.startTime)}',
            (_, final value?, 1) =>
              'Tomorrow · ${_formatTime(value.entry.startTime)}',
            (_, final value?, final days?) =>
              'In $days days · ${_formatTime(value.entry.startTime)}',
            _ => 'Timetable is clear',
          };
    final classMeta = excludedToday
        ? attendanceDay?.override?.note ?? 'Attendance is excluded'
        : selected == null
        ? 'Open CollegeOS to view your timetable'
        : [
            selected.entry.room.isEmpty
                ? selected.subject.room
                : selected.entry.room,
            selected.subject.professor,
          ].where((value) => value.trim().isNotEmpty).join(' · ');

    final attendance = _attendance(attendanceDay);
    return HomeWidgetProjection(
      classLabel: classLabel,
      classTitle: classTitle,
      classTime: classTime,
      classMeta: classMeta,
      attendanceTitle: attendance.$1,
      attendanceSummary: attendance.$2,
      attendanceMeta: attendance.$3,
      attendanceStatus: attendance.$4,
      attendanceProgress: attendance.$5,
      dateKey: _dateKey(now),
    );
  }

  static (String, String, String, String, int) _attendance(AttendanceDay? day) {
    if (day == null) {
      return (
        'TODAY',
        'No active semester',
        'Open CollegeOS',
        'Unavailable',
        0,
      );
    }
    switch (day.state) {
      case AttendanceDayState.holiday:
        return (
          'TODAY',
          'Holiday',
          day.override?.note ?? 'No classes counted',
          'Holiday',
          100,
        );
      case AttendanceDayState.collegeClosed:
        return (
          'TODAY',
          'College closed',
          day.override?.note ?? 'No classes counted',
          'Closed',
          100,
        );
      case AttendanceDayState.noClasses:
        return (
          'TODAY',
          'No classes today',
          'Enjoy the open schedule',
          'Clear day',
          100,
        );
      case AttendanceDayState.outsideSemester:
        return (
          'TODAY',
          'Outside semester',
          'No attendance scheduled',
          'Outside semester',
          0,
        );
      default:
        break;
    }
    final present = _count(day, ClassAttendanceStatus.present);
    final absent = _count(day, ClassAttendanceStatus.absent);
    final cancelled = _count(day, ClassAttendanceStatus.cancelled);
    final unmarked = _count(day, ClassAttendanceStatus.unmarked);
    final summary = '$present present · $absent absent';
    final details = <String>[
      '$unmarked unmarked',
      if (cancelled > 0) '$cancelled cancelled',
    ].join(' · ');
    final eligible = present + absent + unmarked;
    final marked = present + absent;
    final progress = eligible == 0 ? 100 : (marked * 100 / eligible).round();
    final status = unmarked > 0
        ? '$unmarked pending'
        : switch (day.state) {
            AttendanceDayState.present => 'Fully present',
            AttendanceDayState.absent => 'Fully absent',
            AttendanceDayState.partial => 'Partial attendance',
            AttendanceDayState.unmarked => 'Not marked',
            _ => 'Today',
          };
    return ('TODAY\'S ATTENDANCE', summary, details, status, progress);
  }

  static int _count(AttendanceDay day, ClassAttendanceStatus status) =>
      day.sessions.where((session) => session.status == status).length;

  static String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
