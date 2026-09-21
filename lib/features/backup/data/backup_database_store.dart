import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/backup/data/backup_data_snapshot.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:drift/drift.dart';

abstract interface class BackupDatabaseStore {
  Future<BackupDataSnapshot> capture();
  Future<void> restore(BackupDataSnapshot snapshot);
}

final class DriftBackupDatabaseStore implements BackupDatabaseStore {
  DriftBackupDatabaseStore(this._database, {this.beforeRestoreCommit});

  final AppDatabase _database;
  final Future<void> Function()? beforeRestoreCommit;

  @override
  Future<BackupDataSnapshot> capture() => _database.transaction(() async {
    final settings = await _database.select(_database.appSettings).getSingle();
    final semesters = await (_database.select(
      _database.semesters,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final subjects = await (_database.select(
      _database.subjects,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final timetable = await (_database.select(
      _database.timetableEntries,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final attendance = await (_database.select(
      _database.attendanceSessions,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final dailyAttendance = await (_database.select(
      _database.dailyAttendanceRecords,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final scheduledAttendance = await (_database.select(
      _database.scheduledClassAttendance,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final dayOverrides = await (_database.select(
      _database.calendarDayOverrides,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final calendarEvents = await (_database.select(
      _database.academicCalendarEvents,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final tasks = await (_database.select(
      _database.collegeTasks,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final exams = await (_database.select(
      _database.exams,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final marks = await (_database.select(
      _database.marks,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final notes = await (_database.select(
      _database.subjectNotes,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    final subjectFiles = await (_database.select(
      _database.subjectFiles,
    )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
    return BackupDataSnapshot(
      settings: settings,
      semesters: semesters,
      subjects: subjects,
      timetable: timetable,
      attendance: attendance,
      dailyAttendance: dailyAttendance,
      scheduledAttendance: scheduledAttendance,
      dayOverrides: dayOverrides,
      calendarEvents: calendarEvents,
      tasks: tasks,
      exams: exams,
      marks: marks,
      notes: notes,
      subjectFiles: subjectFiles,
    );
  });

  @override
  Future<void> restore(BackupDataSnapshot snapshot) async {
    try {
      await _database.transaction(() async {
        await _database.delete(_database.subjectFiles).go();
        await _database.delete(_database.subjectNotes).go();
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

        await _database.into(_database.appSettings).insert(snapshot.settings);
        for (final row in snapshot.semesters) {
          await _database.into(_database.semesters).insert(row);
        }
        for (final row in snapshot.subjects) {
          await _database.into(_database.subjects).insert(row);
        }
        for (final row in snapshot.notes) {
          await _database.into(_database.subjectNotes).insert(row);
        }
        for (final row in snapshot.subjectFiles) {
          await _database.into(_database.subjectFiles).insert(row);
        }
        for (final row in snapshot.timetable) {
          await _database.into(_database.timetableEntries).insert(row);
        }
        for (final row in snapshot.attendance) {
          await _database.into(_database.attendanceSessions).insert(row);
        }
        for (final row in snapshot.dailyAttendance) {
          await _database.into(_database.dailyAttendanceRecords).insert(row);
        }
        for (final row in snapshot.scheduledAttendance) {
          await _database.into(_database.scheduledClassAttendance).insert(row);
        }
        for (final row in snapshot.dayOverrides) {
          await _database.into(_database.calendarDayOverrides).insert(row);
        }
        for (final row in snapshot.calendarEvents) {
          await _database.into(_database.academicCalendarEvents).insert(row);
        }
        for (final row in snapshot.tasks) {
          await _database.into(_database.collegeTasks).insert(row);
        }
        for (final row in snapshot.exams) {
          await _database.into(_database.exams).insert(row);
        }
        for (final row in snapshot.marks) {
          await _database.into(_database.marks).insert(row);
        }
        if (!await _database.passesForeignKeyCheck()) {
          throw const BackupException(
            'restore_foreign_keys',
            'Restored data failed its relationship check.',
          );
        }
        if (!await _database.passesIntegrityCheck()) {
          throw const BackupException(
            'restore_integrity',
            'Restored data failed its integrity check.',
          );
        }
        await beforeRestoreCommit?.call();
      });
    } on BackupException {
      rethrow;
    } catch (error) {
      throw BackupException(
        'restore_failed',
        'Restore failed. Existing CollegeOS data was kept unchanged.',
        error,
      );
    }
  }
}
