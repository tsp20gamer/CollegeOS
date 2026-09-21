import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'projects attended and missed classes without mutating current data',
    () {
      final current = AttendanceCalculator.calculate(
        presentCount: 8,
        absentCount: 2,
        cancelledCount: 1,
        target: .75,
      );

      final plan = AttendancePlannerService.project(
        current: current,
        plannedPresent: 2,
        plannedAbsent: 1,
      );

      expect(current.presentCount, 8);
      expect(current.absentCount, 2);
      expect(plan.projected.presentCount, 10);
      expect(plan.projected.absentCount, 3);
      expect(plan.projected.cancelledCount, 1);
      expect(plan.projected.attendancePercentage, closeTo(76.923, .001));
      expect(plan.plannedClasses, 3);
    },
  );

  test('uses the exact calculator at the target boundary', () {
    final current = AttendanceCalculator.calculate(
      presentCount: 3,
      absentCount: 1,
      cancelledCount: 0,
      target: .75,
    );
    final missed = AttendancePlannerService.project(
      current: current,
      plannedPresent: 0,
      plannedAbsent: 1,
    );
    final recovered = AttendancePlannerService.project(
      current: current,
      plannedPresent: 1,
      plannedAbsent: 0,
    );

    expect(missed.projected.isAtOrAboveTarget, isFalse);
    expect(recovered.projected.isAtOrAboveTarget, isTrue);
  });

  test('rejects negative planned counts', () {
    final current = AttendanceCalculator.calculate(
      presentCount: 1,
      absentCount: 0,
      cancelledCount: 0,
      target: .75,
    );
    expect(
      () => AttendancePlannerService.project(
        current: current,
        plannedPresent: -1,
        plannedAbsent: 0,
      ),
      throwsArgumentError,
    );
  });
}
