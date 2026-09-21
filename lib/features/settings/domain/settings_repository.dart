import 'package:college_os/core/database/database_enums.dart';

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
});

abstract interface class SettingsRepository {
  Stream<CollegeSettings> watch();
  Future<CollegeSettings> get();
  Future<void> save(CollegeSettings settings);
}
