import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/routing/navigation_shell.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/core/theme/color_tokens.dart';
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
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('home_dashboard_ready')),
    );

    // The dock is one translucent glass strip that floats over the page.
    expect(find.byType(CollegeNavigationBar), findsOneWidget);
    expect(find.byKey(const Key('college-navigation-dock')), findsNothing);
    expect(find.byKey(const Key('navigation_shell_overlay')), findsNothing);
    expect(find.byKey(const Key('floating_navigation_dock')), findsNothing);
    final dockSurface = find.byKey(const Key('navigation_bar_surface'));
    // The dock owns the blur, and it sits inside the dock's own clip so the
    // rounded edge is not blurred away.
    expect(
      find.descendant(of: dockSurface, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(
      find.byType(BackdropFilter),
      findsOneWidget,
      reason: 'the shell chrome carries exactly one blurred surface: the dock',
    );
    final barDecoration =
        tester.widget<DecoratedBox>(dockSurface).decoration as BoxDecoration;
    expect(
      barDecoration.color,
      Theme.of(tester.element(dockSurface)).brightness == Brightness.dark
          ? const Color(0x14FFFFFF)
          : const Color(0xBFFFFFFF),
      reason: 'the dock is translucent, not an opaque bar',
    );
    expect(barDecoration.gradient, isNull);
    expect(barDecoration.border, isNull);
    expect(barDecoration.boxShadow, hasLength(1));

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

    // The dock floats clear of every screen edge instead of sitting flush.
    final screen = tester.getSize(find.byType(MaterialApp));
    final barRect = tester.getRect(dockSurface);
    expect(barRect.left, AppSpacing.md);
    expect(barRect.right, screen.width - AppSpacing.md);
    expect(barRect.bottom, screen.height - AppSpacing.sm);
    expect(barRect.top, greaterThan(0));
    expect(barRect.height, greaterThanOrEqualTo(AppLayout.navigationBarHeight));
    // One smooth floating surface, not a pill clamped by the dock's height.
    expect(_dockRadius(tester), AppRadius.xl);
    expect(_dockRadius(tester) * 2, lessThan(barRect.height));

    // Scrolled content clears the dock *and* the gap it floats above, so the
    // last row of a screen is never left behind the glass.
    final contentPadding = tester.widget<SliverPadding>(
      find.byKey(const Key('app_scaffold_content_padding')).first,
    );
    final dockFootprint = barRect.height + (screen.height - barRect.bottom);
    expect(
      (contentPadding.padding as EdgeInsets).bottom,
      greaterThanOrEqualTo(dockFootprint + AppSpacing.xxs),
      reason: 'content must clear the dock plus the gap below it',
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

    // Selection is minimal: a cobalt icon and label with a tiny cobalt dot
    // underneath. No capsule is painted behind the selected destination.
    expect(find.byKey(const Key('navigation_bar_indicator')), findsNothing);
    final homeLabel = tester.getRect(find.byKey(const Key('dock_label_Home')));
    final homeDot = tester.getRect(find.byKey(const Key('dock_dot_Home')));
    expect(homeDot.width, closeTo(4, .5));
    expect(
      homeDot.center.dx,
      closeTo(homeLabel.center.dx, .5),
      reason: 'the dot sits under its own label',
    );
    expect(homeDot.top, greaterThanOrEqualTo(homeLabel.bottom));
    expect(homeDot.center.dy, lessThan(barRect.bottom));
    expect(_activeDotScale(tester, 'Home'), 1.0);
    expect(_activeDotOpacity(tester, 'Home'), 1.0);
    for (final destination in CollegeNavigationBar.destinations) {
      if (destination.label == 'Home') {
        continue;
      }
      expect(
        _activeDotScale(tester, destination.label),
        .2,
        reason: '${destination.label} is not the selected destination',
      );
      expect(_activeDotOpacity(tester, destination.label), 0.0);
      expect(
        tester
            .widget<Icon>(
              find.byKey(ValueKey('dock_icon_${destination.label}_false')),
            )
            .color,
        colors.onSurfaceVariant,
        reason: 'inactive icons stay muted',
      );
    }

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
    // Mid-flight the tapped icon is popped and lifted, while every other
    // destination stays exactly where it was.
    expect(_popScale(tester, 'Tasks'), greaterThan(1.0));
    expect(_iconLift(tester, 'Tasks'), lessThan(0));
    expect(_popScale(tester, 'Home'), 1.0);
    expect(_iconLift(tester, 'Home'), 0.0);
    await _pumpFrames(tester);
    expect(_popScale(tester, 'Tasks'), 1.0);
    expect(_iconLift(tester, 'Tasks'), 0.0);
    expect(_iconRestScale(tester, 'Tasks'), AppMotion.dockSelectedIconScale);
    expect(_activeDotScale(tester, 'Tasks'), 1.0);
    expect(_activeDotOpacity(tester, 'Tasks'), 1.0);
    expect(_activeDotScale(tester, 'Home'), .2);
    expect(_activeDotOpacity(tester, 'Home'), 0.0);
    expect(
      tester
          .widget<SlideTransition>(find.byKey(const Key('dock_page_motion')))
          .position
          .value,
      Offset.zero,
    );
    // Every destination resolves to the one Electric Cobalt accent.
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('dock_icon_Tasks_true')))
          .color,
      Theme.of(
        tester.element(find.byKey(const Key('nav_tasks'))),
      ).extension<FeatureColors>()!.tasks.accent,
    );
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('nav_tasks'))),
      ).extension<FeatureColors>()!.tasks.accent,
      Theme.of(
        tester.element(find.byKey(const Key('nav_tasks'))),
      ).extension<FeatureColors>()!.attendance.accent,
      reason: 'features share one accent instead of owning colours',
    );
    expect(
      find.text('Assignments and personal work, together.'),
      findsOneWidget,
    );

    // The notes search shortcut is a header action on Home and Tasks, sitting
    // immediately before Settings and clear of the dock and of each other.
    expect(find.byKey(const Key('open_notes_search_button')), findsOneWidget);
    expect(find.byKey(const Key('search_notes_fab')), findsNothing);
    final searchRect = tester.getRect(
      find.byKey(const Key('open_notes_search_button')),
    );
    final settingsRect = tester.getRect(
      find.byKey(const Key('open_settings_button')),
    );
    expect(
      searchRect.overlaps(settingsRect),
      isFalse,
      reason: 'the search button sits beside Settings, not on top of it',
    );
    expect(
      searchRect.right,
      lessThanOrEqualTo(settingsRect.left),
      reason: 'the header reads [context] [Search] [Settings]',
    );
    expect(
      searchRect.bottom,
      lessThanOrEqualTo(barRect.top),
      reason: 'no header control reaches the dock',
    );
    await tester.tap(find.byKey(const Key('nav_timetable')));
    await _pumpFrames(tester);
    expect(find.text('A practical view of your week.'), findsOneWidget);
    expect(_activeDotScale(tester, 'Timetable'), 1.0);
    expect(_activeDotOpacity(tester, 'Timetable'), 1.0);
    expect(_activeDotScale(tester, 'Tasks'), .2);
    expect(find.byKey(const Key('open_notes_search_button')), findsNothing);

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
        find.byKey(const Key('open_notes_search_button')),
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
      find.byKey(const Key('home_dashboard_ready')),
    );

    await tester.tap(find.byKey(const Key('nav_notes')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('notes_search_entry')), findsOneWidget);
    expect(find.byKey(ValueKey('notes_subject_$subjectId')), findsOneWidget);
    expect(find.text('Responsive Design Systems'), findsOneWidget);

    // The shortcut from Home lands on the same unscoped search screen.
    await tester.tap(find.byKey(const Key('nav_home')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('open_notes_search_button')));
    await _pumpFrames(tester);
    expect(find.text('Search PDFs'), findsOneWidget);
    // Search lives under the Notes branch, so the bar stays available.
    expect(find.byType(CollegeNavigationBar), findsOneWidget);
    expect(_activeDotScale(tester, 'Notes'), 1.0);
    expect(_activeDotOpacity(tester, 'Notes'), 1.0);
    expect(_activeDotScale(tester, 'Home'), .2);

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
    expect(_activeDotScale(tester, 'Home'), 1.0);
    expect(_activeDotOpacity(tester, 'Home'), 1.0);

    // With animations disabled the dot lands on the new destination in a single
    // frame instead of animating, and the icon never pops.
    await tester.pumpWidget(bar(2));
    await tester.pump();
    expect(_activeDotScale(tester, 'Timetable'), 1.0);
    expect(_activeDotOpacity(tester, 'Timetable'), 1.0);
    expect(_activeDotScale(tester, 'Home'), .2);
    expect(_activeDotOpacity(tester, 'Home'), 0.0);
    expect(
      _iconRestScale(tester, 'Timetable'),
      AppMotion.dockSelectedIconScale,
    );
    expect(_popScale(tester, 'Timetable'), 1.0);
    expect(_iconLift(tester, 'Timetable'), 0.0);

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
    // Reduced motion changes none of the glass: the dock keeps its blur and its
    // hairline rim, and the dot is the only selected-state decoration.
    expect(
      find.descendant(
        of: find.byKey(const Key('navigation_bar_surface')),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    final rimDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const Key('navigation_bar_rim')),
                )
                .decoration
            as BoxDecoration;
    expect(rimDecoration.border, isNotNull);
    expect(rimDecoration.gradient, isNull);
    expect(rimDecoration.boxShadow, isNull);
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

  testWidgets('floats as a translucent glass dock in both themes', (
    tester,
  ) async {
    Widget dock(Brightness brightness) => MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(
        bottomNavigationBar: CollegeNavigationBar(
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );

    for (final brightness in Brightness.values) {
      await tester.pumpWidget(dock(brightness));
      // MaterialApp cross-fades a theme change, so let it land before reading.
      await tester.pumpAndSettle();
      final surface = find.byKey(const Key('navigation_bar_surface'));
      final rendered = Theme.of(tester.element(surface));
      expect(rendered.brightness, brightness);
      final decoration =
          tester.widget<DecoratedBox>(surface).decoration as BoxDecoration;

      // Translucent glass with one soft shadow and no border on the outer box.
      expect(
        decoration.color,
        rendered.brightness == Brightness.dark
            ? const Color(0x14FFFFFF)
            : const Color(0xBFFFFFFF),
      );
      expect(
        decoration.color!.a,
        rendered.brightness == Brightness.dark ? lessThan(.1) : greaterThan(.7),
        reason: 'dark glass is a light wash, light glass a mostly-white fill',
      );
      expect(decoration.gradient, isNull);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, hasLength(1));
      expect(_dockRadius(tester), AppRadius.xl);

      // The blur belongs to the dock, and the hairline rim is painted above it
      // so the edge stays crisp.
      expect(
        find.descendant(of: surface, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      final rim =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(const Key('navigation_bar_rim')),
                  )
                  .decoration
              as BoxDecoration;
      expect(rim.border, isNotNull);
      expect(rim.gradient, isNull);

      // Five equal slots, every label present and inside the dock.
      final barRect = tester.getRect(surface);
      for (final destination in CollegeNavigationBar.destinations) {
        expect(find.byKey(destination.key), findsOneWidget);
        final label = find.byKey(Key('dock_label_${destination.label}'));
        expect(label, findsOneWidget);
        final labelRect = tester.getRect(label);
        expect(labelRect.left, greaterThanOrEqualTo(barRect.left));
        expect(labelRect.right, lessThanOrEqualTo(barRect.right));
      }
    }
  });
}

/// Corner radius the dock's glass is clipped to.
double _dockRadius(WidgetTester tester) {
  final clip = tester.widget<ClipRRect>(
    find.descendant(
      of: find.byKey(const Key('navigation_bar_surface')),
      matching: find.byType(ClipRRect),
    ),
  );
  return (clip.borderRadius as BorderRadius).topLeft.x;
}

/// Scale the destination's active dot paints with.
double _activeDotScale(WidgetTester tester, String label) => tester
    .widget<AnimatedScale>(find.byKey(Key('dock_dot_scale_$label')))
    .scale;

/// Opacity the destination's active dot paints with.
double _activeDotOpacity(WidgetTester tester, String label) => tester
    .widget<AnimatedOpacity>(find.byKey(Key('dock_dot_fade_$label')))
    .opacity;

/// Scale of a destination icon's tap pop, 1.0 at rest.
double _popScale(WidgetTester tester, String label) => tester
    .widget<Transform>(find.byKey(ValueKey('dock_icon_pop_$label')))
    .transform
    .getMaxScaleOnAxis();

/// Vertical lift of a destination icon's tap pop, in logical pixels.
double _iconLift(WidgetTester tester, String label) => tester
    .widget<Transform>(find.byKey(ValueKey('dock_icon_lift_$label')))
    .transform
    .getTranslation()
    .y;

/// Resting scale of a destination's icon.
double _iconRestScale(WidgetTester tester, String label) => tester
    .widget<Transform>(find.byKey(ValueKey('dock_icon_rest_$label')))
    .transform
    .getMaxScaleOnAxis();

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
