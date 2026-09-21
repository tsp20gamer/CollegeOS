import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceCalculator', () {
    test('returns a no-classes result instead of NaN or infinity', () {
      final result = _calculate(0, 0, cancelled: 4);
      expect(result.heldClasses, 0);
      expect(result.attendancePercentage, isNull);
      expect(result.standing, AttendanceStanding.noClasses);
      expect(result.safeBunks, isNull);
      expect(result.classesRequired, isNull);
      expect(result.cancelledCount, 4);
    });

    test('handles 100 percent attendance', () {
      final result = _calculate(10, 0);
      expect(result.attendancePercentage, 100);
      expect(result.standing, AttendanceStanding.atOrAboveTarget);
      expect(result.safeBunks, 3);
    });

    test('handles exactly 75 percent without a boundary error', () {
      final result = _calculate(3, 1);
      expect(result.attendancePercentage, 75);
      expect(result.isAtOrAboveTarget, isTrue);
      expect(result.safeBunks, 0);
    });

    test('handles just above 75 percent', () {
      final result = _calculate(76, 24);
      expect(result.isAtOrAboveTarget, isTrue);
      expect(result.safeBunks, 1);
    });

    test('handles just below 75 percent', () {
      final result = _calculate(74, 26);
      expect(result.standing, AttendanceStanding.belowTarget);
      expect(result.safeBunks, isNull);
      expect(result.classesRequired, 4);
    });

    test('calculates recovery from very low attendance', () {
      final result = _calculate(1, 9);
      expect(result.attendancePercentage, 10);
      expect(result.classesRequired, 26);
    });

    test('remains exact for large class counts', () {
      final result = _calculate(750000, 250000);
      expect(result.attendancePercentage, 75);
      expect(result.safeBunks, 0);
      expect(result.classesRequired, isNull);
    });

    test('cancelled sessions never affect held classes or percentage', () {
      final withoutCancelled = _calculate(6, 2);
      final withCancelled = _calculate(6, 2, cancelled: 5000);
      expect(withCancelled.heldClasses, withoutCancelled.heldClasses);
      expect(
        withCancelled.attendancePercentage,
        withoutCancelled.attendancePercentage,
      );
      expect(withCancelled.safeBunks, withoutCancelled.safeBunks);
    });

    test('supports 65, 75, 80, and 90 percent targets', () {
      expect(_calculate(70, 30, target: 0.65).safeBunks, 7);
      expect(_calculate(6, 2, target: 0.75).safeBunks, 0);
      expect(_calculate(8, 2, target: 0.80).safeBunks, 0);
      expect(_calculate(8, 2, target: 0.90).classesRequired, 10);
    });

    test('reports a below-target 100 percent target as unreachable', () {
      final result = _calculate(9, 1, target: 1);
      expect(result.standing, AttendanceStanding.unreachable);
      expect(result.safeBunks, isNull);
      expect(result.classesRequired, isNull);
    });

    test('rejects invalid counts and targets', () {
      expect(() => _calculate(-1, 0), throwsArgumentError);
      expect(() => _calculate(1, 0, target: 0), throwsArgumentError);
      expect(() => _calculate(1, 0, target: 1.01), throwsArgumentError);
    });
  });
}

AttendanceMetrics _calculate(
  int present,
  int absent, {
  int cancelled = 0,
  double target = 0.75,
}) {
  return AttendanceCalculator.calculate(
    presentCount: present,
    absentCount: absent,
    cancelledCount: cancelled,
    target: target,
  );
}
