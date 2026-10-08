import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'linked attendance upserts one mark per timetable class and date',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final semesterId = await _setup(database);
      final subjectId = await _subject(database, semesterId);
      final date = DateTime(2026, 8, 12);
      final timetableId = await database.timetableDao.insertEntry(
        TimetableEntriesCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: date.weekday,
          startTime: 9 * 60,
          endTime: 10 * 60,
        ),
      );

      for (final status in [
        ClassAttendanceStatus.present,
        ClassAttendanceStatus.absent,
      ]) {
        await database.attendanceEngineDao.upsertAttendance(
          ScheduledClassAttendanceCompanion.insert(
            semesterId: semesterId,
            timetableEntryId: Value(timetableId),
            subjectId: subjectId,
            date: date,
            startTime: 9 * 60,
            endTime: 10 * 60,
            attendanceStatus: status,
          ),
        );
      }

      final rows = await database
          .select(database.scheduledClassAttendance)
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.attendanceStatus, ClassAttendanceStatus.absent);
    },
  );

  testWidgets(
    'renders real timetable-driven dashboard and attendance',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final semesterId = await _setup(database);
      final subjectId = await _subject(database, semesterId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final firstTimetableId = await database.timetableDao.insertEntry(
        TimetableEntriesCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: now.weekday,
          startTime: 9 * 60,
          endTime: 10 * 60,
          room: const Value('Lab 2'),
        ),
      );
      final secondTimetableId = await database.timetableDao.insertEntry(
        TimetableEntriesCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: now.weekday,
          startTime: 10 * 60,
          endTime: 11 * 60,
          room: const Value('Lab 2'),
        ),
      );
      for (final item in [
        (firstTimetableId, 9 * 60, 10 * 60, ClassAttendanceStatus.present),
        (secondTimetableId, 10 * 60, 11 * 60, ClassAttendanceStatus.absent),
      ]) {
        await database.attendanceEngineDao.upsertAttendance(
          ScheduledClassAttendanceCompanion.insert(
            semesterId: semesterId,
            timetableEntryId: Value(item.$1),
            subjectId: subjectId,
            date: today,
            startTime: item.$2,
            endTime: item.$3,
            attendanceStatus: item.$4,
          ),
        );
      }
      await database.tasksDao.insertTask(
        CollegeTasksCompanion.insert(
          semesterId: semesterId,
          subjectId: Value(subjectId),
          title: 'Submit systems assignment',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: Value(today.add(const Duration(days: 1))),
        ),
      );
      await database.examsDao.insertExam(
        ExamsCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          name: 'Operating Systems Midterm',
          examType: 'Written',
          examDate: today.add(const Duration(days: 2)),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('home_dashboard_ready')),
      );
      // The college/semester banner was removed from Home: identity now lives
      // in the compact header (greeting plus date) and the dashboard itself.
      expect(find.text('City College'), findsNothing);
      expect(find.text('Semester 1'), findsNothing);
      expect(find.text('Operating Systems'), findsWidgets);
      expect(find.text('50.0%'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const Key('weekly_attendance_summary')),
          matching: find.text('50.0%'),
        ),
        findsOneWidget,
      );
      expect(find.text('Submit systems assignment'), findsOneWidget);
      expect(find.text('Operating Systems Midterm'), findsOneWidget);
      expect(find.text('Add Attendance'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('View Timetable'), findsOneWidget);
      expect(find.byKey(const Key('home_attendance_present')), findsOneWidget);
      expect(find.byKey(const Key('home_attendance_absent')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 35)),
  );
}

Future<int> _setup(AppDatabase database) async {
  await DriftOnboardingRepository(database).completeSetup(
    CollegeSetup(
      studentName: 'Test Student',
      collegeName: 'City College',
      course: 'B.Tech',
      branch: 'Computer Science',
      semesterNumber: 1,
      academicYear: '2026-2027',
      academicYearStartDate: DateTime(2026, 8, 1),
      academicYearEndDate: DateTime(2027, 4, 30),
      semesterStartDate: DateTime(2026, 8, 1),
      semesterEndDate: DateTime(2026, 12, 20),
      defaultAttendanceTarget: 0.75,
    ),
  );
  return (await database.semestersDao.findActive())!.id;
}

Future<int> _subject(AppDatabase database, int semesterId) =>
    DriftSubjectRepository(database.subjectsDao).create((
      semesterId: semesterId,
      name: 'Operating Systems',
      shortCode: 'OS',
      professor: 'Dr Rao',
      room: 'A-101',
      attendanceTarget: 0.75,
      displayColor: 0xFF2563EB,
    ));

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}
