import 'package:college_os/core/database/database_enums.dart';

/// Attendance target used when nothing is stored yet.
///
/// One value, mirrors of which live only in the `app_settings` and `subjects`
/// column defaults. Every readout resolves a missing target through this
/// constant instead of repeating the number, so the stored setting stays the
/// single goal the app compares against.
const double kDefaultAttendanceTarget = 0.75;

typedef CollegeSettings = ({
  String studentName,
  String collegeName,
  String course,
  String branch,
  DateTime? academicYearStartDate,
  DateTime? academicYearEndDate,
  double defaultAttendanceTarget,
  CollegeThemeMode themeMode,
  bool onboardingCompleted,
  bool notificationsEnabled,
  bool automaticLocalBackup,

  /// Whether the student wants reminders for timetable classes.
  ///
  /// Independent of [notificationsEnabled]: that switch pauses every reminder
  /// type, while this one pauses only classes.
  bool classRemindersEnabled,

  /// Lead time, in minutes before a class start, offered to classes that have
  /// no reminder of their own.
  int classReminderMinutesBefore,
});

abstract interface class SettingsRepository {
  Stream<CollegeSettings> watch();
  Future<CollegeSettings> get();
  Future<void> save(CollegeSettings settings);
}
