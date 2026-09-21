import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edits college information without changing semester setup', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await DriftOnboardingRepository(database).completeSetup(
      CollegeSetup(
        studentName: 'Old Name',
        collegeName: 'Old College',
        course: 'B.Tech',
        branch: 'Computer Science',
        semesterNumber: 2,
        academicYear: '2026-2027',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 20),
        defaultAttendanceTarget: 0.75,
      ),
    );
    final semesterBefore = await database.semestersDao.findActive();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
        ],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(tester, find.text('Your day, calmly organized.'));

    await tester.tap(find.byKey(const Key('nav_settings')));
    await tester.pump(const Duration(milliseconds: 500));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('college_information_tile')),
    );
    await tester.tap(find.byKey(const Key('college_information_tile')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('edit_college_name_field')),
    );

    await tester.enterText(
      find.byKey(const Key('edit_student_name_field')),
      'New Name',
    );
    await tester.enterText(
      find.byKey(const Key('edit_college_name_field')),
      'New College',
    );
    final saveButton = find.byKey(const Key('save_college_information_button'));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(saveButton);
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('college_information_tile')),
    );
    await tester.pumpAndSettle();

    final settings = await database.settingsDao.getSettings();
    final semesterAfter = await database.semestersDao.findActive();
    expect(settings.studentName, 'New Name');
    expect(settings.collegeName, 'New College');
    expect(settings.onboardingCompleted, isTrue);
    expect(semesterAfter!.id, semesterBefore!.id);
    expect(semesterAfter.semesterNumber, 2);

    final appInfo = find.byKey(const Key('app_info_tile'));
    await tester.drag(
      find.byKey(const Key('settings_list')),
      const Offset(0, -650),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(appInfo);
    await tester.pumpAndSettle();
    await tester.tap(appInfo);
    await tester.pumpAndSettle();
    expect(find.text('Version 1.0.0+1'), findsOneWidget);
    expect(find.text('Made By Tsp'), findsWidgets);
    expect(find.byKey(const Key('made_by_tsp')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
