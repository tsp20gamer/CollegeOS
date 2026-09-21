import 'package:college_os/core/database/database_enums.dart';

typedef DailyAttendanceRecord = ({
  int id,
  DateTime date,
  DailyAttendanceStatus status,
  String note,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef DailyAttendanceSummary = ({int present, int absent, int total});

extension DailyAttendanceSummaryValues on DailyAttendanceSummary {
  double? get percentage => total == 0 ? null : present * 100 / total;
}

abstract interface class DailyAttendanceRepository {
  Stream<List<DailyAttendanceRecord>> watchAll();
  Stream<List<DailyAttendanceRecord>> watchRange(
    DateTime firstDay,
    DateTime lastDay,
  );
  Stream<DailyAttendanceRecord?> watchForDate(DateTime date);
  Future<void> setStatus({
    required DateTime date,
    required DailyAttendanceStatus status,
    String note = '',
  });
  Future<void> remove(DateTime date);
}
