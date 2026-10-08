import 'package:college_os/core/database/tables/semesters.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
// Used by Drift when validating the composite foreign-key SQL below.
// ignore: unused_import
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('TimetableEntryRow')
@TableIndex(
  name: 'timetable_semester_weekday_start',
  columns: {#semesterId, #weekday, #startTime},
)
@TableIndex(name: 'timetable_subject', columns: {#subjectId})
class TimetableEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get subjectId => integer()();
  IntColumn get weekday => integer()();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  TextColumn get room => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get effectiveFrom =>
      integer().map(const EpochDayConverter()).nullable()();
  IntColumn get effectiveUntil =>
      integer().map(const EpochDayConverter()).nullable()();

  /// Lead time, in minutes before [startTime], for this class's reminder.
  ///
  /// `null` means the class has no reminder. The lead time is relative to each
  /// occurrence, so a weekly class reminds before every one of its classes.
  /// Declared last so a migration that only adds this column produces the same
  /// table SQL as a fresh create.
  IntColumn get reminderMinutesBefore => integer().nullable()();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (subject_id, semester_id) '
        'REFERENCES subjects (id, semester_id) ON DELETE CASCADE',
    'CHECK (weekday BETWEEN 1 AND 7)',
    'CHECK (start_time BETWEEN 0 AND 1439)',
    'CHECK (end_time BETWEEN 1 AND 1440)',
    'CHECK (end_time > start_time)',
    'CHECK (effective_until IS NULL OR effective_from IS NULL '
        'OR effective_until >= effective_from)',
    'CHECK (reminder_minutes_before IS NULL OR '
        'reminder_minutes_before BETWEEN 0 AND 10080)',
  ];
}
