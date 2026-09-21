import 'attendance_calculator.dart';

enum AttendanceRiskLevel { noData, onTrack, fragile, belowTarget, unreachable }

final class AttendanceForecast {
  const AttendanceForecast({
    required this.current,
    required this.afterAttendingNext,
    required this.afterMissingNext,
    required this.riskLevel,
  });

  final AttendanceMetrics current;
  final AttendanceMetrics afterAttendingNext;
  final AttendanceMetrics afterMissingNext;
  final AttendanceRiskLevel riskLevel;

  bool get needsAttention =>
      riskLevel == AttendanceRiskLevel.fragile ||
      riskLevel == AttendanceRiskLevel.belowTarget ||
      riskLevel == AttendanceRiskLevel.unreachable;

  bool get fallsBelowTargetIfNextMissed =>
      current.isAtOrAboveTarget && !afterMissingNext.isAtOrAboveTarget;
}

abstract final class AttendanceForecastService {
  static AttendanceForecast calculate(AttendanceMetrics metrics) {
    final afterAttending = AttendanceCalculator.calculate(
      presentCount: metrics.presentCount + 1,
      absentCount: metrics.absentCount,
      cancelledCount: metrics.cancelledCount,
      target: metrics.target,
    );
    final afterMissing = AttendanceCalculator.calculate(
      presentCount: metrics.presentCount,
      absentCount: metrics.absentCount + 1,
      cancelledCount: metrics.cancelledCount,
      target: metrics.target,
    );
    final risk = switch (metrics.standing) {
      AttendanceStanding.noClasses => AttendanceRiskLevel.noData,
      AttendanceStanding.unreachable => AttendanceRiskLevel.unreachable,
      AttendanceStanding.belowTarget => AttendanceRiskLevel.belowTarget,
      AttendanceStanding.atOrAboveTarget =>
        afterMissing.isAtOrAboveTarget
            ? AttendanceRiskLevel.onTrack
            : AttendanceRiskLevel.fragile,
    };
    return AttendanceForecast(
      current: metrics,
      afterAttendingNext: afterAttending,
      afterMissingNext: afterMissing,
      riskLevel: risk,
    );
  }

  static List<T> attentionFirst<T>(
    Iterable<T> values,
    AttendanceMetrics Function(T value) metricsOf,
  ) {
    final result = values.toList(growable: false);
    int rank(T value) => switch (calculate(metricsOf(value)).riskLevel) {
      AttendanceRiskLevel.unreachable => 0,
      AttendanceRiskLevel.belowTarget => 1,
      AttendanceRiskLevel.fragile => 2,
      AttendanceRiskLevel.onTrack => 3,
      AttendanceRiskLevel.noData => 4,
    };
    return [...result]..sort((a, b) {
      final byRisk = rank(a).compareTo(rank(b));
      if (byRisk != 0) return byRisk;
      final aPercentage = metricsOf(a).attendancePercentage ?? 101;
      final bPercentage = metricsOf(b).attendancePercentage ?? 101;
      return aPercentage.compareTo(bPercentage);
    });
  }
}
