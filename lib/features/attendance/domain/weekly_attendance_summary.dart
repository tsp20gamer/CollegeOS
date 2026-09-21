import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/reports/domain/attendance_report.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';

final class WeeklyAttendanceSummary {
  const WeeklyAttendanceSummary({
    required this.current,
    required this.previous,
  });
  final AttendanceReportData current;
  final AttendanceReportData previous;

  double? get change =>
      current.percentage == null || previous.percentage == null
      ? null
      : current.percentage! - previous.percentage!;

  List<SubjectAttendanceReportRow> get needsAttention => current.rows
      .where(
        (row) => row.percentage != null && row.percentage! < row.target * 100,
      )
      .toList(growable: false);

  static WeeklyAttendanceSummary build({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime now,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    final monday = DateTime(day.year, day.month, day.day - day.weekday + 1);
    AttendanceReportData report(DateTime start, DateTime end) =>
        AttendanceReportService.build(
          snapshot: snapshot,
          semester: semester,
          startDate: start,
          endDate: end,
          asOf: now,
        );
    return WeeklyAttendanceSummary(
      current: report(monday, day),
      previous: report(
        DateTime(monday.year, monday.month, monday.day - 7),
        DateTime(monday.year, monday.month, monday.day - 1),
      ),
    );
  }
}
