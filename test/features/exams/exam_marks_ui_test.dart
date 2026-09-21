import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'manages exams and subject marks from Settings',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
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
      final semester = await database.semestersDao.findActive();
      await DriftSubjectRepository(database.subjectsDao).create((
        semesterId: semester!.id,
        name: 'Operating Systems',
        shortCode: 'OS',
        professor: 'Dr Rao',
        room: 'A-101',
        attendanceTarget: 0.75,
        displayColor: 0xFF2563EB,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      await _pumpUntilFound(tester, find.text('Your day, calmly organized.'));
      await tester.tap(find.byKey(const Key('nav_settings')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.byKey(const Key('exams_marks_tile')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('exams_marks_tile')));
      await _pumpUntilFound(tester, find.text('No exams yet'));

      await tester.tap(find.widgetWithText(FilledButton, 'Add exam'));
      await _pumpUntilFound(tester, find.byKey(const Key('exam_name_field')));
      await tester.enterText(
        find.byKey(const Key('exam_name_field')),
        'Midterm',
      );
      await tester.enterText(
        find.byKey(const Key('exam_type_field')),
        'Written',
      );
      await tester.enterText(
        find.byKey(const Key('exam_room_field')),
        'Hall A',
      );
      await tester.enterText(
        find.byKey(const Key('exam_syllabus_field')),
        'Units 1–3',
      );
      await tester.enterText(
        find.byKey(const Key('exam_max_marks_field')),
        '100',
      );
      await tester.enterText(
        find.byKey(const Key('exam_obtained_marks_field')),
        '82',
      );
      await _saveSheet(tester, const Key('save_exam_button'));
      await _pumpUntilAbsent(tester, find.byKey(const Key('save_exam_button')));
      await _pumpUntilFound(tester, find.text('Midterm'));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('82 / 100 marks'), findsOneWidget);

      await tester.tap(find.text('Midterm'));
      await _pumpUntilFound(tester, find.byKey(const Key('exam_name_field')));
      await tester.enterText(
        find.byKey(const Key('exam_name_field')),
        'Updated Midterm',
      );
      await _saveSheet(tester, const Key('save_exam_button'));
      await _pumpUntilAbsent(tester, find.byKey(const Key('save_exam_button')));
      await _pumpUntilFound(tester, find.text('Updated Midterm'));

      await tester.tap(find.text('Performance'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('SGPA/CGPA setup can be configured later.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(Card, 'Operating Systems'));
      await _pumpUntilFound(tester, find.text('Subject performance'));
      expect(find.text('No marks recorded'), findsWidgets);
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Record marks'));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('mark_obtained_field')),
      );
      await tester.pumpAndSettle();
      final categoryField = find.byKey(const Key('mark_category_field'));
      await tester.scrollUntilVisible(
        categoryField,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(categoryField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lab').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('mark_obtained_field')),
        '18',
      );
      await tester.enterText(find.byKey(const Key('mark_maximum_field')), '20');
      await tester.enterText(
        find.byKey(const Key('mark_note_field')),
        'Practical',
      );
      await _saveSheet(tester, const Key('save_mark_button'));
      await _pumpUntilAbsent(tester, find.byKey(const Key('save_mark_button')));
      await _pumpUntilFound(tester, find.text('Lab'));
      expect(find.text('90.0%'), findsOneWidget);
      expect(find.textContaining('18 / 20'), findsWidgets);

      await tester.tap(find.text('Lab'));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('mark_obtained_field')),
      );
      await tester.enterText(
        find.byKey(const Key('mark_obtained_field')),
        '19',
      );
      await _saveSheet(tester, const Key('save_mark_button'));
      await _pumpUntilAbsent(tester, find.byKey(const Key('save_mark_button')));
      await _pumpUntilFound(tester, find.text('95.0%'));

      await tester.tap(find.byTooltip('Marks actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete marks?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await _pumpUntilFound(tester, find.text('No marks recorded'));
      expect(await database.select(database.marks).get(), isEmpty);

      Navigator.of(tester.element(find.text('Subject performance'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exams'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Exam actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete exam?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await _pumpUntilFound(tester, find.text('No exams yet'));
      expect(await database.select(database.exams).get(), isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

Future<void> _saveSheet(WidgetTester tester, Key key) async {
  final button = find.byKey(key);
  tester.testTextInput.hide();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(button);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (
    var attempt = 0;
    attempt < 80 && finder.evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsNothing);
}
