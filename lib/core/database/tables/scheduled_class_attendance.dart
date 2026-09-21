import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:college_os/core/database/tables/timetable_entries.dart';
import 'package:drift/drift.dart';

@DataClassName('ScheduledClassAttendanceRow')
@TableIndex(
  name: 'scheduled_attendance_date_timetable',
  columns: {#date, #timetableEntryId},
  unique: true,
)
@TableIndex(
  name: 'scheduled_attendance_subject_date',
  columns: {#subjectId, #date},
)
@TableIndex(
  name: 'scheduled_attendance_semester_date',
  columns: {#semesterId, #date},
)
class ScheduledClassAttendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get timetableEntryId => integer().nullable().references(
    TimetableEntries,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer().map(const EpochDayConverter())();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  TextColumn get attendanceStatus => textEnum<ClassAttendanceStatus>()();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get manuallyModified =>
      boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'CHECK (start_time BETWEEN 0 AND 1439)',
    'CHECK (end_time BETWEEN 1 AND 1440)',
    'CHECK (end_time > start_time)',
    "CHECK (attendance_status IN ('unmarked', 'present', 'absent', 'cancelled'))",
  ];
}
