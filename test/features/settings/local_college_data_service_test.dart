import 'dart:convert';

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/settings/data/attendance_csv_exporter.dart';
import 'package:college_os/features/settings/data/local_college_data_service.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await DriftOnboardingRepository(database).completeSetup(
      CollegeSetup(
        studentName: 'Test Student',
        collegeName: 'City College',
        course: 'B.Tech',
        branch: 'Computer Science',
        semesterNumber: 2,
        academicYear: '2026-2027',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 20),
        defaultAttendanceTarget: 0.75,
      ),
    );
  });

  tearDown(() => database.close());

  test(
    'reset clears only active semester content and preserves history',
    () async {
      final active = (await database.semestersDao.findActive())!;
      final olderId = await database
          .into(database.semesters)
          .insert(
            SemestersCompanion.insert(
              name: 'Semester 1',
              semesterNumber: 1,
              academicYear: '2025-2026',
              startDate: DateTime(2025, 8, 1),
              endDate: DateTime(2025, 12, 20),
            ),
          );
      final activeSubject = await _subject(database, active.id, 'Current');
      final oldSubject = await _subject(database, olderId, 'History');
      await _attendance(database, activeSubject, 'remove');
      await _attendance(database, oldSubject, 'keep');
      await _dailyAttendance(database, DateTime(2026, 8, 13), 'remove');
      await _dailyAttendance(database, DateTime(2025, 8, 13), 'keep');
      await database
          .into(database.collegeTasks)
          .insert(
            CollegeTasksCompanion.insert(
              semesterId: active.id,
              title: 'General task',
              type: CollegeTaskType.general,
              priority: TaskPriority.low,
            ),
          );

      final result = await LocalCollegeDataService(
        database,
      ).resetActiveSemester();

      expect(result?.semesterId, active.id);
      expect(await database.semestersDao.findActive(), isNotNull);
      expect(
        await (database.select(
          database.subjects,
        )..where((row) => row.semesterId.equals(active.id))).get(),
        isEmpty,
      );
      expect(
        await (database.select(
          database.subjects,
        )..where((row) => row.semesterId.equals(olderId))).get(),
        hasLength(1),
      );
      final attendance = await database
          .select(database.attendanceSessions)
          .get();
      expect(attendance.single.subjectId, oldSubject);
      final daily = await database
          .select(database.dailyAttendanceRecords)
          .get();
      expect(daily.single.date, DateTime(2025, 8, 13));
      expect(await database.select(database.collegeTasks).get(), isEmpty);
      expect(await database.passesForeignKeyCheck(), isTrue);
    },
  );

  test(
    'delete all restores singleton defaults and first-launch state',
    () async {
      final active = (await database.semestersDao.findActive())!;
      final subject = await _subject(database, active.id, 'Programming');
      await _attendance(database, subject, 'present');
      await _dailyAttendance(database, DateTime(2026, 8, 13), 'present');

      await LocalCollegeDataService(database).deleteAllCollegeData();

      expect(await database.select(database.semesters).get(), isEmpty);
      expect(await database.select(database.subjects).get(), isEmpty);
      expect(await database.select(database.attendanceSessions).get(), isEmpty);
      expect(
        await database.select(database.dailyAttendanceRecords).get(),
        isEmpty,
      );
      final settings = await database.settingsDao.getSettings();
      expect(settings.collegeName, isEmpty);
      expect(settings.onboardingCompleted, isFalse);
      expect(settings.notificationsEnabled, isFalse);
      expect(settings.defaultAttendanceTarget, 0.75);
      expect(await database.passesIntegrityCheck(), isTrue);
    },
  );

  test(
    'attendance CSV exports linked classes with RFC 4180 escaping',
    () async {
      final semester = (await database.semestersDao.findActive())!;
      final subjectId = await _subject(database, semester.id, 'Programming, C');
      await database
          .into(database.scheduledClassAttendance)
          .insert(
            ScheduledClassAttendanceCompanion.insert(
              semesterId: semester.id,
              subjectId: subjectId,
              date: DateTime(2026, 8, 13),
              startTime: 9 * 60,
              endTime: 10 * 60,
              attendanceStatus: ClassAttendanceStatus.present,
              note: const Value('Asked "why", then left'),
            ),
          );
      final snapshot = await DriftBackupDatabaseStore(database).capture();

      final file = const AttendanceCsvExporter().create(
        snapshot,
        createdAt: DateTime(2026, 8, 13, 15),
      );
      final csv = utf8.decode(file.bytes);

      expect(file.fileName, 'CollegeOS_Attendance_2026-08-13_1500.csv');
      expect(
        csv,
        contains('Date,Day,Start,End,Subject,Short Code,Status,Note'),
      );
      expect(csv, contains('"2026-08-13"'));
      expect(csv, contains('"Thursday"'));
      expect(csv, contains('"09:00"'));
      expect(csv, contains('"10:00"'));
      expect(csv, contains('"Programming, C"'));
      expect(csv, contains('"Asked ""why"", then left"'));
      expect(csv, contains('"present"'));
    },
  );
}

Future<int> _subject(AppDatabase database, int semesterId, String name) =>
    database
        .into(database.subjects)
        .insert(
          SubjectsCompanion.insert(
            semesterId: semesterId,
            name: name,
            displayColor: 0xFF2563EB,
          ),
        );

Future<int> _attendance(AppDatabase database, int subjectId, String note) =>
    database
        .into(database.attendanceSessions)
        .insert(
          AttendanceSessionsCompanion.insert(
            subjectId: subjectId,
            date: DateTime(2026, 8, 13),
            period: 1,
            status: AttendanceStatus.present,
            note: Value(note),
          ),
        );

Future<int> _dailyAttendance(
  AppDatabase database,
  DateTime date,
  String note,
) => database
    .into(database.dailyAttendanceRecords)
    .insert(
      DailyAttendanceRecordsCompanion.insert(
        date: date,
        status: DailyAttendanceStatus.present,
        note: Value(note),
      ),
    );
