import 'attendance_calculator.dart';

/// A read-only what-if projection. Planned classes are never persisted.
final class AttendancePlan {
  const AttendancePlan({
    required this.current,
    required this.projected,
    required this.plannedPresent,
    required this.plannedAbsent,
  });

  final AttendanceMetrics current;
  final AttendanceMetrics projected;
  final int plannedPresent;
  final int plannedAbsent;

  int get plannedClasses => plannedPresent + plannedAbsent;

  double get percentagePointChange =>
      (projected.attendancePercentage ?? 0) -
      (current.attendancePercentage ?? 0);
}

abstract final class AttendancePlannerService {
  static AttendancePlan project({
    required AttendanceMetrics current,
    required int plannedPresent,
    required int plannedAbsent,
  }) {
    if (plannedPresent < 0 || plannedAbsent < 0) {
      throw ArgumentError('Planned attendance counts cannot be negative.');
    }
    return AttendancePlan(
      current: current,
      plannedPresent: plannedPresent,
      plannedAbsent: plannedAbsent,
      projected: AttendanceCalculator.calculate(
        presentCount: current.presentCount + plannedPresent,
        absentCount: current.absentCount + plannedAbsent,
        cancelledCount: current.cancelledCount,
        target: current.target,
      ),
    );
  }
}
