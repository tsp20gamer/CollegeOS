import 'dart:io';

import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/onboarding/domain/college_setup_validator.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('onboarding validation', () {
    test('validates required values, academic year, dates, and target', () {
      expect(
        CollegeSetupValidator.requiredText('', fieldName: 'College name'),
        'College name is required.',
      );
      expect(CollegeSetupValidator.academicYear('2026-27'), isNotNull);
      expect(CollegeSetupValidator.academicYear('2026-2027'), isNull);
      expect(CollegeSetupValidator.academicYear('2026–2027'), isNull);
      expect(
        CollegeSetupValidator.dateRange(
          DateTime(2026, 8, 13),
          DateTime(2026, 12, 15),
          academicStart: DateTime(2026, 8, 13),
          academicEnd: DateTime(2027, 4, 30),
        ),
        isNull,
      );
      expect(
        CollegeSetupValidator.dateRange(
          DateTime(2026, 8, 13),
          DateTime(2026, 12, 15),
          academicStart: DateTime(2027, 4, 30),
          academicEnd: DateTime(2026, 8, 13),
        ),
        'Academic year start must be before its end.',
      );
      expect(
        CollegeSetupValidator.dateRange(
          DateTime(2026, 8, 12),
          DateTime(2026, 12, 15),
          academicStart: DateTime(2026, 8, 13),
          academicEnd: DateTime(2027, 4, 30),
        ),
        'Semester cannot start before the academic year.',
      );
      expect(
        CollegeSetupValidator.dateRange(
          DateTime(2026, 8, 13),
          DateTime(2027, 5, 1),
          academicStart: DateTime(2026, 8, 13),
          academicEnd: DateTime(2027, 4, 30),
        ),
        'Semester cannot end after the academic year.',
      );
      expect(
        CollegeSetupValidator.dateRange(
          DateTime(2026, 12, 15),
          DateTime(2026, 12, 15),
          academicStart: DateTime(2026, 8, 13),
          academicEnd: DateTime(2027, 4, 30),
        ),
        'Semester start must be before its end.',
      );
      expect(CollegeSetupValidator.attendanceTarget('0'), isNotNull);
      expect(CollegeSetupValidator.attendanceTarget('75'), isNull);
    });
  });

  test('setup persists settings and active semester after reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'college_os_onboarding_',
    );
    final file = File(p.join(directory.path, 'college_os.sqlite'));
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    var database = AppDatabase.forTesting(NativeDatabase(file));
    await DriftOnboardingRepository(database).completeSetup(_validSetup);
    await database.close();

    database = AppDatabase.forTesting(NativeDatabase(file));
    final settings = await database.settingsDao.getSettings();
    final semester = await database.semestersDao.findActive();

    expect(settings.collegeName, 'City College of Engineering');
    expect(settings.course, 'B.Tech');
    expect(settings.branch, 'Computer Science');
    expect(settings.defaultAttendanceTarget, 0.75);
    expect(settings.academicYearStartDate, DateTime(2026, 8, 1));
    expect(settings.academicYearEndDate, DateTime(2027, 4, 30));
    expect(settings.onboardingCompleted, isTrue);
    expect(semester, isNotNull);
    expect(semester!.name, 'Semester 3');
    expect(semester.semesterNumber, 3);
    expect(semester.academicYear, '2026-2027');
    expect(semester.isActive, isTrue);
    await database.close();
  });

  test('failed setup rolls back semester and settings together', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final invalid = CollegeSetup(
      studentName: _validSetup.studentName,
      collegeName: _validSetup.collegeName,
      course: _validSetup.course,
      branch: _validSetup.branch,
      semesterNumber: _validSetup.semesterNumber,
      academicYear: _validSetup.academicYear,
      semesterStartDate: _validSetup.semesterStartDate,
      semesterEndDate: _validSetup.semesterEndDate,
      defaultAttendanceTarget: 1.5,
    );

    await expectLater(
      DriftOnboardingRepository(database).completeSetup(invalid),
      throwsA(anything),
    );

    expect(await database.select(database.semesters).get(), isEmpty);
    expect(
      (await database.settingsDao.getSettings()).onboardingCompleted,
      isFalse,
    );
  });

  testWidgets(
    'first launch shows welcome and production restore entry',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('get_started_button')),
      );

      expect(find.text('CollegeOS'), findsOneWidget);
      expect(find.text('Your personal college companion.'), findsOneWidget);
      expect(find.text('Everything stays on your device.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('restore_backup_button')));
      await _pumpUntilFound(tester, find.text('Bring CollegeOS with you'));
      expect(find.byKey(const Key('import_backup')), findsOneWidget);
      await _disposeApp(tester);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  testWidgets('completing the setup form persists and opens Home', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(tester, find.byKey(const Key('get_started_button')));
    await tester.tap(find.byKey(const Key('get_started_button')));
    await _pumpUntilFound(tester, find.byKey(const Key('college_name_field')));

    expect(find.text('First semester'), findsNothing);
    expect(find.text('Current academic details'), findsOneWidget);
    expect(find.text('Current Semester'), findsOneWidget);
    expect(find.text('Academic Year Start Date'), findsOneWidget);
    expect(find.text('Academic Year End Date'), findsOneWidget);
    expect(find.text('Current Semester Start Date'), findsOneWidget);
    expect(find.text('Current Semester End Date'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('student_name_field')),
      'Test Student',
    );
    await tester.enterText(
      find.byKey(const Key('college_name_field')),
      'City College',
    );
    await tester.enterText(find.byKey(const Key('course_field')), 'B.Tech');
    await tester.enterText(
      find.byKey(const Key('branch_field')),
      'Computer Science',
    );
    final completeButton = find.byKey(const Key('complete_setup_button'));
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await _pumpUntilFound(tester, find.text('Your CollegeOS is ready'));
    expect(find.text('Create your weekly timetable'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go to Home'));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('home_dashboard_ready')),
    );

    expect(find.byKey(const Key('home_dashboard_ready')), findsOneWidget);
    final settings = await database.settingsDao.getSettings();
    final activeSemester = await database.semestersDao.findActive();
    expect(settings.onboardingCompleted, isTrue);
    expect(settings.studentName, 'Test Student');
    expect(settings.collegeName, 'City College');
    expect(activeSemester, isNotNull);
    expect(activeSemester!.isActive, isTrue);
    await _disposeApp(tester);
  });

  testWidgets('completed local setup skips onboarding on launch', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await DriftOnboardingRepository(database).completeSetup(_validSetup);

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

    expect(find.byKey(const Key('home_dashboard_ready')), findsOneWidget);
    expect(find.byKey(const Key('get_started_button')), findsNothing);
    await _disposeApp(tester);
  });
}

final _validSetup = CollegeSetup(
  studentName: 'Test Student',
  collegeName: 'City College of Engineering',
  course: 'B.Tech',
  branch: 'Computer Science',
  semesterNumber: 3,
  academicYear: '2026-2027',
  academicYearStartDate: DateTime(2026, 8, 1),
  academicYearEndDate: DateTime(2027, 4, 30),
  semesterStartDate: DateTime(2026, 8, 1),
  semesterEndDate: DateTime(2026, 12, 20),
  defaultAttendanceTarget: 0.75,
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}
