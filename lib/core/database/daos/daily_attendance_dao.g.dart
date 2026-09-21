// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_attendance_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyAttendanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyAttendanceRecordsTable get dailyAttendanceRecords =>
      attachedDatabase.dailyAttendanceRecords;
  DailyAttendanceDaoManager get managers => DailyAttendanceDaoManager(this);
}

class DailyAttendanceDaoManager {
  final _$DailyAttendanceDaoMixin _db;
  DailyAttendanceDaoManager(this._db);
  $$DailyAttendanceRecordsTableTableManager get dailyAttendanceRecords =>
      $$DailyAttendanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.dailyAttendanceRecords,
      );
}
