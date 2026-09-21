import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:drift/drift.dart';

@DataClassName('DailyAttendanceRecordRow')
@TableIndex(name: 'daily_attendance_status', columns: {#status})
class DailyAttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer().map(const EpochDayConverter()).unique()();
  TextColumn get status => textEnum<DailyAttendanceStatus>()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('present', 'absent'))",
  ];
}
