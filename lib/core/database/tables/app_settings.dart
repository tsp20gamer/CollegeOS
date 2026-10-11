import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:drift/drift.dart';

@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get studentName => text().withDefault(const Constant(''))();
  TextColumn get collegeName => text().withDefault(const Constant(''))();
  TextColumn get course => text().withDefault(const Constant(''))();
  TextColumn get branch => text().withDefault(const Constant(''))();
  IntColumn get academicYearStartDate =>
      integer().map(const EpochDayConverter()).nullable()();
  IntColumn get academicYearEndDate =>
      integer().map(const EpochDayConverter()).nullable()();
  RealColumn get defaultAttendanceTarget =>
      real().withDefault(const Constant(0.75))();
  TextColumn get themeMode =>
      textEnum<CollegeThemeMode>().withDefault(const Constant('system'))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get automaticLocalBackup =>
      boolean().withDefault(const Constant(true))();

  /// Whether the student wants reminders for timetable classes at all.
  ///
  /// Independent of [notificationsEnabled]: the global switch pauses every
  /// reminder type, while this one pauses only classes. Both must be on before
  /// a class alarm is handed to Android.
  BoolColumn get classRemindersEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Lead time, in minutes before a class start, offered to every class that
  /// has no reminder of its own.
  ///
  /// Mirrored by the `class_reminder_minutes_before` CHECK constraint below and
  /// by `minClassReminderLeadMinutes`/`maxClassReminderLeadMinutes`, so the
  /// database, the Settings picker and a class's own reminder agree on exactly
  /// one range. Declared last so a migration that only adds these columns
  /// produces the same table SQL as a fresh create.
  IntColumn get classReminderMinutesBefore =>
      integer().withDefault(const Constant(10))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (id = 1)',
    'CHECK (default_attendance_target > 0 '
        'AND default_attendance_target <= 1)',
    "CHECK (theme_mode IN ('system', 'light', 'dark'))",
    'CHECK (class_reminder_minutes_before BETWEEN 0 AND 10080)',
  ];
}
