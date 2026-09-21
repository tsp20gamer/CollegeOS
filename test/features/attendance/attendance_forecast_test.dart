import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact target is fragile and one miss falls below target', () {
    final forecast = _forecast(3, 1);
    expect(forecast.riskLevel, AttendanceRiskLevel.fragile);
    expect(forecast.fallsBelowTargetIfNextMissed, isTrue);
    expect(forecast.afterMissingNext.attendancePercentage, 60);
    expect(forecast.afterAttendingNext.attendancePercentage, 80);
  });

  test('healthy attendance stays on track after one miss', () {
    final forecast = _forecast(9, 1);
    expect(forecast.riskLevel, AttendanceRiskLevel.onTrack);
    expect(forecast.fallsBelowTargetIfNextMissed, isFalse);
    expect(
      forecast.afterMissingNext.attendancePercentage,
      closeTo(81.818, .001),
    );
  });

  test('below-target and empty records receive stable risk levels', () {
    expect(_forecast(2, 2).riskLevel, AttendanceRiskLevel.belowTarget);
    expect(_forecast(0, 0).riskLevel, AttendanceRiskLevel.noData);
  });
}

AttendanceForecast _forecast(int present, int absent) =>
    AttendanceForecastService.calculate(
      AttendanceCalculator.calculate(
        presentCount: present,
        absentCount: absent,
        cancelledCount: 0,
        target: .75,
      ),
    );
