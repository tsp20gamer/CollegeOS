import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The visual contract for this design pass, checked rather than assumed.
///
/// Colour values, surface/border policy, the single-accent rule, the dock's
/// solid surface, and the moved search entry point are all asserted here; the
/// six screens are then rendered in both themes at a compact width and checked
/// for layout failures.
void main() {
  group('design tokens', () {
    test('use the specified palette in both modes', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      // Dark: #0F1115 page, #161920 surfaces.
      expect(dark.scaffoldBackgroundColor, const Color(0xFF0F1115));
      expect(dark.colorScheme.surfaceContainerLow, const Color(0xFF161920));

      // Light: #F8F9FA page, #FFFFFF surfaces.
      expect(light.scaffoldBackgroundColor, const Color(0xFFF8F9FA));
      expect(light.colorScheme.surfaceContainerLow, const Color(0xFFFFFFFF));

      // Electric Cobalt is the single accent in both modes.
      expect(AppColors.cobalt, const Color(0xFF2563EB));
      expect(light.colorScheme.primary, const Color(0xFF2563EB));
      expect(dark.colorScheme.primary, const Color(0xFF2563EB));
      expect(light.colorScheme.secondary, const Color(0xFF2563EB));
      expect(dark.colorScheme.secondary, const Color(0xFF2563EB));
    });

    test('every feature shares the one accent', () {
      final light = AppTheme.light.extension<FeatureColors>()!;
      final dark = AppTheme.dark.extension<FeatureColors>()!;
      for (final feature in AppFeature.values) {
        expect(
          light.of(feature).accent,
          AppColors.cobalt,
          reason: '${feature.name} must use the shared accent',
        );
        expect(
          dark.of(feature).accent,
          AppColors.cobaltLifted,
          reason: '${feature.name} must use the same hue in dark mode',
        );
      }
    });

    test('cards carry no border in dark mode', () {
      final darkCard = AppTheme.dark.cardTheme;
      final shape = darkCard.shape! as RoundedRectangleBorder;
      expect(shape.side, BorderSide.none);

      final lightShape =
          AppTheme.light.cardTheme.shape! as RoundedRectangleBorder;
      expect(
        lightShape.side.color.a,
        lessThanOrEqualTo(.1),
        reason: 'light mode keeps only a hairline above the page',
      );
    });

    test('dividers are barely visible', () {
      expect(AppTheme.dark.dividerTheme.color, AppColors.darkDivider);
      expect(AppTheme.light.dividerTheme.color, AppColors.lightDivider);
      expect(AppColors.darkDivider.a, lessThan(.1));
      expect(AppColors.lightDivider.a, lessThan(.1));
    });

    test('progress rings default to a thin stroke', () {
      const ring = GradientProgressRing(value: .5, child: SizedBox.shrink());
      expect(ring.strokeWidth, lessThanOrEqualTo(5));
    });
  });

  for (final dark in [false, true]) {
    final label = dark ? 'dark' : 'light';

    testWidgets(
      '$label mode renders every screen without layout failure',
      (tester) async {
        tester.view.physicalSize = const Size(320, 820);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        await _seed(database, dark: dark);

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

          // ── Home: compact header, hero, one surface for the day ───────────
          expect(
            find.byKey(const Key('open_notes_search_button')),
            findsOneWidget,
            reason: 'search lives in the Home header',
          );
          expect(find.byKey(const Key('open_settings_button')), findsOneWidget);
          expect(
            find.byKey(const Key('search_notes_fab')),
            findsNothing,
            reason: 'the floating search button is gone',
          );
          expect(
            find.text('City College of Engineering and Technology'),
            findsNothing,
            reason: 'the college banner is gone from Home',
          );
          // Home stays flat: the only blurred surface on screen is the
          // floating dock's own glass. (The AI notes screen frosts its input
          // area, but it is a pushed screen and not part of this flow.)
          expect(
            find.descendant(
              of: find.byKey(const Key('navigation_bar_surface')),
              matching: find.byType(BackdropFilter),
            ),
            findsOneWidget,
          );
          expect(
            find.byType(BackdropFilter),
            findsOneWidget,
            reason: 'the dock is the only blurred surface here',
          );
          _expectNoLayoutFailure(tester, 'Home in $label mode');

          // ── Tasks: chips instead of a segmented control ───────────────────
          await tester.tap(find.byKey(const Key('nav_tasks')));
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('task_filter_all')),
          );
          expect(find.byKey(const Key('task_filter_all')), findsOneWidget);
          expect(find.byType(SegmentedButton<Object?>), findsNothing);
          expect(
            find.byIcon(Icons.radio_button_unchecked_rounded),
            findsNothing,
            reason: 'completion is a rounded square, not a radio glyph',
          );
          expect(
            find.byKey(const Key('open_notes_search_button')),
            findsOneWidget,
            reason: 'Tasks kept its search entry when the FAB was removed',
          );
          _expectNoLayoutFailure(tester, 'Tasks in $label mode');

          // ── Notes: search entry plus material type chips ──────────────────
          await tester.tap(find.byKey(const Key('nav_notes')));
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('notes_material_filter')),
          );
          expect(find.byKey(const Key('notes_search_entry')), findsOneWidget);
          expect(
            find.byKey(const Key('notes_material_filter')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('notes_filter_all')), findsOneWidget);
          expect(
            find.byKey(const Key('open_notes_search_button')),
            findsNothing,
            reason: 'Notes carries the search field itself',
          );
          _expectNoLayoutFailure(tester, 'Notes in $label mode');

          // ── Attendance and Timetable ──────────────────────────────────────
          await tester.tap(find.byKey(const Key('nav_attendance')));
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('attendance_mode_toggle')),
          );
          _expectNoLayoutFailure(tester, 'Attendance in $label mode');

          await tester.tap(find.byKey(const Key('nav_timetable')));
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('timetable_day_1')),
          );
          _expectNoLayoutFailure(tester, 'Timetable in $label mode');

          // ── Settings ──────────────────────────────────────────────────────
          await tester.tap(find.byKey(const Key('nav_home')));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byKey(const Key('open_settings_button')));
          await _pumpUntilFound(
            tester,
            find.byKey(const Key('settings_college_profile')),
          );
          _expectNoLayoutFailure(tester, 'Settings in $label mode');
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));
        }
      },
      timeout: const Timeout(Duration(seconds: 40)),
    );
  }
}

void _expectNoLayoutFailure(WidgetTester tester, String where) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: 'layout failed on $where');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
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
          displayColor: 0xFF2563EB,
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
  await database
      .into(database.collegeTasks)
      .insert(
        CollegeTasksCompanion.insert(
          semesterId: semester.id,
          subjectId: Value(subjectId),
          title: 'Complete the responsive interface accessibility review',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: Value(DateTime(today.year, today.month, today.day)),
        ),
      );
}
