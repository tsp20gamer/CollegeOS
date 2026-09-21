enum AttendanceStanding { noClasses, atOrAboveTarget, belowTarget, unreachable }

final class AttendanceMetrics {
  const AttendanceMetrics({
    required this.presentCount,
    required this.absentCount,
    required this.cancelledCount,
    required this.target,
    required this.standing,
    required this.safeBunks,
    required this.classesRequired,
  });

  final int presentCount;
  final int absentCount;
  final int cancelledCount;
  final double target;
  final AttendanceStanding standing;
  final int? safeBunks;
  final int? classesRequired;

  int get heldClasses => presentCount + absentCount;

  double? get attendancePercentage =>
      heldClasses == 0 ? null : presentCount / heldClasses * 100;

  bool get hasClasses => heldClasses > 0;
  bool get isAtOrAboveTarget => standing == AttendanceStanding.atOrAboveTarget;
}

abstract final class AttendanceCalculator {
  static const int _scale = 1000000000;

  static AttendanceMetrics calculate({
    required int presentCount,
    required int absentCount,
    required int cancelledCount,
    required double target,
  }) {
    if (presentCount < 0 || absentCount < 0 || cancelledCount < 0) {
      throw ArgumentError('Attendance counts cannot be negative.');
    }
    if (!target.isFinite || target <= 0 || target > 1) {
      throw ArgumentError.value(target, 'target', 'Must be within (0, 1].');
    }

    final held = presentCount + absentCount;
    final targetUnits = (target * _scale).round().clamp(1, _scale);
    if (held == 0) {
      return AttendanceMetrics(
        presentCount: presentCount,
        absentCount: absentCount,
        cancelledCount: cancelledCount,
        target: targetUnits / _scale,
        standing: AttendanceStanding.noClasses,
        safeBunks: null,
        classesRequired: null,
      );
    }

    final presentUnits = presentCount * _scale;
    final targetHeldUnits = held * targetUnits;
    if (presentUnits >= targetHeldUnits) {
      final maximumHeld = presentUnits ~/ targetUnits;
      return AttendanceMetrics(
        presentCount: presentCount,
        absentCount: absentCount,
        cancelledCount: cancelledCount,
        target: targetUnits / _scale,
        standing: AttendanceStanding.atOrAboveTarget,
        safeBunks: (maximumHeld - held).clamp(0, maximumHeld),
        classesRequired: null,
      );
    }

    if (targetUnits == _scale) {
      return AttendanceMetrics(
        presentCount: presentCount,
        absentCount: absentCount,
        cancelledCount: cancelledCount,
        target: 1,
        standing: AttendanceStanding.unreachable,
        safeBunks: null,
        classesRequired: null,
      );
    }

    final deficit = targetHeldUnits - presentUnits;
    final gainPerAttendedClass = _scale - targetUnits;
    final required = _ceilDivide(deficit, gainPerAttendedClass);
    return AttendanceMetrics(
      presentCount: presentCount,
      absentCount: absentCount,
      cancelledCount: cancelledCount,
      target: targetUnits / _scale,
      standing: AttendanceStanding.belowTarget,
      safeBunks: null,
      classesRequired: required,
    );
  }

  static int _ceilDivide(int numerator, int denominator) =>
      (numerator + denominator - 1) ~/ denominator;
}
