import 'dart:io';

import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'repository persists edit/archive and preserves dependent history',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'college_os_subjects_',
      );
      final file = File(p.join(directory.path, 'college_os.sqlite'));
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      var database = AppDatabase.forTesting(NativeDatabase(file));
      await DriftOnboardingRepository(database).completeSetup(_setup);
      final semester = await database.semestersDao.findActive();
      final repository = DriftSubjectRepository(database.subjectsDao);
      final id = await repository.create((
        semesterId: semester!.id,
        name: 'Operating Systems',
        shortCode: 'OS',
        professor: 'Dr Rao',
        room: 'B-204',
        attendanceTarget: 0.8,
        displayColor: 0xFF2563EB,
      ));
      await database.attendanceDao.insertSession(
        AttendanceSessionsCompanion.insert(
          subjectId: id,
          date: DateTime(2026, 8, 12),
          period: 1,
          status: AttendanceStatus.present,
        ),
      );

      final original = (await repository.findById(id))!;
      await repository.update((
        id: original.id,
        semesterId: original.semesterId,
        name: 'Advanced Operating Systems',
        shortCode: original.shortCode,
        professor: original.professor,
        room: original.room,
        attendanceTarget: 0.85,
        displayColor: original.displayColor,
        isArchived: original.isArchived,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      ));
      await repository.setArchived(id, archived: true);
      await database.close();

      database = AppDatabase.forTesting(NativeDatabase(file));
      final reopenedRepository = DriftSubjectRepository(database.subjectsDao);
      final reopened = await reopenedRepository.findById(id);
      expect(reopened!.name, 'Advanced Operating Systems');
      expect(reopened.attendanceTarget, 0.85);
      expect(reopened.isArchived, isTrue);
      expect(
        await database.select(database.attendanceSessions).get(),
        hasLength(1),
      );

      await reopenedRepository.setArchived(id, archived: false);
      expect((await reopenedRepository.findById(id))!.isArchived, isFalse);
      await database.close();
    },
  );

  testWidgets(
    'adds, edits, archives, and restores a subject from Settings',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await DriftOnboardingRepository(database).completeSetup(_setup);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      await _pumpUntilFound(tester, find.text('Your day, calmly organized.'));
      await tester.tap(find.byKey(const Key('open_settings_button')));
      // Settings arrives as a pushed route now, so wait for its list to exist
      // before scrolling it.
      await _pumpUntilFound(tester, find.byKey(const Key('settings_list')));
      await tester.drag(
        find.byKey(const Key('settings_list')),
        const Offset(0, -180),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.byKey(const Key('subjects_tile')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('subjects_tile')));
      await _pumpUntilFound(tester, find.text('No subjects yet'));

      expect(find.text('Add Your First Subject'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add_first_subject_button')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('subject_name_field')),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('subject_target_field')),
            )
            .controller!
            .text,
        '82',
      );

      await tester.enterText(
        find.byKey(const Key('subject_name_field')),
        'Operating Systems',
      );
      await tester.enterText(find.byKey(const Key('subject_code_field')), 'OS');
      await tester.enterText(
        find.byKey(const Key('subject_professor_field')),
        'Dr Rao',
      );
      await tester.enterText(
        find.byKey(const Key('subject_room_field')),
        'B-204',
      );
      final save = find.byKey(const Key('save_subject_button'));
      await _tapSheetButton(tester, save);
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('subject_name_field')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilFound(tester, find.text('Operating Systems'));
      expect(find.text('OS'), findsWidgets);
      expect(find.text('Dr Rao'), findsOneWidget);
      expect(find.text('B-204'), findsOneWidget);
      expect(find.text('82% target'), findsOneWidget);

      await tester.tap(find.text('Operating Systems'));
      await _pumpUntilFound(tester, find.text('Edit Subject'));
      await tester.enterText(
        find.byKey(const Key('subject_name_field')),
        'Advanced Operating Systems',
      );
      await _tapSheetButton(tester, save);
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('subject_name_field')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await _pumpUntilFound(tester, find.text('Advanced Operating Systems'));

      final semester = await database.semestersDao.findActive();
      final repository = DriftSubjectRepository(database.subjectsDao);
      final subjectId =
          (await database.select(database.subjects).getSingle()).id;
      await repository.setArchived(subjectId, archived: true);
      await _pumpUntilAbsent(tester, find.text('Advanced Operating Systems'));
      await tester.tap(find.textContaining('Archived (1)'));
      await _pumpUntilFound(tester, find.text('Advanced Operating Systems'));
      expect(find.text('Archived'), findsOneWidget);

      await repository.setArchived(subjectId, archived: false);
      await _pumpUntilAbsent(tester, find.text('Advanced Operating Systems'));
      await tester.tap(find.textContaining('Active (1)'));
      await _pumpUntilFound(tester, find.text('Advanced Operating Systems'));

      final persisted = await repository.findById(subjectId);
      expect(semester, isNotNull);
      expect(persisted!.name, 'Advanced Operating Systems');
      expect(persisted.isArchived, isFalse);

      await _disposeApp(tester);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

final _setup = CollegeSetup(
  studentName: 'Test Student',
  collegeName: 'City College',
  course: 'B.Tech',
  branch: 'Computer Science',
  semesterNumber: 3,
  academicYear: '2026-2027',
  semesterStartDate: DateTime(2026, 8, 1),
  semesterEndDate: DateTime(2026, 12, 20),
  defaultAttendanceTarget: 0.82,
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (
    var attempt = 0;
    attempt < 60 && finder.evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsNothing);
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _tapSheetButton(WidgetTester tester, Finder button) async {
  tester.testTextInput.hide();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pump();
  await tester.tap(button);
}
