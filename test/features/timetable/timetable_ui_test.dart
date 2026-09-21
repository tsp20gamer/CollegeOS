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
    'adds overlapping classes with confirmation and supports duplicate edit delete',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
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
      await tester.tap(find.byKey(const Key('nav_timetable')));
      await _pumpUntilFound(tester, find.byKey(const Key('timetable_day_1')));
      await tester.tap(find.byKey(const Key('timetable_day_1')));
      await tester.pump();

      await _openAddForm(tester);
      expect(find.text('Operating Systems'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('timetable_room_field')),
            )
            .controller!
            .text,
        'A-101',
      );
      await _saveSheet(tester);
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      expect(
        await database.select(database.timetableEntries).get(),
        hasLength(1),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('timetable_subject_accent_1')),
      );
      final accent = tester.widget<Container>(
        find.byKey(const Key('timetable_subject_accent_1')),
      );
      final accentDecoration = accent.decoration! as BoxDecoration;
      expect(accentDecoration.color, const Color(0xFF2563EB));
      expect(accentDecoration.boxShadow, hasLength(2));

      await _openAddForm(tester);
      await _saveSheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('Schedule overlap'), findsOneWidget);
      expect(find.text('Save anyway'), findsOneWidget);
      await tester.tap(find.text('Save anyway'));
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      expect(
        await database.select(database.timetableEntries).get(),
        hasLength(2),
      );

      await tester.ensureVisible(find.byTooltip('Class actions').first);
      await tester.tap(find.byTooltip('Class actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate to another day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tuesday'));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      await _saveSheet(tester);
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      final afterDuplicate = await database
          .select(database.timetableEntries)
          .get();
      expect(afterDuplicate, hasLength(3));
      expect(
        afterDuplicate.where((entry) => entry.weekday == DateTime.tuesday),
        hasLength(1),
      );

      await tester.tap(find.byKey(const Key('timetable_day_2')));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntilFound(
        tester,
        find.widgetWithText(Card, 'Operating Systems'),
      );
      await tester.tap(find.widgetWithText(Card, 'Operating Systems'));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('timetable_room_field')),
      );
      await tester.enterText(
        find.byKey(const Key('timetable_room_field')),
        'B-204',
      );
      await _saveSheet(tester);
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      expect(
        (await database.select(database.timetableEntries).get())
            .singleWhere(
              (entry) =>
                  entry.weekday == DateTime.tuesday && entry.room == 'B-204',
            )
            .room,
        'B-204',
      );

      await tester.ensureVisible(find.byTooltip('Class actions'));
      await tester.tap(find.byTooltip('Class actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete class'));
      await tester.pumpAndSettle();
      expect(find.text('Delete class?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await _waitForEntryCount(database, 3);
      expect(
        await database.select(database.timetableEntries).get(),
        hasLength(3),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}

Future<void> _openAddForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('add_timetable_entry_button')));
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('save_timetable_entry_button')),
  );
}

Future<void> _saveSheet(WidgetTester tester) async {
  final button = find.byKey(const Key('save_timetable_entry_button'));
  tester.testTextInput.hide();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.scrollUntilVisible(
    button,
    250,
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

Future<void> _waitForEntryCount(AppDatabase database, int count) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if ((await database.select(database.timetableEntries).get()).length ==
        count) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}
