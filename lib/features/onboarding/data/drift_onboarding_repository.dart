import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:drift/drift.dart';

final class DriftOnboardingRepository implements OnboardingRepository {
  DriftOnboardingRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> completeSetup(CollegeSetup setup) {
    return _database.transaction(() async {
      final currentSettings = await _database.settingsDao.getSettings();
      if (currentSettings.onboardingCompleted) {
        throw StateError('CollegeOS setup has already been completed.');
      }

      await (_database.update(_database.semesters)
            ..where((row) => row.isActive.equals(true)))
          .write(const SemestersCompanion(isActive: Value(false)));

      await _database.semestersDao.insertSemester(
        SemestersCompanion.insert(
          name: 'Semester ${setup.semesterNumber}',
          semesterNumber: setup.semesterNumber,
          academicYear: setup.academicYear.trim(),
          startDate: setup.semesterStartDate,
          endDate: setup.semesterEndDate,
          isActive: const Value(true),
        ),
      );

      await _database.settingsDao.save(
        AppSettingsCompanion(
          id: const Value(1),
          studentName: Value(setup.studentName.trim()),
          collegeName: Value(setup.collegeName.trim()),
          course: Value(setup.course.trim()),
          branch: Value(setup.branch.trim()),
          academicYearStartDate: Value(setup.academicYearStartDate),
          academicYearEndDate: Value(setup.academicYearEndDate),
          defaultAttendanceTarget: Value(setup.defaultAttendanceTarget),
          themeMode: Value(currentSettings.themeMode),
          onboardingCompleted: const Value(true),
          notificationsEnabled: Value(currentSettings.notificationsEnabled),
          automaticLocalBackup: Value(currentSettings.automaticLocalBackup),
        ),
      );
    });
  }
}
