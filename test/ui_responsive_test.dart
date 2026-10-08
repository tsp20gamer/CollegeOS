import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0, 412.0, 430.0]) {
    testWidgets(
      'major screens fit a ${width.toInt()}dp phone',
      (tester) async {
        tester.view.physicalSize = Size(width, 820);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        await _seed(database, dark: width == 390);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(database),
              appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
            ],
            child: const CollegeOsApp(enableStartupAnimation: false),
          ),
        );

        try {
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('home_dashboard_ready')),
          );
          _expectNoLayoutFailure(tester, 'Home at ${width.toInt()}dp');
          for (final destination in [
            'Attendance',
            'Timetable',
            'Tasks',
            'Notes',
          ]) {
            await tester.tap(
              find.byKey(Key('nav_${destination.toLowerCase()}')),
            );
            await tester.pump(const Duration(milliseconds: 500));
            _expectNoLayoutFailure(
              tester,
              '$destination at ${width.toInt()}dp',
            );
            if (destination == 'Attendance') {
              expect(
                find.byKey(const Key('attendance_mode_toggle')),
                findsOneWidget,
              );
              _expectNoLayoutFailure(
                tester,
                'Attendance calendar at ${width.toInt()}dp',
              );
            }
          }
          // Settings left the bar, so it is reached from the tab headers and
          // arrives as a pushed route rather than a branch switch.
          await tester.tap(find.byKey(const Key('nav_home')));
          await _settle(tester);
          await tester.tap(find.byKey(const Key('open_settings_button')));
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('settings_college_profile')),
          );
          _expectNoLayoutFailure(tester, 'Settings at ${width.toInt()}dp');
          await _pumpUntilFound(tester, find.byKey(const Key('subjects_tile')));
          await tester.drag(
            find.byKey(const Key('settings_list')),
            const Offset(0, -180),
          );
          await _settle(tester);
          for (final route in [
            (const Key('subjects_tile'), 'Subjects'),
            (const Key('exams_marks_tile'), 'Exams and marks'),
          ]) {
            await tester.ensureVisible(find.byKey(route.$1));
            await tester.tap(find.byKey(route.$1));
            await _settle(tester);
            _expectNoLayoutFailure(tester, '${route.$2} at ${width.toInt()}dp');
            await tester.binding.handlePopRoute();
            await _settle(tester);
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));
        }
      },
      timeout: const Timeout(Duration(seconds: 40)),
    );
  }

  testWidgets(
    'subject form remains scrollable above a compact keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await _seed(database, dark: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      try {
        await _pumpUntilFound(
          tester,
          find.byKey(const Key('home_dashboard_ready')),
        );
        GoRouter.of(
          tester.element(find.byKey(const Key('nav_home'))),
        ).go(RoutePaths.subjects);
        await _pumpUntilFound(
          tester,
          find.byKey(const Key('add_subject_button')),
        );
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -180),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byKey(const Key('add_subject_button')));
        await _pumpUntilFound(
          tester,
          find.byKey(const Key('subject_name_field')),
        );

        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.byKey(const Key('subject_name_field')),
          'Advanced Interdisciplinary Computational Design Systems',
        );
        await tester.ensureVisible(
          find.byKey(const Key('subject_professor_field')),
        );
        await tester.enterText(
          find.byKey(const Key('subject_professor_field')),
          'Professor Alexandria Catherine Johnson-Srinivasan',
        );
        await tester.ensureVisible(
          find.byKey(const Key('save_subject_button')),
        );
        await tester.pump();

        _expectNoLayoutFailure(tester, 'Subject form with compact keyboard');
        expect(find.byKey(const Key('save_subject_button')), findsOneWidget);
      } finally {
        tester.view.resetViewInsets();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
      }
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}

/// Advances past a route transition without waiting on an indeterminate
/// animation, which [WidgetTester.pumpAndSettle] would never settle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void _expectNoLayoutFailure(WidgetTester tester, String screen) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: screen);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> _seed(AppDatabase database, {required bool dark}) async {
  await DriftOnboardingRepository(database).completeSetup(
    CollegeSetup(
      studentName: 'Alexandria Student With A Long Name',
      collegeName: 'City College of Engineering and Technology',
      course: 'Bachelor of Technology',
      branch: 'Computer Science and Engineering',
      semesterNumber: 5,
      academicYear: '2026-2027',
      semesterStartDate: DateTime(2026, 8, 1),
      semesterEndDate: DateTime(2026, 12, 20),
      defaultAttendanceTarget: 0.75,
    ),
  );
  if (dark) {
    await database.settingsDao.save(
      const AppSettingsCompanion(themeMode: Value(CollegeThemeMode.dark)),
    );
  }
  final semester = (await database.semestersDao.findActive())!;
  final subjectId = await database
      .into(database.subjects)
      .insert(
        SubjectsCompanion.insert(
          semesterId: semester.id,
          name: 'Responsive Design Systems',
          shortCode: const Value('RDS'),
          professor: const Value('Professor Alexandria Johnson'),
          room: const Value('Innovation Laboratory 204'),
          attendanceTarget: const Value(0.75),
          displayColor: 0xFF4758D6,
        ),
      );
  final today = DateTime.now();
  await database
      .into(database.timetableEntries)
      .insert(
        TimetableEntriesCompanion.insert(
          semesterId: semester.id,
          subjectId: subjectId,
          weekday: today.weekday == DateTime.sunday
              ? DateTime.monday
              : today.weekday,
          startTime: 9 * 60,
          endTime: 10 * 60 + 30,
          room: const Value('Innovation Laboratory 204'),
        ),
      );
  for (var index = 0; index < 8; index++) {
    await database
        .into(database.attendanceSessions)
        .insert(
          AttendanceSessionsCompanion.insert(
            subjectId: subjectId,
            date: today.subtract(Duration(days: index + 1)),
            period: index + 1,
            status: index < 5
                ? AttendanceStatus.present
                : AttendanceStatus.absent,
          ),
        );
  }
  await database
      .into(database.collegeTasks)
      .insert(
        CollegeTasksCompanion.insert(
          semesterId: semester.id,
          subjectId: Value(subjectId),
          title: 'Complete the responsive interface accessibility review',
          description: const Value(
            'Check compact phones, long labels, contrast, and touch targets.',
          ),
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: Value(DateTime(today.year, today.month, today.day)),
        ),
      );
}
