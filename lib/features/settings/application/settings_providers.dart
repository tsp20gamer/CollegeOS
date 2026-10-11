import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';
import 'package:college_os/features/settings/data/attendance_csv_exporter.dart';
import 'package:college_os/features/settings/data/local_college_data_service.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final collegeSettingsProvider = StreamProvider<CollegeSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final localCollegeDataServiceProvider = Provider<LocalCollegeDataService>(
  (ref) => LocalCollegeDataService(ref.watch(appDatabaseProvider)),
);

final attendanceCsvExporterProvider = Provider<AttendanceCsvExporter>(
  (ref) => const AttendanceCsvExporter(),
);

final attendanceCsvFileGatewayProvider = Provider<AttendanceCsvFileGateway>(
  (ref) => const AndroidAttendanceCsvFileGateway(),
);

final collegeInformationControllerProvider =
    AsyncNotifierProvider<CollegeInformationController, void>(
      CollegeInformationController.new,
    );

final class CollegeInformationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    required String studentName,
    required String collegeName,
    required String course,
    required String branch,
    required double defaultAttendanceTarget,
    DateTime? academicYearStartDate,
    DateTime? academicYearEndDate,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      final current = await repository.get();
      await repository.save((
        studentName: studentName.trim(),
        collegeName: collegeName.trim(),
        course: course.trim(),
        branch: branch.trim(),
        academicYearStartDate:
            academicYearStartDate ?? current.academicYearStartDate,
        academicYearEndDate: academicYearEndDate ?? current.academicYearEndDate,
        defaultAttendanceTarget: defaultAttendanceTarget,
        themeMode: current.themeMode,
        onboardingCompleted: current.onboardingCompleted,
        notificationsEnabled: current.notificationsEnabled,
        automaticLocalBackup: current.automaticLocalBackup,
        classRemindersEnabled: current.classRemindersEnabled,
        classReminderMinutesBefore: current.classReminderMinutesBefore,
      ));
      if (current.defaultAttendanceTarget != defaultAttendanceTarget) {
        await _retargetSubjects(ref, defaultAttendanceTarget);
      }
    });
    return !state.hasError;
  }
}

final settingsPreferenceControllerProvider =
    AsyncNotifierProvider<SettingsPreferenceController, void>(
      SettingsPreferenceController.new,
    );

final class SettingsPreferenceController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> setTheme(CollegeThemeMode themeMode) => _save(
    (current) => (
      studentName: current.studentName,
      collegeName: current.collegeName,
      course: current.course,
      branch: current.branch,
      academicYearStartDate: current.academicYearStartDate,
      academicYearEndDate: current.academicYearEndDate,
      defaultAttendanceTarget: current.defaultAttendanceTarget,
      themeMode: themeMode,
      onboardingCompleted: current.onboardingCompleted,
      notificationsEnabled: current.notificationsEnabled,
      automaticLocalBackup: current.automaticLocalBackup,
      classRemindersEnabled: current.classRemindersEnabled,
      classReminderMinutesBefore: current.classReminderMinutesBefore,
    ),
  );

  /// Whether the student wants reminders for timetable classes.
  ///
  /// The reactive class-reminder projection is what actually cancels or
  /// schedules alarms; this only records the intent.
  Future<bool> setClassRemindersEnabled(bool enabled) => _save(
    (current) => (
      studentName: current.studentName,
      collegeName: current.collegeName,
      course: current.course,
      branch: current.branch,
      academicYearStartDate: current.academicYearStartDate,
      academicYearEndDate: current.academicYearEndDate,
      defaultAttendanceTarget: current.defaultAttendanceTarget,
      themeMode: current.themeMode,
      onboardingCompleted: current.onboardingCompleted,
      notificationsEnabled: current.notificationsEnabled,
      automaticLocalBackup: current.automaticLocalBackup,
      classRemindersEnabled: enabled,
      classReminderMinutesBefore: current.classReminderMinutesBefore,
    ),
  );

  /// Lead time, in minutes before a class start, offered to classes that have
  /// no reminder of their own.
  ///
  /// Values outside the range the database accepts are refused rather than
  /// clamped, so the stored setting always matches what the picker showed.
  Future<bool> setClassReminderMinutesBefore(int minutesBefore) {
    if (minutesBefore < minClassReminderLeadMinutes ||
        minutesBefore > maxClassReminderLeadMinutes) {
      return Future.value(false);
    }
    return _save(
      (current) => (
        studentName: current.studentName,
        collegeName: current.collegeName,
        course: current.course,
        branch: current.branch,
        academicYearStartDate: current.academicYearStartDate,
        academicYearEndDate: current.academicYearEndDate,
        defaultAttendanceTarget: current.defaultAttendanceTarget,
        themeMode: current.themeMode,
        onboardingCompleted: current.onboardingCompleted,
        notificationsEnabled: current.notificationsEnabled,
        automaticLocalBackup: current.automaticLocalBackup,
        classRemindersEnabled: current.classRemindersEnabled,
        classReminderMinutesBefore: minutesBefore,
      ),
    );
  }

  Future<bool> setDefaultAttendanceTarget(double target) async {
    if (target <= 0 || target > 1) return Future.value(false);
    final current = await ref.read(settingsRepositoryProvider).get();
    final saved = await _save(
      (existing) => (
        studentName: existing.studentName,
        collegeName: existing.collegeName,
        course: existing.course,
        branch: existing.branch,
        academicYearStartDate: existing.academicYearStartDate,
        academicYearEndDate: existing.academicYearEndDate,
        defaultAttendanceTarget: target,
        themeMode: existing.themeMode,
        onboardingCompleted: existing.onboardingCompleted,
        notificationsEnabled: existing.notificationsEnabled,
        automaticLocalBackup: existing.automaticLocalBackup,
        classRemindersEnabled: existing.classRemindersEnabled,
        classReminderMinutesBefore: existing.classReminderMinutesBefore,
      ),
    );
    if (!saved || current.defaultAttendanceTarget == target) return saved;
    await _retargetSubjects(ref, target);
    return saved;
  }

  Future<bool> _save(
    CollegeSettings Function(CollegeSettings current) update,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      await repository.save(update(await repository.get()));
    });
    return !state.hasError;
  }
}

final settingsDataControllerProvider =
    AsyncNotifierProvider<SettingsDataController, void>(
      SettingsDataController.new,
    );

final class SettingsDataController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> exportAttendanceCsv() => _run(() async {
    final snapshot = await ref.read(backupDatabaseStoreProvider).capture();
    final file = ref.read(attendanceCsvExporterProvider).create(snapshot);
    return ref.read(attendanceCsvFileGatewayProvider).save(file);
  });

  Future<SemesterResetSummary?> resetCurrentSemester() => _run(() async {
    final result = await ref
        .read(localCollegeDataServiceProvider)
        .resetActiveSemester();
    try {
      await ref.read(notificationCoordinatorProvider).reconcile();
    } catch (_) {
      // The durable database reset succeeded; notification cleanup retries.
    }
    return result;
  });

  Future<void> deleteAllData() => _run(() async {
    try {
      await ref.read(notificationCoordinatorProvider).disable();
    } catch (_) {
      // Continue: the local database remains the source of reminder intent.
    }
    await ref.read(localCollegeDataServiceProvider).deleteAllCollegeData();
    await ref.read(recoveryBackupStoreProvider).clear();
    await ref.read(emergencyBackupStoreProvider).clear();
    ref.invalidate(recoveryBackupsProvider);
  });

  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final value = await action();
      state = const AsyncData(null);
      return value;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final automaticLocalBackupControllerProvider =
    AsyncNotifierProvider<AutomaticLocalBackupController, void>(
      AutomaticLocalBackupController.new,
    );

final class AutomaticLocalBackupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> setEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      final current = await repository.get();
      await repository.save((
        studentName: current.studentName,
        collegeName: current.collegeName,
        course: current.course,
        branch: current.branch,
        academicYearStartDate: current.academicYearStartDate,
        academicYearEndDate: current.academicYearEndDate,
        defaultAttendanceTarget: current.defaultAttendanceTarget,
        themeMode: current.themeMode,
        onboardingCompleted: current.onboardingCompleted,
        notificationsEnabled: current.notificationsEnabled,
        automaticLocalBackup: enabled,
        classRemindersEnabled: current.classRemindersEnabled,
        classReminderMinutesBefore: current.classReminderMinutesBefore,
      ));
    });
    return !state.hasError;
  }
}

/// Re-targets every existing subject after the default attendance target
/// changes.
///
/// Attendance, the planner and analytics all read a subject's own stored
/// target, so the new default has to reach subjects that already exist or the
/// screens keep reporting the old goal.
Future<void> _retargetSubjects(Ref ref, double target) =>
    ref.read(subjectRepositoryProvider).setAllAttendanceTargets(target);
