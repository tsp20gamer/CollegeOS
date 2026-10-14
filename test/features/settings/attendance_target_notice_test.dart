import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/settings/domain/attendance_target_mismatch.dart';
import 'package:college_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The state an import or an older build leaves behind: the stored default has
/// moved on to 95% while the subjects still hold the built-in 75%.
void main() {
  group('AttendanceTargetMismatch', () {
    test('stays silent when every subject already uses the default', () {
      final mismatch = AttendanceTargetMismatch(
        defaultTarget: 0.95,
        subjects: [_subject(id: 1, target: 0.95)],
      );

      expect(mismatch.hasMismatch, isFalse);
      expect(mismatch.summary, isEmpty);
      expect(mismatch.actionLabel, 'Use 95%');
    });

    test('names one stray target in the singular', () {
      final mismatch = AttendanceTargetMismatch(
        defaultTarget: 0.95,
        subjects: [_subject(id: 1, target: 0.75)],
      );

      expect(mismatch.count, 1);
      expect(mismatch.summary, '1 subject still compares against 75%');
    });

    test('summarises several stray targets without listing them', () {
      final mismatch = AttendanceTargetMismatch(
        defaultTarget: 0.95,
        subjects: [
          _subject(id: 1, target: 0.75),
          _subject(id: 2, target: 0.8),
          _subject(id: 3, target: 0.75),
        ],
      );

      expect(mismatch.strayTargets, [0.75, 0.8]);
      expect(mismatch.summary, '3 subjects use targets other than 95%');
      expect(mismatch.actionLabel, 'Use 95%');
    });
  });

  testWidgets('Settings offers the stored default where subjects hold another '
      'target, and applies it on request', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _seedSubjects(database, defaultTarget: 0.95, subjectTarget: 0.75);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _openSettings(tester);

    final notice = find.byKey(const Key('attendance_target_mismatch_notice'));
    await _scrollUntilFound(tester, notice);
    expect(
      find.textContaining('2 subjects still compare against 75%'),
      findsOneWidget,
    );

    // Applying names the targets it replaces before anything is written.
    await tester.tap(find.byKey(const Key('apply_default_target_to_subjects')));
    await tester.pumpAndSettle();
    expect(find.text('Apply 95% to every subject'), findsOneWidget);
    expect(
      find.textContaining(
        'Targets you set on individual subjects will be '
        'replaced.',
      ),
      findsOneWidget,
    );
    expect(
      (await database.select(database.subjects).get())
          .map((row) => row.attendanceTarget)
          .toSet(),
      {0.75},
      reason: 'nothing changes before the student confirms',
    );

    await tester.tap(find.byKey(const Key('confirm_apply_default_target')));
    await tester.pumpAndSettle();

    expect(
      (await database.select(database.subjects).get())
          .map((row) => row.attendanceTarget)
          .toSet(),
      {0.95},
      reason: 'every subject now compares against the stored default',
    );
    expect(notice, findsNothing);
    expect(
      find.text('Every subject now compares against 95%.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('nothing is offered while every subject matches the default', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _seedSubjects(database, defaultTarget: 0.95, subjectTarget: 0.95);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _openSettings(tester);
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('default_attendance_target_tile')),
    );

    expect(
      find.byKey(const Key('attendance_target_mismatch_notice')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('the notice holds a compact phone at a large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _seedSubjects(database, defaultTarget: 0.95, subjectTarget: 0.75);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 820),
              textScaler: TextScaler.linear(2),
            ),
            child: const SettingsScreen(),
          ),
        ),
      ),
    );
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('attendance_target_mismatch_notice')),
    );

    expect(
      find.byKey(const Key('apply_default_target_to_subjects')),
      findsOneWidget,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'the notice must not overflow at twice the text size',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Subject _subject({required int id, required double target}) => (
  id: id,
  semesterId: 1,
  name: 'Subject $id',
  shortCode: 'S$id',
  professor: 'Dr Rao',
  room: 'A-101',
  attendanceTarget: target,
  displayColor: 0xFF2563EB,
  isArchived: false,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

Future<void> _seedSubjects(
  AppDatabase database, {
  required double defaultTarget,
  required double subjectTarget,
}) async {
  await DriftOnboardingRepository(database).completeSetup(
    CollegeSetup(
      studentName: 'Test Student',
      collegeName: 'City College',
      course: 'B.Tech',
      branch: 'Computer Science',
      semesterNumber: 1,
      academicYear: '2026-2027',
      semesterStartDate: DateTime(2026, 8, 1),
      semesterEndDate: DateTime(2026, 12, 20),
      defaultAttendanceTarget: 0.75,
    ),
  );
  final semester = (await database.semestersDao.findActive())!;
  final subjects = DriftSubjectRepository(database.subjectsDao);
  for (final name in ['Operating Systems', 'Digital Logic']) {
    await subjects.create((
      semesterId: semester.id,
      name: name,
      shortCode: name.split(' ').first,
      professor: 'Dr Rao',
      room: 'A-101',
      attendanceTarget: subjectTarget,
      displayColor: 0xFF2563EB,
    ));
  }
  // Writes the default the way an import or an older build leaves it: the
  // stored setting moves on without re-targeting the subjects that exist, which
  // is exactly the gap the repair action in Settings closes.
  await database.settingsDao.save(
    AppSettingsCompanion(defaultAttendanceTarget: Value(defaultTarget)),
  );
}

Future<void> _openSettings(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byKey(const Key('open_settings_button')));
  await tester.tap(find.byKey(const Key('open_settings_button')));
  await tester.pumpAndSettle();
}

/// Scrolls the Settings list until [finder] exists, then reveals it.
Future<void> _scrollUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 25 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(
      find.byKey(const Key('settings_list')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
