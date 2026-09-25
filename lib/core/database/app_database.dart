import 'package:college_os/core/database/connection/open_database.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/daos/attendance_dao.dart';
import 'package:college_os/core/database/daos/academic_calendar_dao.dart';
import 'package:college_os/core/database/daos/attendance_engine_dao.dart';
import 'package:college_os/core/database/daos/daily_attendance_dao.dart';
import 'package:college_os/core/database/daos/exams_dao.dart';
import 'package:college_os/core/database/daos/marks_dao.dart';
import 'package:college_os/core/database/daos/semesters_dao.dart';
import 'package:college_os/core/database/daos/settings_dao.dart';
import 'package:college_os/core/database/daos/subjects_dao.dart';
import 'package:college_os/core/database/daos/subject_notes_dao.dart';
import 'package:college_os/core/database/daos/subject_files_dao.dart';
import 'package:college_os/core/database/daos/tasks_dao.dart';
import 'package:college_os/core/database/daos/timetable_dao.dart';
import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/schema_versions.dart';
import 'package:college_os/core/database/tables/app_settings.dart';
import 'package:college_os/core/database/tables/academic_calendar_events.dart';
import 'package:college_os/core/database/tables/calendar_day_overrides.dart';
import 'package:college_os/core/database/tables/attendance_sessions.dart';
import 'package:college_os/core/database/tables/college_tasks.dart';
import 'package:college_os/core/database/tables/daily_attendance_records.dart';
import 'package:college_os/core/database/tables/exams.dart';
import 'package:college_os/core/database/tables/marks.dart';
import 'package:college_os/core/database/tables/scheduled_class_attendance.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:college_os/core/database/tables/subject_notes.dart';
import 'package:college_os/core/database/tables/subject_files.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:college_os/core/database/tables/timetable_entries.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {'tables/pdf_search_index.drift'},
  tables: [
    Semesters,
    Subjects,
    TimetableEntries,
    AttendanceSessions,
    DailyAttendanceRecords,
    ScheduledClassAttendance,
    CalendarDayOverrides,
    AcademicCalendarEvents,
    CollegeTasks,
    Exams,
    Marks,
    AppSettings,
    SubjectNotes,
    SubjectFiles,
  ],
  daos: [
    SemestersDao,
    SubjectsDao,
    TimetableDao,
    AttendanceDao,
    DailyAttendanceDao,
    AttendanceEngineDao,
    AcademicCalendarDao,
    TasksDao,
    ExamsDao,
    MarksDao,
    SettingsDao,
    SubjectNotesDao,
    SubjectFilesDao,
    PdfSearchDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openCollegeOsDatabase());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => CollegeOsSchemaVersions.current;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await into(appSettings).insert(const AppSettingsCompanion());
    },
    onUpgrade: (migrator, from, to) async {
      if (from < CollegeOsSchemaVersions.tasksDueTime &&
          to >= CollegeOsSchemaVersions.tasksDueTime) {
        await migrator.alterTable(
          TableMigration(collegeTasks, newColumns: [collegeTasks.dueTime]),
        );
      }
      if (from < CollegeOsSchemaVersions.automaticLocalBackup &&
          to >= CollegeOsSchemaVersions.automaticLocalBackup) {
        await migrator.addColumn(appSettings, appSettings.automaticLocalBackup);
      }
      if (from < CollegeOsSchemaVersions.examReminders &&
          to >= CollegeOsSchemaVersions.examReminders) {
        await migrator.addColumn(exams, exams.reminderAt);
      }
      if (from < CollegeOsSchemaVersions.dailyAttendance &&
          to >= CollegeOsSchemaVersions.dailyAttendance) {
        await migrator.createTable(dailyAttendanceRecords);
        await migrator.createIndex(dailyAttendanceStatus);
      }
      if (from < CollegeOsSchemaVersions.linkedClassAttendance &&
          to >= CollegeOsSchemaVersions.linkedClassAttendance) {
        await migrator.addColumn(
          appSettings,
          appSettings.academicYearStartDate,
        );
        await migrator.addColumn(appSettings, appSettings.academicYearEndDate);
        await migrator.alterTable(
          TableMigration(
            timetableEntries,
            newColumns: [
              timetableEntries.effectiveFrom,
              timetableEntries.effectiveUntil,
            ],
          ),
        );
        await migrator.createTable(scheduledClassAttendance);
        await migrator.createTable(calendarDayOverrides);
        await migrator.createIndex(scheduledAttendanceDateTimetable);
        await migrator.createIndex(scheduledAttendanceSubjectDate);
        await migrator.createIndex(scheduledAttendanceSemesterDate);
        await migrator.createIndex(calendarOverrideSemesterDate);
        await customStatement('''
UPDATE app_settings
SET academic_year_start_date = (
      SELECT MIN(start_date) FROM semesters WHERE is_active = 1
    ),
    academic_year_end_date = (
      SELECT MAX(end_date) FROM semesters WHERE is_active = 1
    )
WHERE id = 1
''');
        await customStatement('''
UPDATE timetable_entries
SET effective_from = (
      SELECT start_date FROM semesters WHERE semesters.id = timetable_entries.semester_id
    ),
    effective_until = (
      SELECT end_date FROM semesters WHERE semesters.id = timetable_entries.semester_id
    )
''');
        await _migrateAttendanceToLinkedSessions();
      }
      if (from < CollegeOsSchemaVersions.academicCalendar &&
          to >= CollegeOsSchemaVersions.academicCalendar) {
        await migrator.createTable(academicCalendarEvents);
        await migrator.createIndex(academicCalendarSemesterDates);
      }
      if (from < CollegeOsSchemaVersions.studentProfile &&
          to >= CollegeOsSchemaVersions.studentProfile) {
        await migrator.addColumn(appSettings, appSettings.studentName);
      }
      if (from < CollegeOsSchemaVersions.subjectNotes &&
          to >= CollegeOsSchemaVersions.subjectNotes) {
        await migrator.createTable(subjectNotes);
        await migrator.createIndex(subjectNotesSubjectCreated);
      }
      if (from < CollegeOsSchemaVersions.subjectFiles &&
          to >= CollegeOsSchemaVersions.subjectFiles) {
        await migrator.createTable(subjectFiles);
        await migrator.createIndex(subjectFilesSubjectCreated);
      }
      if (from < CollegeOsSchemaVersions.pdfSearch &&
          to >= CollegeOsSchemaVersions.pdfSearch) {
        await migrator.createTable(pdfSearchMetadata);
        await migrator.createTable(pdfPageFts);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<bool> passesIntegrityCheck() async {
    final result = await customSelect('PRAGMA integrity_check').getSingle();
    return result.data.values.single == 'ok';
  }

  Future<bool> passesForeignKeyCheck() async {
    final violations = await customSelect('PRAGMA foreign_key_check').get();
    return violations.isEmpty;
  }

  Future<void> _migrateAttendanceToLinkedSessions() async {
    final legacyRows = await select(attendanceSessions).get();
    final timetableRows = await select(timetableEntries).get();
    final subjectRows = await select(subjects).get();
    final semesterRows = await select(semesters).get();
    final subjectById = {for (final row in subjectRows) row.id: row};

    for (final legacy in legacyRows) {
      final subject = subjectById[legacy.subjectId];
      if (subject == null) continue;
      final dayEntries =
          timetableRows
              .where(
                (entry) =>
                    entry.semesterId == subject.semesterId &&
                    entry.weekday == legacy.date.weekday,
              )
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
      TimetableEntryRow? match;
      if (legacy.period > 0 && legacy.period <= dayEntries.length) {
        final candidate = dayEntries[legacy.period - 1];
        if (candidate.subjectId == legacy.subjectId) match = candidate;
      }
      final subjectMatches = dayEntries
          .where((entry) => entry.subjectId == legacy.subjectId)
          .toList();
      if (match == null && subjectMatches.length == 1) {
        match = subjectMatches.single;
      }
      final fallbackStart = ((legacy.period - 1).clamp(0, 23)) * 60;
      await into(scheduledClassAttendance).insert(
        ScheduledClassAttendanceCompanion.insert(
          semesterId: subject.semesterId,
          timetableEntryId: Value(match?.id),
          subjectId: legacy.subjectId,
          date: legacy.date,
          startTime: match?.startTime ?? fallbackStart,
          endTime: match?.endTime ?? (fallbackStart + 60).clamp(1, 1440),
          attendanceStatus: ClassAttendanceStatus.values.byName(
            legacy.status.name,
          ),
          note: Value(legacy.note),
          manuallyModified: const Value(true),
          createdAt: Value(legacy.createdAt),
          updatedAt: Value(legacy.updatedAt),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    final dailyRows = await select(dailyAttendanceRecords).get();
    for (final daily in dailyRows) {
      if (legacyRows.any((row) => row.date == daily.date)) continue;
      final matchingSemesters = semesterRows
          .where(
            (semester) =>
                !daily.date.isBefore(semester.startDate) &&
                !daily.date.isAfter(semester.endDate),
          )
          .toList();
      if (matchingSemesters.length != 1) continue;
      final semester = matchingSemesters.single;
      final entries = timetableRows.where(
        (entry) =>
            entry.semesterId == semester.id &&
            entry.weekday == daily.date.weekday,
      );
      for (final entry in entries) {
        await into(scheduledClassAttendance).insert(
          ScheduledClassAttendanceCompanion.insert(
            semesterId: semester.id,
            timetableEntryId: Value(entry.id),
            subjectId: entry.subjectId,
            date: daily.date,
            startTime: entry.startTime,
            endTime: entry.endTime,
            attendanceStatus: ClassAttendanceStatus.values.byName(
              daily.status.name,
            ),
            note: Value(daily.note),
            manuallyModified: const Value(false),
            createdAt: Value(daily.createdAt),
            updatedAt: Value(daily.updatedAt),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }
}
