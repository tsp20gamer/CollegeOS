import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/schema_versions.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'migrations/college_os/generated/schema.dart';

void main() {
  test('migrates v1 data through current schema without losing data', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    schema.rawDatabase.execute('''
INSERT INTO semesters
  (id, name, semester_number, academic_year, start_date, end_date, is_active, created_at, updated_at)
VALUES (1, 'Semester 1', 1, '2026-2027', 20666, 20807, 1, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO tasks
  (id, semester_id, subject_id, title, description, type, priority, due_date,
   reminder_at, is_completed, completed_at, created_at, updated_at)
VALUES (1, 1, NULL, 'Preserved task', 'Existing data', 'study', 'high',
        20675, NULL, 0, NULL, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO app_settings
  (id, college_name, course, branch, default_attendance_target, theme_mode,
   onboarding_completed, notifications_enabled)
VALUES (1, 'Existing College', 'B.Tech', 'CSE', 0.75, 'system', 1, 0)
''');

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(
      database,
      CollegeOsSchemaVersions.current,
    );
    final task = await database.select(database.collegeTasks).getSingle();
    expect(task.title, 'Preserved task');
    expect(task.description, 'Existing data');
    expect(task.dueTime, isNull);
    final settings = await database.select(database.appSettings).getSingle();
    expect(settings.automaticLocalBackup, isTrue);
    await database.close();
  });

  test(
    'migrates v2 settings with automatic backup enabled by default',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(2);
      addTearDown(schema.close);
      schema.rawDatabase.execute('''
INSERT INTO app_settings
  (id, college_name, course, branch, default_attendance_target, theme_mode,
   onboarding_completed, notifications_enabled)
VALUES (1, 'Migration College', 'B.Tech', 'CSE', 0.8, 'dark', 1, 1)
''');

      final database = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(
        database,
        CollegeOsSchemaVersions.current,
      );
      final settings = await database.select(database.appSettings).getSingle();
      expect(settings.collegeName, 'Migration College');
      expect(settings.defaultAttendanceTarget, 0.8);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.automaticLocalBackup, isTrue);
      await database.close();
    },
  );

  test('migrates v3 exams with no reminder without losing data', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.close);
    schema.rawDatabase.execute('''
INSERT INTO semesters
  (id, name, semester_number, academic_year, start_date, end_date, is_active, created_at, updated_at)
VALUES (1, 'Semester 1', 1, '2026-2027', 20666, 20807, 1, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO subjects
  (id, semester_id, name, short_code, professor, room, attendance_target,
   display_color, is_archived, created_at, updated_at)
VALUES (1, 1, 'Algorithms', 'ALGO', '', '', 0.75, 4280391411, 0, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO exams
  (id, semester_id, subject_id, name, exam_type, exam_date, start_time,
   end_time, room, syllabus, max_marks, obtained_marks, created_at, updated_at)
VALUES (1, 1, 1, 'Midterm', 'Written', 20710, 600, 720, 'A1', '', 100, NULL, 0, 0)
''');

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(
      database,
      CollegeOsSchemaVersions.current,
    );
    final exam = await database.select(database.exams).getSingle();
    expect(exam.name, 'Midterm');
    expect(exam.reminderAt, isNull);
    await database.close();
  });

  test('migrates v4 without losing legacy attendance', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(4);
    addTearDown(schema.close);
    schema.rawDatabase.execute('''
INSERT INTO semesters
  (id, name, semester_number, academic_year, start_date, end_date, is_active, created_at, updated_at)
VALUES (1, 'Semester 1', 1, '2026-2027', 20666, 20807, 1, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO subjects
  (id, semester_id, name, short_code, professor, room, attendance_target,
   display_color, is_archived, created_at, updated_at)
VALUES (1, 1, 'Algorithms', 'ALGO', '', '', 0.75, 4280391411, 0, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO attendance_sessions
  (id, subject_id, date, period, status, note, created_at, updated_at)
VALUES (1, 1, 20677, 2, 'absent', 'Legacy record', 0, 0)
''');

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(
      database,
      CollegeOsSchemaVersions.current,
    );
    final legacy = await database
        .select(database.attendanceSessions)
        .getSingle();
    expect(legacy.note, 'Legacy record');
    expect(legacy.status.name, 'absent');
    final linked = await database
        .select(database.scheduledClassAttendance)
        .getSingle();
    expect(linked.subjectId, legacy.subjectId);
    expect(linked.attendanceStatus.name, 'absent');
    expect(linked.note, 'Legacy record');
    expect(
      await database.select(database.dailyAttendanceRecords).get(),
      isEmpty,
    );
    await database.close();
  });

  test(
    'migrates an unambiguous v5 day into linked timetable classes',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(5);
      addTearDown(schema.close);
      schema.rawDatabase.execute('''
INSERT INTO semesters
  (id, name, semester_number, academic_year, start_date, end_date, is_active, created_at, updated_at)
VALUES (1, 'Semester 1', 1, '2026-2027', 20666, 20807, 1, 0, 0)
''');
      schema.rawDatabase.execute('''
INSERT INTO subjects
  (id, semester_id, name, short_code, professor, room, attendance_target,
   display_color, is_archived, created_at, updated_at)
VALUES (1, 1, 'Algorithms', 'ALGO', '', '', 0.75, 4280391411, 0, 0, 0)
''');
      schema.rawDatabase.execute('''
INSERT INTO timetable_entries
  (id, semester_id, subject_id, weekday, start_time, end_time, room, note)
VALUES (1, 1, 1, 3, 540, 600, 'A1', '')
''');
      schema.rawDatabase.execute('''
INSERT INTO daily_attendance_records
  (id, date, status, note, created_at, updated_at)
VALUES (1, 20677, 'present', 'Legacy day', 0, 0)
''');
      schema.rawDatabase.execute('''
INSERT INTO app_settings
  (id, college_name, course, branch, default_attendance_target, theme_mode,
   onboarding_completed, notifications_enabled, automatic_local_backup)
VALUES (1, 'Migration College', 'B.Tech', 'CSE', 0.75, 'system', 1, 0, 1)
''');

      final database = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(
        database,
        CollegeOsSchemaVersions.current,
      );

      final daily = await database
          .select(database.dailyAttendanceRecords)
          .getSingle();
      expect(daily.note, 'Legacy day');
      final linked = await database
          .select(database.scheduledClassAttendance)
          .getSingle();
      expect(linked.timetableEntryId, 1);
      expect(linked.subjectId, 1);
      expect(linked.attendanceStatus.name, 'present');
      expect(linked.manuallyModified, isFalse);
      final timetable = await database
          .select(database.timetableEntries)
          .getSingle();
      expect(timetable.effectiveFrom, DateTime(2026, 8, 1));
      expect(timetable.effectiveUntil, DateTime(2026, 12, 20));
      final settings = await database.select(database.appSettings).getSingle();
      expect(settings.academicYearStartDate, DateTime(2026, 8, 1));
      expect(settings.academicYearEndDate, DateTime(2026, 12, 20));
      await database.close();
    },
  );

  test('migrates v6 to v7 and preserves linked attendance', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(6);
    addTearDown(schema.close);
    schema.rawDatabase.execute('''
INSERT INTO semesters
  (id, name, semester_number, academic_year, start_date, end_date, is_active, created_at, updated_at)
VALUES (1, 'Semester 1', 1, '2026-2027', 20678, 20802, 1, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO subjects
  (id, semester_id, name, short_code, professor, room, attendance_target,
   display_color, is_archived, created_at, updated_at)
VALUES (1, 1, 'Mathematics', 'MC', 'Mrs. Aruna', '2009', 0.75,
        4280391411, 0, 0, 0)
''');
    schema.rawDatabase.execute('''
INSERT INTO scheduled_class_attendance
  (id, semester_id, timetable_entry_id, subject_id, date, start_time,
   end_time, attendance_status, note, manually_modified, created_at, updated_at)
VALUES (1, 1, NULL, 1, 20678, 560, 610, 'present', '', 1, 0, 0)
''');

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(
      database,
      CollegeOsSchemaVersions.current,
    );

    expect(
      (await database.select(database.scheduledClassAttendance).getSingle())
          .attendanceStatus
          .name,
      'present',
    );
    expect(
      await database.select(database.academicCalendarEvents).get(),
      isEmpty,
    );
    await database.close();
  });

  test('migrates v7 settings with an empty local student name', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema = await verifier.schemaAt(7);
    addTearDown(schema.close);
    schema.rawDatabase.execute('''
INSERT INTO app_settings
  (id, college_name, course, branch, academic_year_start_date,
   academic_year_end_date, default_attendance_target, theme_mode,
   onboarding_completed, notifications_enabled, automatic_local_backup)
VALUES (1, 'Preserved College', 'B.Tech', 'CSE', 20666, 20938,
        0.8, 'dark', 1, 1, 0)
''');

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(
      database,
      CollegeOsSchemaVersions.current,
    );

    final settings = await database.settingsDao.getSettings();
    expect(settings.studentName, isEmpty);
    expect(settings.collegeName, 'Preserved College');
    expect(settings.defaultAttendanceTarget, .8);
    expect(settings.notificationsEnabled, isTrue);
    expect(settings.automaticLocalBackup, isFalse);
    await database.close();
  });
}
