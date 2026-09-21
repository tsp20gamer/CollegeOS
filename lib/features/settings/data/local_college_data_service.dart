import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:drift/drift.dart';

final class SemesterResetSummary {
  const SemesterResetSummary({
    required this.semesterId,
    required this.semesterName,
  });

  final int semesterId;
  final String semesterName;
}

/// Owns destructive database operations so they are atomic and testable.
final class LocalCollegeDataService {
  const LocalCollegeDataService(this._database);

  final AppDatabase _database;

  Future<SemesterResetSummary?> resetActiveSemester() =>
      _database.transaction(() async {
        final semester = await (_database.select(
          _database.semesters,
        )..where((row) => row.isActive.equals(true))).getSingleOrNull();
        if (semester == null) return null;

        const dateConverter = EpochDayConverter();
        await (_database.delete(_database.dailyAttendanceRecords)..where(
              (row) => row.date.isBetweenValues(
                dateConverter.toSql(semester.startDate),
                dateConverter.toSql(semester.endDate),
              ),
            ))
            .go();
        await (_database.delete(
          _database.scheduledClassAttendance,
        )..where((row) => row.semesterId.equals(semester.id))).go();
        await (_database.delete(
          _database.calendarDayOverrides,
        )..where((row) => row.semesterId.equals(semester.id))).go();
        await (_database.delete(
          _database.academicCalendarEvents,
        )..where((row) => row.semesterId.equals(semester.id))).go();

        // Semester-scoped tasks without a subject are not covered by a subject
        // cascade, so remove every top-level semester collection explicitly.
        await (_database.delete(
          _database.collegeTasks,
        )..where((row) => row.semesterId.equals(semester.id))).go();
        await (_database.delete(
          _database.exams,
        )..where((row) => row.semesterId.equals(semester.id))).go();
        await (_database.delete(
          _database.timetableEntries,
        )..where((row) => row.semesterId.equals(semester.id))).go();
        await (_database.delete(
          _database.subjects,
        )..where((row) => row.semesterId.equals(semester.id))).go();

        return SemesterResetSummary(
          semesterId: semester.id,
          semesterName: semester.name,
        );
      });

  Future<void> deleteAllCollegeData() => _database.transaction(() async {
    await _database.delete(_database.marks).go();
    await _database.delete(_database.exams).go();
    await _database.delete(_database.attendanceSessions).go();
    await _database.delete(_database.dailyAttendanceRecords).go();
    await _database.delete(_database.scheduledClassAttendance).go();
    await _database.delete(_database.calendarDayOverrides).go();
    await _database.delete(_database.academicCalendarEvents).go();
    await _database.delete(_database.timetableEntries).go();
    await _database.delete(_database.collegeTasks).go();
    await _database.delete(_database.subjects).go();
    await _database.delete(_database.semesters).go();
    await _database.delete(_database.appSettings).go();
    await _database
        .into(_database.appSettings)
        .insert(const AppSettingsCompanion());
  });
}
