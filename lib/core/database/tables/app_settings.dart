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

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (id = 1)',
    'CHECK (default_attendance_target > 0 '
        'AND default_attendance_target <= 1)',
    "CHECK (theme_mode IN ('system', 'light', 'dark'))",
  ];
}
