import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
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
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

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
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            // Reminders are projected through the coordinator; the platform is
            // faked so the test stays hermetic and nothing touches Android.
            notificationPlatformProvider.overrideWithValue(
              _NoopNotificationPlatform(),
            ),
          ],
          child: const CollegeOsApp(enableStartupAnimation: false),
        ),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('home_dashboard_ready')),
      );
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
      // Every class carries a reminder option next to its schedule, and a new
      // class starts from the student's class-notifier reminder time.
      await tester.ensureVisible(
        find.byKey(const Key('timetable_reminder_field')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('10 min before'),
        findsOneWidget,
        reason: 'a new class inherits the class notifier time',
      );
      await tester.tap(find.byKey(const Key('timetable_reminder_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15 min before').last);
      await tester.pumpAndSettle();
      expect(find.text('15 min before a 9:00 AM class'), findsOneWidget);
      await _saveSheet(tester);
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      expect(
        (await database.select(database.timetableEntries).get())
            .single
            .reminderMinutesBefore,
        15,
      );
      await _pumpUntilFound(tester, find.text('Operating Systems'));
      // The saved reminder is visible on the class row itself.
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
      expect(find.text('15 min before'), findsOneWidget);
      // The bright vertical accent bars are gone: the row reads through its
      // time, subject and details instead.
      expect(
        find.byKey(const Key('timetable_subject_accent_1')),
        findsNothing,
        reason: 'class rows no longer carry a colour rail',
      );
      // The selector holds exactly one pill, it is cobalt and borderless, and
      // no day paints a background of its own.
      AnimatedAlign dayPill() => tester.widget<AnimatedAlign>(
        find.byKey(const Key('timetable_day_pill')),
      );
      Finder pillBox() => find.descendant(
        of: find.byKey(const Key('timetable_day_pill')),
        matching: find.byType(FractionallySizedBox),
      );
      BoxDecoration dayPillDecoration() =>
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byKey(const Key('timetable_day_pill')),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(find.byKey(const Key('timetable_day_pill')), findsOneWidget);
      expect(dayPill().duration, AppDurations.dayPillGlide);
      expect(
        dayPill().alignment,
        const Alignment(-1, 0),
        reason: 'Monday is the first slot',
      );
      expect(dayPillDecoration().color, const Color(0xFF2563EB));
      expect(
        dayPillDecoration().borderRadius,
        BorderRadius.circular(AppRadius.pill),
      );
      expect(dayPillDecoration().border, isNull);
      expect(dayPillDecoration().boxShadow, isNull);
      expect(
        find.descendant(
          of: find.byKey(const Key('timetable_day_2')),
          matching: find.byType(AnimatedContainer),
        ),
        findsNothing,
        reason: 'only the strip owns a pill',
      );

      // Choosing another day glides the pill: it is between the two slots
      // mid-flight and lands centred on the chosen day.
      final pillStart = tester.getCenter(pillBox());
      final target = tester.getCenter(find.byKey(const Key('timetable_day_4')));
      await tester.tap(find.byKey(const Key('timetable_day_4')));
      // The first pump rebuilds with the new target and starts the glide; the
      // second advances into it so the pill is measured in motion.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final pillDuring = tester.getCenter(pillBox());
      await tester.pumpAndSettle();
      final pillEnd = tester.getCenter(pillBox());
      expect(pillDuring.dx, greaterThan(pillStart.dx));
      expect(pillDuring.dx, lessThan(pillEnd.dx));
      expect((pillEnd.dx - target.dx).abs(), lessThan(1));
      await tester.tap(find.byKey(const Key('timetable_day_1')));
      await tester.pumpAndSettle();
      expect(
        dayPill().alignment,
        const Alignment(-1, 0),
        reason: 'the pill follows the selection back',
      );
      // The pills sit in the mockup's rounded bar: one full-width strip at the
      // surface-container-high step, radius 20, with no border or glow.
      final barFinder = find
          .ancestor(
            of: find.byKey(const Key('timetable_day_1')),
            matching: find.byType(Container),
          )
          .first;
      final bar = tester.widget<Container>(barFinder);
      expect(bar.decoration, isA<BoxDecoration>());
      final barDecoration = bar.decoration! as BoxDecoration;
      final darkTheme = Theme.of(tester.element(barFinder));
      expect(darkTheme.brightness, Brightness.dark);
      expect(
        barDecoration.color,
        darkTheme.colorScheme.surfaceContainerHigh,
        reason: 'the bar reads one surface step above the canvas',
      );
      expect(
        barDecoration.color,
        isNot(darkTheme.scaffoldBackgroundColor),
        reason: 'the strip must stay one step above the dark canvas',
      );
      expect(barDecoration.borderRadius, BorderRadius.circular(20));
      expect(barDecoration.border, isNull);
      expect(barDecoration.boxShadow, isNull);

      // The bar keeps its shape in light mode: the strip lifts to the light
      // surface step, still distinct from the page, and the pill stays cobalt.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      final lightBarFinder = find
          .ancestor(
            of: find.byKey(const Key('timetable_day_1')),
            matching: find.byType(Container),
          )
          .first;
      final lightTheme = Theme.of(tester.element(lightBarFinder));
      expect(lightTheme.brightness, Brightness.light);
      final lightBarDecoration =
          tester.widget<Container>(lightBarFinder).decoration! as BoxDecoration;
      expect(
        lightBarDecoration.color,
        AppTheme.light.colorScheme.surfaceContainerHigh,
      );
      expect(
        lightBarDecoration.color,
        isNot(lightTheme.scaffoldBackgroundColor),
        reason: 'the strip must stay one step above the light canvas',
      );
      expect(dayPillDecoration().color, AppColors.cobalt);
      expect(dayPillDecoration().boxShadow, isNull);
      expect(dayPillDecoration().border, isNull);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(barFinder)).brightness, Brightness.dark);

      await _openAddForm(tester);
      // The custom setter accepts any lead time, not just the presets.
      await tester.ensureVisible(
        find.byKey(const Key('timetable_reminder_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timetable_reminder_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom\u2026').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('timetable_reminder_preview')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('timetable_reminder_minutes_field')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('45').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('timetable_reminder_preview')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('timetable_reminder_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('45 min before a 9:00 AM class'), findsOneWidget);
      await _saveSheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('Schedule overlap'), findsOneWidget);
      expect(find.text('Save anyway'), findsOneWidget);
      await tester.tap(find.text('Save anyway'));
      await _pumpUntilAbsent(
        tester,
        find.byKey(const Key('save_timetable_entry_button')),
      );
      final savedEntries = await database
          .select(database.timetableEntries)
          .get();
      expect(savedEntries, hasLength(2));
      expect(
        savedEntries.map((row) => row.reminderMinutesBefore).toList(),
        [15, 45],
        reason: 'both classes keep the reminder they were saved with',
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
      // Let the day transition finish, so only Tuesday's list is on screen.
      await tester.pumpAndSettle();
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

final class _NoopNotificationPlatform implements NotificationPlatform {
  @override
  Future<String?> initialize(void Function(String payload) onTap) async => null;

  @override
  Future<bool> notificationsEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> showTestNotification() async {}

  @override
  Future<void> schedule(CollegeOsNotification notification) async {}

  @override
  Future<void> cancel(NotificationEntityType type, int entityId) async {}

  @override
  Future<List<PendingCollegeOsNotification>> pending() async => const [];
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
