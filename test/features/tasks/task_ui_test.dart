import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:college_os/features/tasks/domain/task_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'creates edits completes uncompletes and deletes an assignment',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1300);
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
      final subjectId = await DriftSubjectRepository(database.subjectsDao)
          .create((
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
      await tester.tap(find.byKey(const Key('nav_tasks')));
      await _pumpUntilFound(tester, find.text('No active tasks'));
      await tester.tap(find.byKey(const Key('add_task_button')));
      await _pumpUntilFound(tester, find.byKey(const Key('task_title_field')));
      await tester.enterText(
        find.byKey(const Key('task_title_field')),
        'Systems assignment',
      );
      tester
          .widget<DropdownButtonFormField<CollegeTaskType>>(
            find.byKey(const Key('task_type_field')),
          )
          .onChanged!(CollegeTaskType.assignment);
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<int?>>(
            find.byKey(const Key('task_subject_field')),
          )
          .onChanged!(subjectId);
      tester
          .widget<SegmentedButton<TaskPriority>>(
            find.byKey(const Key('task_priority_field')),
          )
          .onSelectionChanged!({TaskPriority.high});
      await tester.pump();
      await _saveSheet(tester);
      await _pumpUntilAbsent(tester, find.byKey(const Key('save_task_button')));
      await _pumpUntilFound(tester, find.text('Systems assignment'));
      expect(find.text('Assignment • OS'), findsOneWidget);
      final created = await database.select(database.collegeTasks).getSingle();
      expect(created.type, CollegeTaskType.assignment);
      expect(created.subjectId, subjectId);
      expect(created.priority, TaskPriority.high);

      await tester.tap(find.byKey(Key('task_toggle_${created.id}')));
      await _pumpUntilAbsent(tester, find.text('Systems assignment'));
      final completed = await database
          .select(database.collegeTasks)
          .getSingle();
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);

      tester
          .widget<SegmentedButton<TaskFilter>>(
            find.byKey(const Key('task_filter')),
          )
          .onSelectionChanged!({TaskFilter.completed});
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Systems assignment'));
      await tester.tap(find.byKey(Key('task_toggle_${created.id}')));
      await _pumpUntilAbsent(tester, find.text('Systems assignment'));
      expect(
        (await database.select(database.collegeTasks).getSingle()).isCompleted,
        isFalse,
      );

      tester
          .widget<SegmentedButton<TaskFilter>>(
            find.byKey(const Key('task_filter')),
          )
          .onSelectionChanged!({TaskFilter.all});
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Systems assignment'));
      await tester.tap(find.text('Systems assignment'));
      await _pumpUntilFound(tester, find.byKey(const Key('task_title_field')));
      await tester.enterText(
        find.byKey(const Key('task_title_field')),
        'Updated systems assignment',
      );
      await _saveSheet(tester);
      await _pumpUntilAbsent(tester, find.byKey(const Key('save_task_button')));
      await _pumpUntilFound(tester, find.text('Updated systems assignment'));

      await tester.tap(find.byTooltip('Task actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete task?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await _pumpUntilFound(tester, find.text('No active tasks'));
      expect(await database.select(database.collegeTasks).get(), isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}

Future<void> _saveSheet(WidgetTester tester) async {
  final button = find.byKey(const Key('save_task_button'));
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
