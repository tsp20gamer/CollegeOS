import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/settings_dao.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:drift/drift.dart';

final class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._dao);

  final SettingsDao _dao;

  @override
  Stream<CollegeSettings> watch() => _dao.watchSettings().map(_map);

  @override
  Future<CollegeSettings> get() async => _map(await _dao.getSettings());

  @override
  Future<void> save(CollegeSettings settings) => _dao.save(
    AppSettingsCompanion(
      id: const Value(1),
      studentName: Value(settings.studentName.trim()),
      collegeName: Value(settings.collegeName.trim()),
      course: Value(settings.course.trim()),
      branch: Value(settings.branch.trim()),
      academicYearStartDate: Value(settings.academicYearStartDate),
      academicYearEndDate: Value(settings.academicYearEndDate),
      defaultAttendanceTarget: Value(settings.defaultAttendanceTarget),
      themeMode: Value(settings.themeMode),
      onboardingCompleted: Value(settings.onboardingCompleted),
      notificationsEnabled: Value(settings.notificationsEnabled),
      automaticLocalBackup: Value(settings.automaticLocalBackup),
      classRemindersEnabled: Value(settings.classRemindersEnabled),
      classReminderMinutesBefore: Value(settings.classReminderMinutesBefore),
    ),
  );

  CollegeSettings _map(AppSettingsRow row) => (
    studentName: row.studentName,
    collegeName: row.collegeName,
    course: row.course,
    branch: row.branch,
    academicYearStartDate: row.academicYearStartDate,
    academicYearEndDate: row.academicYearEndDate,
    defaultAttendanceTarget: row.defaultAttendanceTarget,
    themeMode: row.themeMode,
    onboardingCompleted: row.onboardingCompleted,
    notificationsEnabled: row.notificationsEnabled,
    automaticLocalBackup: row.automaticLocalBackup,
    classRemindersEnabled: row.classRemindersEnabled,
    classReminderMinutesBefore: row.classReminderMinutesBefore,
  );
}
