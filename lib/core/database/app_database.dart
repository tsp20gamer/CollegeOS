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
        // The v6 timetable table is recreated from its own frozen definition
        // instead of the current Dart class. A `TableMigration` would build
        // this table with every column and constraint the current definition
        // has, so the class-reminder column added in v14 would silently appear
        // in every v6–v13 upgrade and the v6 shape could never change again.
        // Pinning the historical shape keeps each intermediate schema exactly
        // as it shipped, and the v14 step recreates the current shape later.
        await customStatement('''
CREATE TABLE "tmp_for_copy_timetable_entries_v6" (
  "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "semester_id" INTEGER NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
  "subject_id" INTEGER NOT NULL,
  "weekday" INTEGER NOT NULL,
  "start_time" INTEGER NOT NULL,
  "end_time" INTEGER NOT NULL,
  "room" TEXT NOT NULL DEFAULT '',
  "note" TEXT NOT NULL DEFAULT '',
  "effective_from" INTEGER NULL,
  "effective_until" INTEGER NULL,
  FOREIGN KEY(subject_id, semester_id) REFERENCES subjects(id, semester_id) ON DELETE CASCADE,
  CHECK(weekday BETWEEN 1 AND 7),
  CHECK(start_time BETWEEN 0 AND 1439),
  CHECK(end_time BETWEEN 1 AND 1440),
  CHECK(end_time > start_time),
  CHECK(effective_until IS NULL OR effective_from IS NULL OR effective_until >= effective_from)
)
''');
        await customStatement('''
INSERT INTO "tmp_for_copy_timetable_entries_v6"
  ("id", "semester_id", "subject_id", "weekday", "start_time", "end_time",
   "room", "note", "effective_from", "effective_until")
SELECT "id", "semester_id", "subject_id", "weekday", "start_time",
       "end_time", "room", "note", NULL, NULL
FROM "timetable_entries"
''');
        await customStatement('DROP TABLE "timetable_entries"');
        await customStatement(
          'ALTER TABLE "tmp_for_copy_timetable_entries_v6" '
          'RENAME TO "timetable_entries"',
        );
        await customStatement(
          'CREATE INDEX timetable_semester_weekday_start '
          'ON timetable_entries (semester_id, weekday, start_time)',
        );
        await customStatement(
          'CREATE INDEX timetable_subject '
          'ON timetable_entries (subject_id)',
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
      if (from < CollegeOsSchemaVersions.pdfSearchV2 &&
          to >= CollegeOsSchemaVersions.pdfSearchV2) {
        await migrator.alterTable(TableMigration(pdfSearchMetadata));
      }
      if (from < CollegeOsSchemaVersions.pdfIndexResume &&
          to >= CollegeOsSchemaVersions.pdfIndexResume) {
        // The v12 recreation rebuilds pdf_search_metadata from the current
        // Dart definition, which already contains last_indexed_page. Only add
        // the column when it is genuinely missing so stacked v11→v13 and
        // v12→v13 upgrades both succeed.
        final columns = await customSelect(
          'PRAGMA table_info(pdf_search_metadata)',
        ).get();
        final hasLastIndexedPage = columns.any(
          (row) => row.read<String>('name') == 'last_indexed_page',
        );
        if (!hasLastIndexedPage) {
          await migrator.addColumn(
            pdfSearchMetadata,
            pdfSearchMetadata.lastIndexedPage,
          );
        }
      }
      if (from < CollegeOsSchemaVersions.classReminders &&
          to >= CollegeOsSchemaVersions.classReminders) {
        // The v6 timetable recreation already builds the table from the current
        // definition, so a stacked upgrade can arrive here with the column in
        // place. Only recreate when it is genuinely missing, which also keeps
        // the new CHECK constraint identical to a fresh v14 create.
        final columns = await customSelect(
          'PRAGMA table_info(timetable_entries)',
        ).get();
        final hasReminder = columns.any(
          (row) => row.read<String>('name') == 'reminder_minutes_before',
        );
        if (!hasReminder) {
          // Every existing class keeps its subject, times, room and effective
          // dates; it simply carries no reminder until one is chosen.
          await migrator.alterTable(
            TableMigration(
              timetableEntries,
              newColumns: [timetableEntries.reminderMinutesBefore],
            ),
          );
        }
      }
      if (from < CollegeOsSchemaVersions.classNotifier &&
          to >= CollegeOsSchemaVersions.classNotifier) {
        // The class-notifier switch and its default lead time arrive together.
        // Both are defaulted, so every existing settings row backfills to
        // enabled with a 10-minute lead time, exactly as a fresh v15 install
        // would: nothing that already works stops firing. The lead time carries
        // a table-level CHECK constraint, so the table is recreated rather
        // than appended to. The recreation is the pinned v15 shape, written out
        // below just like the v6 timetable recreation is: a `TableMigration`
        // would build the table from the *current* Dart definition, so an app
        // that ships a later settings version would silently demand v16
        // columns from a v14 source table.
        final columns = await customSelect(
          'PRAGMA table_info(app_settings)',
        ).get();
        final hasClassReminders = columns.any(
          (row) => row.read<String>('name') == 'class_reminders_enabled',
        );
        if (!hasClassReminders) {
          await _recreatePinnedAppSettings(migrator);
        }
      }
      if (from < CollegeOsSchemaVersions.defaultHolidays &&
          to >= CollegeOsSchemaVersions.defaultHolidays) {
        // The three derived-holiday rules arrive together, all defaulted on so
        // an existing install keeps exactly the attendance it had plus the
        // holidays the student asked for: Sundays, second Saturdays and the
        // fixed national dates stop counting. They are settings, not generated
        // calendar rows, so nothing writes a holiday into the student's data.
        // The table is recreated rather than appended to, which is what keeps
        // the class-notifier CHECK and the singleton CHECK in the upgraded
        // table: a plain `addColumn` would leave the old constraints behind.
        // Like v15 above, the recreation is the pinned v16 shape instead of a
        // `TableMigration`, so the copy cannot ask a v15 table for columns it
        // does not have.
        final columns = await customSelect(
          'PRAGMA table_info(app_settings)',
        ).get();
        final hasDefaultHolidays = columns.any(
          (row) => row.read<String>('name') == 'sunday_off',
        );
        if (!hasDefaultHolidays) {
          await _recreateAppSettingsForDefaultHolidays();
        }
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

  /// Recreates `app_settings` in its exact frozen v15 shape.
  ///
  /// Mirrors the fresh-v15 create byte for byte, including the `CHECK`s a
  /// plain `addColumn` cannot attach. The copy keeps every pre-v15 value and
  /// lets the two new columns take their defaults.
  Future<void> _recreatePinnedAppSettings(Migrator migrator) async {
    await customStatement('''
CREATE TABLE "tmp_app_settings_v15" (
  "id" INTEGER NOT NULL DEFAULT 1,
  "student_name" TEXT NOT NULL DEFAULT '',
  "college_name" TEXT NOT NULL DEFAULT '',
  "course" TEXT NOT NULL DEFAULT '',
  "branch" TEXT NOT NULL DEFAULT '',
  "academic_year_start_date" INTEGER NULL,
  "academic_year_end_date" INTEGER NULL,
  "default_attendance_target" REAL NOT NULL DEFAULT 0.75,
  "theme_mode" TEXT NOT NULL DEFAULT 'system',
  "onboarding_completed" INTEGER NOT NULL DEFAULT 0 CHECK (onboarding_completed IN (0, 1)),
  "notifications_enabled" INTEGER NOT NULL DEFAULT 0 CHECK (notifications_enabled IN (0, 1)),
  "automatic_local_backup" INTEGER NOT NULL DEFAULT 1 CHECK (automatic_local_backup IN (0, 1)),
  "class_reminders_enabled" INTEGER NOT NULL DEFAULT 1 CHECK (class_reminders_enabled IN (0, 1)),
  "class_reminder_minutes_before" INTEGER NOT NULL DEFAULT 10,
  PRIMARY KEY(id),
  CHECK(id = 1),
  CHECK(default_attendance_target > 0 AND default_attendance_target <= 1),
  CHECK(theme_mode IN ('system', 'light', 'dark')),
  CHECK (class_reminder_minutes_before BETWEEN 0 AND 10080)
)
''');
    await customStatement('''
INSERT INTO "tmp_app_settings_v15"
  ("id", "student_name", "college_name", "course", "branch",
   "academic_year_start_date", "academic_year_end_date",
   "default_attendance_target", "theme_mode", "onboarding_completed",
   "notifications_enabled", "automatic_local_backup")
SELECT "id", "student_name", "college_name", "course", "branch",
       "academic_year_start_date", "academic_year_end_date",
       "default_attendance_target", "theme_mode", "onboarding_completed",
       "notifications_enabled", "automatic_local_backup"
FROM "app_settings"
''');
    await customStatement('DROP TABLE "app_settings"');
    await customStatement(
      'ALTER TABLE "tmp_app_settings_v15" RENAME TO "app_settings"',
    );
  }

  /// Recreates `app_settings` in the exact v16 shape, adding the three
  /// default-holiday rules as defaulted columns and keeping every constraint
  /// the database already enforces. The copy keeps the values the install
  /// already carries, at whatever v15-or-earlier shape it has; the three new
  /// rules take the defaults a fresh v16 install stores.
  Future<void> _recreateAppSettingsForDefaultHolidays() async {
    await customStatement('''
CREATE TABLE "tmp_app_settings_v16" (
  "id" INTEGER NOT NULL DEFAULT 1,
  "student_name" TEXT NOT NULL DEFAULT '',
  "college_name" TEXT NOT NULL DEFAULT '',
  "course" TEXT NOT NULL DEFAULT '',
  "branch" TEXT NOT NULL DEFAULT '',
  "academic_year_start_date" INTEGER NULL,
  "academic_year_end_date" INTEGER NULL,
  "default_attendance_target" REAL NOT NULL DEFAULT 0.75,
  "theme_mode" TEXT NOT NULL DEFAULT 'system',
  "onboarding_completed" INTEGER NOT NULL DEFAULT 0 CHECK (onboarding_completed IN (0, 1)),
  "notifications_enabled" INTEGER NOT NULL DEFAULT 0 CHECK (notifications_enabled IN (0, 1)),
  "automatic_local_backup" INTEGER NOT NULL DEFAULT 1 CHECK (automatic_local_backup IN (0, 1)),
  "class_reminders_enabled" INTEGER NOT NULL DEFAULT 1 CHECK (class_reminders_enabled IN (0, 1)),
  "class_reminder_minutes_before" INTEGER NOT NULL DEFAULT 10,
  "sunday_off" INTEGER NOT NULL DEFAULT 1 CHECK (sunday_off IN (0, 1)),
  "second_saturday_off" INTEGER NOT NULL DEFAULT 1 CHECK (second_saturday_off IN (0, 1)),
  "government_holidays_off" INTEGER NOT NULL DEFAULT 1 CHECK (government_holidays_off IN (0, 1)),
  PRIMARY KEY(id),
  CHECK (id = 1),
  CHECK (default_attendance_target > 0 AND default_attendance_target <= 1),
  CHECK (theme_mode IN ('system', 'light', 'dark')),
  CHECK (class_reminder_minutes_before BETWEEN 0 AND 10080)
)
''');
    await customStatement('''
INSERT INTO "tmp_app_settings_v16"
  ("id", "student_name", "college_name", "course", "branch",
   "academic_year_start_date", "academic_year_end_date",
   "default_attendance_target", "theme_mode", "onboarding_completed",
   "notifications_enabled", "automatic_local_backup",
   "class_reminders_enabled", "class_reminder_minutes_before")
SELECT "id", "student_name", "college_name", "course", "branch",
       "academic_year_start_date", "academic_year_end_date",
       "default_attendance_target", "theme_mode", "onboarding_completed",
       "notifications_enabled", "automatic_local_backup",
       "class_reminders_enabled", "class_reminder_minutes_before"
FROM "app_settings"
''');
    await customStatement('DROP TABLE "app_settings"');
    await customStatement(
      'ALTER TABLE "tmp_app_settings_v16" RENAME TO "app_settings"',
    );
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
