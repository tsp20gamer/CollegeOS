import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/routing/navigation_shell.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and navigates all five destinations', (tester) async {
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

    expect(find.text('Your day, calmly organized.'), findsOneWidget);
    expect(find.byType(CollegeNavigationDock), findsOneWidget);
    final systemUi = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byKey(const Key('app_system_ui_style')),
    );
    expect(systemUi.value.statusBarIconBrightness, Brightness.dark);
    expect(systemUi.value.systemNavigationBarIconBrightness, Brightness.dark);
    expect(
      tester
          .widget<SafeArea>(
            find.byKey(const Key('app_scaffold_safe_area')).first,
          )
          .bottom,
      isFalse,
    );
    final contentPadding = tester.widget<SliverPadding>(
      find.byKey(const Key('app_scaffold_content_padding')).first,
    );
    expect(
      (contentPadding.padding as EdgeInsets).bottom,
      greaterThanOrEqualTo(AppLayout.floatingDockContentInset),
    );
    final navigationScaffold = tester.widget<Scaffold>(
      find.byKey(const Key('navigation_shell_scaffold')),
    );
    expect(navigationScaffold.extendBody, isTrue);
    expect(navigationScaffold.bottomNavigationBar, isNull);
    expect(find.byKey(const Key('navigation_shell_overlay')), findsOneWidget);
    expect(find.byKey(const Key('floating_navigation_dock')), findsOneWidget);
    expect(find.byKey(const Key('navigation_moving_shade')), findsNothing);
    expect(find.byKey(const Key('navigation_page_transition')), findsNothing);
    expect(find.byKey(const Key('navigation_page_slide')), findsNothing);
    expect(find.byKey(const Key('navigation_page_scale')), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    final glassSurface = tester.widget<DecoratedBox>(
      find.byKey(const Key('navigation_glass_surface')),
    );
    final glassDecoration = glassSurface.decoration as BoxDecoration;
    expect(glassDecoration.gradient, isA<LinearGradient>());
    expect(
      (glassDecoration.gradient! as LinearGradient).colors.every(
        (color) => color.a > .05 && color.a <= .8,
      ),
      isTrue,
    );
    expect(
      tester.getSize(find.byKey(const Key('dock_selection_surface_Home'))),
      const Size.square(46),
    );
    final selectedSurface = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('dock_selection_surface_Home')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final selectedDecoration = selectedSurface.decoration as BoxDecoration;
    expect(selectedDecoration.shape, BoxShape.circle);
    expect(selectedDecoration.gradient, isA<LinearGradient>());
    expect(selectedDecoration.boxShadow, isNull);
    for (final key in const [
      Key('nav_home'),
      Key('nav_attendance'),
      Key('nav_timetable'),
      Key('nav_tasks'),
      Key('nav_settings'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(find.text('More'), findsNothing);

    var previousDestination = 'Home';
    for (final destination in [
      ('Attendance', 'One timetable, two synchronized views.'),
      ('Timetable', 'A practical view of your week.'),
      ('Tasks', 'Assignments and personal work, together.'),
      ('Settings', 'College Information'),
    ]) {
      await tester.tap(find.byKey(Key('nav_${destination.$1.toLowerCase()}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final pageOffset = tester
          .widget<SlideTransition>(find.byKey(const Key('dock_page_motion')))
          .position
          .value
          .dx;
      expect(pageOffset, greaterThan(0));
      expect(pageOffset, lessThan(.012));
      expect(find.byKey(const Key('navigation_page_transition')), findsNothing);
      expect(find.byKey(const Key('navigation_page_slide')), findsNothing);
      expect(find.byKey(const Key('navigation_page_scale')), findsNothing);
      final selectedScale = _dockScale(tester, destination.$1);
      final deselectedScale = _dockScale(tester, previousDestination);
      expect(selectedScale, greaterThan(1));
      expect(selectedScale, lessThan(1.08));
      expect(deselectedScale, greaterThan(1));
      expect(deselectedScale, lessThan(1.08));

      final colors = Theme.of(
        tester.element(find.byType(CollegeNavigationDock)),
      ).colorScheme;
      final selectedIcon = tester.widget<Icon>(
        find.byKey(ValueKey('dock_icon_${destination.$1}_true')),
      );
      expect(selectedIcon.color, isNot(colors.onSurfaceVariant));
      expect(selectedIcon.color, isNot(colors.onPrimaryContainer));

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<Text>(find.byKey(Key('dock_label_${destination.$1}')))
            .data,
        destination.$1,
      );
      expect(
        tester
            .widget<Text>(find.byKey(Key('dock_label_$previousDestination')))
            .data,
        '',
      );
      expect(
        tester
            .widget<SlideTransition>(find.byKey(const Key('dock_page_motion')))
            .position
            .value,
        Offset.zero,
      );
      expect(find.text(destination.$2), findsOneWidget);
      if (destination.$1 == 'Attendance') {
        expect(find.text('Analytics'), findsOneWidget);
        expect(
          find.byKey(const Key('open_attendance_analytics')),
          findsOneWidget,
        );
      }
      expect(_dockScale(tester, destination.$1), closeTo(1.08, 0.001));
      expect(_dockScale(tester, previousDestination), closeTo(1, 0.001));
      previousDestination = destination.$1;
    }
    await _disposeApp(tester);
  });

  testWidgets('navigation dock honors reduced-motion accessibility', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            bottomNavigationBar: CollegeNavigationDock(
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final containers = tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(containers, hasLength(5));
    expect(
      containers.every((container) => container.duration == Duration.zero),
      isTrue,
    );
    expect(find.byKey(const Key('navigation_moving_shade')), findsNothing);
  });
}

double _dockScale(WidgetTester tester, String label) => tester
    .widget<Transform>(find.byKey(Key('dock_icon_scale_$label')))
    .transform
    .getMaxScaleOnAxis();

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}
