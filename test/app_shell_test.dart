import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/routing/navigation_shell.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders an edge-to-edge bar with every destination labelled', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.settingsDao.save(
      const AppSettingsCompanion(onboardingCompleted: Value(true)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(tester, find.text('Your day, calmly organized.'));

    // The floating pill dock is gone, replaced by a real bottom navigation bar.
    expect(find.byType(CollegeNavigationBar), findsOneWidget);
    expect(find.byKey(const Key('college-navigation-dock')), findsNothing);
    expect(find.byKey(const Key('navigation_shell_overlay')), findsNothing);
    expect(find.byKey(const Key('floating_navigation_dock')), findsNothing);
    // The bar keeps its glass blur; only the floating dock's overlay and its
    // scale animation are gone.
    expect(find.byType(BackdropFilter), findsOneWidget);

    final navigationScaffold = tester.widget<Scaffold>(
      find.byKey(const Key('navigation_shell_scaffold')),
    );
    expect(navigationScaffold.extendBody, isTrue);
    // The bar is wrapped in the shell's hide-on-scroll animation.
    final bottomBar = navigationScaffold.bottomNavigationBar;
    expect(bottomBar, isNotNull);
    expect(
      find.descendant(
        of: find.byWidget(bottomBar!),
        matching: find.byType(CollegeNavigationBar),
      ),
      findsOneWidget,
    );

    // The bar spans the full width and sits flush with the bottom edge.
    final screen = tester.getSize(find.byType(MaterialApp));
    final barRect = tester.getRect(
      find.byKey(const Key('navigation_bar_surface')),
    );
    // The bar floats just inside the screen edges, above the content.
    expect(barRect.width, screen.width - AppSpacing.xs * 2);
    expect(barRect.bottom, screen.height - AppSpacing.sm);
    expect(barRect.height, greaterThanOrEqualTo(AppLayout.navigationBarHeight));

    // Scrolled content still clears the bar.
    final contentPadding = tester.widget<SliverPadding>(
      find.byKey(const Key('app_scaffold_content_padding')).first,
    );
    expect(
      (contentPadding.padding as EdgeInsets).bottom,
      greaterThanOrEqualTo(AppLayout.navigationBarHeight),
    );

    // Every destination keeps its label, always.
    for (final destination in CollegeNavigationBar.destinations) {
      expect(find.byKey(destination.key), findsOneWidget);
      expect(
        find.byKey(Key('dock_label_${destination.label}')),
        findsOneWidget,
      );
      expect(find.text(destination.label), findsOneWidget);
      final labelRect = tester.getRect(
        find.byKey(Key('dock_label_${destination.label}')),
      );
      expect(labelRect.left, greaterThanOrEqualTo(barRect.left));
      expect(labelRect.right, lessThanOrEqualTo(barRect.right));
    }
    // Settings is no longer a destination.
    expect(find.byKey(const Key('nav_settings')), findsNothing);
    expect(find.text('More'), findsNothing);

    final colors = Theme.of(
      tester.element(find.byType(CollegeNavigationBar)),
    ).colorScheme;
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('dock_icon_Home_true')))
          .color,
      colors.primary,
    );

    final cellWidth = barRect.width / CollegeNavigationBar.destinations.length;
    expect(_indicatorLeft(tester), closeTo(barRect.left + 6, .5));

    // The selected pill is a soft rounded rectangle. A pill radius would clamp
    // to half the slot width, which is narrower than the bar is tall, and paint
    // an ellipse at both ends of the bar.
    final indicatorRect = tester.getRect(
      find.byKey(const Key('navigation_bar_indicator')),
    );
    expect(indicatorRect.height, AppLayout.navigationBarHeight);
    expect(_indicatorRadius(tester), AppRadius.lg);
    expect(
      _indicatorRadius(tester) * 2,
      lessThan(indicatorRect.height),
      reason: 'a pill radius would clamp to half the slot width',
    );
    expect(indicatorRect.left, greaterThan(barRect.left));
    expect(indicatorRect.right, lessThan(barRect.right));

    // Selecting a destination slides the indicator and runs the short page move.
    await tester.tap(find.byKey(const Key('nav_tasks')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final pageOffset = tester
        .widget<SlideTransition>(find.byKey(const Key('dock_page_motion')))
        .position
        .value
        .dx;
    expect(pageOffset, greaterThan(0));
    expect(pageOffset, lessThan(.012));
    await _pumpFrames(tester);
    expect(
      _indicatorLeft(tester),
      closeTo(barRect.left + 3 * cellWidth + 6, .5),
    );
    expect(
      tester
          .widget<SlideTransition>(find.byKey(const Key('dock_page_motion')))
          .position
          .value,
      Offset.zero,
    );
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('dock_icon_Tasks_true')))
          .color,
      colors.primary,
    );
    expect(
      find.text('Assignments and personal work, together.'),
      findsOneWidget,
    );

    // The notes search shortcut belongs to Home and Tasks only, and Scaffold
    // keeps it clear of the bar without any manual offset.
    expect(find.byKey(const Key('search_notes_fab')), findsOneWidget);
    final fabRect = tester.getRect(find.byKey(const Key('search_notes_fab')));
    expect(fabRect.bottom, lessThanOrEqualTo(barRect.top));
    expect(fabRect.right, lessThanOrEqualTo(barRect.right));
    await tester.tap(find.byKey(const Key('nav_timetable')));
    await _pumpFrames(tester);
    expect(find.text('A practical view of your week.'), findsOneWidget);
    expect(
      _indicatorLeft(tester),
      closeTo(barRect.left + 2 * cellWidth + 6, .5),
    );
    expect(find.byKey(const Key('search_notes_fab')), findsNothing);

    // Settings is reachable from every destination header, and the notes
    // shortcut only appears on the two destinations that asked for it.
    for (final destination in CollegeNavigationBar.destinations) {
      await tester.tap(find.byKey(destination.key));
      await _pumpFrames(tester);
      expect(
        find.byKey(const Key('open_settings_button')),
        findsOneWidget,
        reason: 'Settings must be reachable from ${destination.label}',
      );
      final wantsShortcut =
          destination.key == const Key('nav_home') ||
          destination.key == const Key('nav_tasks');
      expect(
        find.byKey(const Key('search_notes_fab')),
        wantsShortcut ? findsOneWidget : findsNothing,
        reason: 'notes shortcut on ${destination.label}',
      );
    }

    // Tapping the destination you are already on returns it to its root.
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('nav_home'))),
    );
    await tester.tap(find.byKey(const Key('nav_attendance')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('open_attendance_planner')));
    await _pumpUntilPath(tester, router, RoutePaths.attendancePlanner);
    await tester.tap(find.byKey(const Key('nav_attendance')));
    await _pumpUntilPath(tester, router, RoutePaths.attendance);

    // It pushes over the shell, which is why it keeps a back button.
    await tester.tap(find.byKey(const Key('open_settings_button')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('settings_college_profile')),
    );
    // Settings has its own AppBar, which supplies the back button automatically.
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('open_settings_button')), findsOneWidget);

    await _disposeApp(tester);
  });

  testWidgets('notes destination browses material and searches the library', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final subjectId = await _seedSemesterWithSubject(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.text('City College of Engineering and Technology'),
    );

    await tester.tap(find.byKey(const Key('nav_notes')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('notes_search_entry')), findsOneWidget);
    expect(find.byKey(ValueKey('notes_subject_$subjectId')), findsOneWidget);
    expect(find.text('Responsive Design Systems'), findsOneWidget);

    // The shortcut from Home lands on the same unscoped search screen.
    await tester.tap(find.byKey(const Key('nav_home')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('search_notes_fab')));
    await _pumpFrames(tester);
    expect(find.text('Search PDFs'), findsOneWidget);
    // Search lives under the Notes branch, so the bar stays available.
    expect(find.byType(CollegeNavigationBar), findsOneWidget);
    final barRect = tester.getRect(
      find.byKey(const Key('navigation_bar_surface')),
    );
    final cellWidth = barRect.width / CollegeNavigationBar.destinations.length;
    expect(
      _indicatorLeft(tester),
      closeTo(barRect.left + 4 * cellWidth + 6, .5),
    );

    // Unscoped search must not trigger per-subject indexing work, and must be
    // leavable without the Android back gesture.
    await tester.tap(find.byKey(const Key('app_back_button')).first);
    await _pumpFrames(tester);
    expect(find.byKey(const Key('notes_search_entry')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _disposeApp(tester);
  });

  testWidgets('navigation bar honors reduced-motion accessibility', (
    tester,
  ) async {
    Widget bar(int selectedIndex) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          bottomNavigationBar: CollegeNavigationBar(
            selectedIndex: selectedIndex,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(bar(0));
    final barRect = tester.getRect(
      find.byKey(const Key('navigation_bar_surface')),
    );
    final slotWidth = barRect.width / CollegeNavigationBar.destinations.length;
    expect(_indicatorLeft(tester), closeTo(barRect.left + 6, .5));

    // With animations disabled the indicator lands on the new slot in a single
    // frame instead of sliding there.
    await tester.pumpWidget(bar(2));
    await tester.pump();
    expect(
      _indicatorLeft(tester),
      closeTo(barRect.left + 2 * slotWidth + 6, .5),
    );

    final iconScales = tester.widgetList<TweenAnimationBuilder<double>>(
      find.descendant(
        of: find.byType(PressScale),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
    );
    expect(iconScales, isNotEmpty);
    expect(
      iconScales.every((tween) => tween.duration == Duration.zero),
      isTrue,
    );
    // Scoped past the bar's own Material wrapper, which animates its text
    // style independently of the destinations.
    final labelStyles = tester.widgetList<AnimatedDefaultTextStyle>(
      find.descendant(
        of: find.byType(PressScale),
        matching: find.byType(AnimatedDefaultTextStyle),
      ),
    );
    expect(labelStyles, hasLength(CollegeNavigationBar.destinations.length));
    expect(
      labelStyles.every((style) => style.duration == Duration.zero),
      isTrue,
    );
    // The glass blur is a static surface, not an animation.
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('labels stay inside the bar at a large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            bottomNavigationBar: CollegeNavigationBar(
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final barRect = tester.getRect(
      find.byKey(const Key('navigation_bar_surface')),
    );
    for (final destination in CollegeNavigationBar.destinations) {
      final label = find.byKey(Key('dock_label_${destination.label}'));
      expect(label, findsOneWidget, reason: '${destination.label} label');
      final labelRect = tester.getRect(label);
      expect(
        labelRect.right,
        lessThanOrEqualTo(barRect.right),
        reason: '${destination.label} label must stay inside the bar',
      );
      expect(
        labelRect.left,
        greaterThanOrEqualTo(barRect.left),
        reason: '${destination.label} label must stay inside the bar',
      );
    }
  });
}

/// Global left edge of the selected-destination pill.
double _indicatorLeft(WidgetTester tester) =>
    tester.getRect(find.byKey(const Key('navigation_bar_indicator'))).left;

/// Corner radius the indicator paints with.
double _indicatorRadius(WidgetTester tester) {
  final decoration =
      tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byKey(const Key('navigation_bar_indicator')),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration
          as BoxDecoration;
  return (decoration.borderRadius! as BorderRadius).topLeft.x;
}

/// Advances past the selection animation and the Scaffold's FAB segue.
///
/// The first frame installs the new target, so the implicit animations only
/// start after it, and the FAB's exit segue additionally resolves on a later
/// frame than the one that completes it.
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(AppDurations.medium);
  await tester.pump(AppDurations.medium);
}

Future<void> _pumpUntilPath(
  WidgetTester tester,
  GoRouter router,
  String path,
) async {
  for (
    var attempt = 0;
    attempt < 30 && router.routeInformationProvider.value.uri.path != path;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(router.routeInformationProvider.value.uri.path, path);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<int> _seedSemesterWithSubject(AppDatabase database) async {
  await DriftOnboardingRepository(database).completeSetup(
    CollegeSetup(
      studentName: 'Alexandria Student',
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
  final semester = (await database.semestersDao.findActive())!;
  return database
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
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}
