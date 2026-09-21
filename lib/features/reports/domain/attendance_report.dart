import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';

final class SubjectAttendanceReportRow {
  const SubjectAttendanceReportRow({
    required this.semesterId,
    required this.semesterName,
    required this.subjectId,
    required this.subjectName,
    required this.shortCode,
    required this.present,
    required this.absent,
    required this.cancelled,
    required this.unmarked,
    required this.target,
  });

  final int semesterId;
  final String semesterName;
  final int subjectId;
  final String subjectName;
  final String shortCode;
  final int present;
  final int absent;
  final int cancelled;
  final int unmarked;
  final double target;

  int get held => present + absent;
  double? get percentage => held == 0 ? null : present / held * 100;
}

final class AttendanceReportData {
  const AttendanceReportData({
    required this.startDate,
    required this.endDate,
    required this.rows,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<SubjectAttendanceReportRow> rows;

  int get present => rows.fold(0, (sum, row) => sum + row.present);
  int get absent => rows.fold(0, (sum, row) => sum + row.absent);
  int get cancelled => rows.fold(0, (sum, row) => sum + row.cancelled);
  int get unmarked => rows.fold(0, (sum, row) => sum + row.unmarked);
  int get held => present + absent;
  double? get percentage => held == 0 ? null : present / held * 100;
}

abstract final class AttendanceReportService {
  static AttendanceReportData build({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime asOf,
    int? subjectId,
  }) {
    final start = _later(_dateOnly(startDate), _dateOnly(semester.startDate));
    final end = _earlier(_dateOnly(endDate), _dateOnly(semester.endDate));
    final subjects = snapshot.subjects.where(
      (subject) =>
          !subject.isArchived && (subjectId == null || subject.id == subjectId),
    );
    final reportRows = <SubjectAttendanceReportRow>[];
    // Project each day only once, shared by every subject's report row.
    final days = <AttendanceDay>[];
    for (
      var date = start;
      !date.isAfter(end);
      date = DateTime(date.year, date.month, date.day + 1)
    ) {
      days.add(
        AttendanceScheduleEngine.day(
          snapshot: snapshot,
          semester: semester,
          date: date,
        ),
      );
    }
    for (final subject in subjects) {
      var present = 0;
      var absent = 0;
      var cancelled = 0;
      var unmarked = 0;
      if (!end.isBefore(start)) {
        for (final day in days) {
          if (day.state != AttendanceDayState.holiday &&
              day.state != AttendanceDayState.collegeClosed) {
            for (final session in day.sessions.where(
              (session) => session.subject.id == subject.id,
            )) {
              switch (session.status) {
                case ClassAttendanceStatus.present:
                  present++;
                case ClassAttendanceStatus.absent:
                  absent++;
                case ClassAttendanceStatus.cancelled:
                  cancelled++;
                case ClassAttendanceStatus.unmarked:
                  if (_hasEnded(session, asOf)) unmarked++;
              }
            }
          }
        }
      }
      reportRows.add(
        SubjectAttendanceReportRow(
          semesterId: semester.id,
          semesterName: semester.name,
          subjectId: subject.id,
          subjectName: subject.name,
          shortCode: subject.shortCode,
          present: present,
          absent: absent,
          cancelled: cancelled,
          unmarked: unmarked,
          target: subject.attendanceTarget,
        ),
      );
    }
    return AttendanceReportData(
      startDate: start,
      endDate: end,
      rows: List.unmodifiable(reportRows),
    );
  }

  static ({DateTime start, DateTime end}) weekContaining(DateTime date) {
    final day = _dateOnly(date);
    final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
    return (start: start, end: start.add(const Duration(days: 6)));
  }

  static ({DateTime start, DateTime end}) monthContaining(DateTime date) => (
    start: DateTime(date.year, date.month),
    end: DateTime(date.year, date.month + 1, 0),
  );

  static AttendanceReportData combine(Iterable<AttendanceReportData> reports) {
    final values = reports.toList(growable: false);
    if (values.isEmpty) {
      final today = _dateOnly(DateTime.now());
      return AttendanceReportData(
        startDate: today,
        endDate: today,
        rows: const [],
      );
    }
    final start = values.map((report) => report.startDate).reduce(_earlier);
    final end = values.map((report) => report.endDate).reduce(_later);
    return AttendanceReportData(
      startDate: start,
      endDate: end,
      rows: List.unmodifiable([for (final report in values) ...report.rows]),
    );
  }

  static bool _hasEnded(ProjectedClassSession session, DateTime asOf) {
    final date = _dateOnly(session.date);
    final today = _dateOnly(asOf);
    if (date.isBefore(today)) return true;
    if (date.isAfter(today)) return false;
    return session.endTime <= asOf.hour * 60 + asOf.minute;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
