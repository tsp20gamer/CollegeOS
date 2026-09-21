import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/daily_attendance_records.dart';
import 'package:drift/drift.dart';

part 'daily_attendance_dao.g.dart';

@DriftAccessor(tables: [DailyAttendanceRecords])
class DailyAttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$DailyAttendanceDaoMixin {
  DailyAttendanceDao(super.attachedDatabase);

  Stream<List<DailyAttendanceRecordRow>> watchAll() {
    final query = select(dailyAttendanceRecords)
      ..orderBy([(row) => OrderingTerm.desc(row.date)]);
    return query.watch();
  }

  Stream<List<DailyAttendanceRecordRow>> watchRange(
    DateTime firstDay,
    DateTime lastDay,
  ) {
    final converter = const EpochDayConverter();
    final query = select(dailyAttendanceRecords)
      ..where(
        (row) => row.date.isBetweenValues(
          converter.toSql(firstDay),
          converter.toSql(lastDay),
        ),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.date)]);
    return query.watch();
  }

  Stream<DailyAttendanceRecordRow?> watchForDate(DateTime date) {
    final epochDay = const EpochDayConverter().toSql(date);
    return (select(
      dailyAttendanceRecords,
    )..where((row) => row.date.equals(epochDay))).watchSingleOrNull();
  }

  Future<DailyAttendanceRecordRow?> getForDate(DateTime date) {
    final epochDay = const EpochDayConverter().toSql(date);
    return (select(
      dailyAttendanceRecords,
    )..where((row) => row.date.equals(epochDay))).getSingleOrNull();
  }

  Future<int> upsert(DailyAttendanceRecordsCompanion record) =>
      into(dailyAttendanceRecords).insertOnConflictUpdate(record);

  Future<int> deleteForDate(DateTime date) {
    final epochDay = const EpochDayConverter().toSql(date);
    return (delete(
      dailyAttendanceRecords,
    )..where((row) => row.date.equals(epochDay))).go();
  }
}
