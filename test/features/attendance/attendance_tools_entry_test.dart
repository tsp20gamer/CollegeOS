import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The Attendance screen's two tools are entries, not icons.
///
/// They used to be a header icon and a pill whose label said nothing about what
/// was behind them. This checks the contract that replaced them: both carry a
/// full name and a purpose, both are as large as a card, both stay reachable
/// even when no semester is active, and each one opens its own screen.
void main() {
  testWidgets('both tools are named cards that open their own screen', (
    tester,
  ) async {
    await _pumpAttendance(tester, width: 390);
    await _pumpUntilFound(tester, find.text('Day View'));

    final planner = find.byKey(const Key('open_attendance_planner'));
    final analytics = find.byKey(const Key('open_attendance_analytics'));
    expect(planner, findsOneWidget);
    expect(analytics, findsOneWidget);
    expect(find.text('Attendance Planner'), findsOneWidget);
    expect(find.text('Attendance Analytics'), findsOneWidget);
    expect(find.text('See what a missed class costs'), findsOneWidget);
    expect(find.text('Trends, streaks and reports'), findsOneWidget);

    // Big enough to be found by name rather than hunted for: a card-sized tap
    // target on one row, above the calendar it belongs to.
    final plannerRect = tester.getRect(planner);
    final analyticsRect = tester.getRect(analytics);
    expect(plannerRect.width, greaterThanOrEqualTo(150));
    expect(plannerRect.height, greaterThanOrEqualTo(96));
    expect(analyticsRect.height, plannerRect.height);
    expect(plannerRect.top, analyticsRect.top);
    expect(plannerRect.right, lessThanOrEqualTo(analyticsRect.left));
    final toggle = tester.getRect(
      find.byKey(const Key('attendance_mode_toggle')),
    );
    expect(
      plannerRect.bottom,
      lessThanOrEqualTo(toggle.top),
      reason: 'the tools lead the body, above the Day/Subject views',
    );

    await tester.tap(planner);
    await _pumpUntilFound(tester, find.text('Planner screen'));
    GoRouter.of(tester.element(find.text('Planner screen'))).pop();
    // The popped page stays in the tree while its transition runs, so the
    // second tap waits until the attendance screen is the one on top again.
    await _pumpUntilGone(tester, find.text('Planner screen'));
    await tester.tap(find.byKey(const Key('open_attendance_analytics')));
    await _pumpUntilFound(tester, find.text('Analytics screen'));
    expect(find.text('Planner screen'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('a compact phone stacks the same two entries', (tester) async {
    await _pumpAttendance(tester, width: 320);
    await _pumpUntilFound(tester, find.text('Day View'));

    final plannerRect = tester.getRect(
      find.byKey(const Key('open_attendance_planner')),
    );
    final analyticsRect = tester.getRect(
      find.byKey(const Key('open_attendance_analytics')),
    );
    expect(
      analyticsRect.top,
      greaterThanOrEqualTo(plannerRect.bottom),
      reason: 'neither name is squeezed onto a half-width tile',
    );
    expect(analyticsRect.width, plannerRect.width);
    expect(plannerRect.width, greaterThanOrEqualTo(280));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('the entries survive a missing active semester', (tester) async {
    await _pumpAttendance(tester, width: 390, withSemester: false);
    await _pumpUntilFound(tester, find.text('No active semester'));

    // Analytics reports across every semester, so a student without an active
    // one still has to be able to find it.
    expect(find.byKey(const Key('open_attendance_planner')), findsOneWidget);
    expect(find.byKey(const Key('open_attendance_analytics')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pumpAttendance(
  WidgetTester tester, {
  required double width,
  bool withSemester = true,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final now = DateUtils.dateOnly(DateTime.now());
  final timestamp = now.toUtc();
  // A semester that contains today and a timetable with nothing on it: the
  // tools are asserted first, and the empty day keeps the rest of the body
  // from depending on this fixture.
  const snapshot = AttendanceEngineSnapshot(
    subjects: [],
    timetable: [],
    attendance: [],
    overrides: [],
  );
  final router = GoRouter(
    initialLocation: RoutePaths.attendance,
    routes: [
      GoRoute(
        path: RoutePaths.attendance,
        builder: (context, state) => const Scaffold(body: AttendanceScreen()),
        routes: [
          GoRoute(
            path: 'planner',
            builder: (context, state) =>
                const Scaffold(body: Text('Planner screen')),
          ),
          GoRoute(
            path: 'analytics',
            builder: (context, state) =>
                const Scaffold(body: Text('Analytics screen')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeSemesterProvider.overrideWith(
          (ref) => Stream.value(
            withSemester
                ? (
                    id: 1,
                    name: 'Semester 1',
                    semesterNumber: 1,
                    academicYear: '${now.year}-${now.year + 1}',
                    startDate: now.subtract(const Duration(days: 10)),
                    endDate: now.add(const Duration(days: 120)),
                    isActive: true,
                    createdAt: timestamp,
                    updatedAt: timestamp,
                  )
                : null,
          ),
        ),
        attendanceEngineProvider.overrideWith((ref) => Stream.value(snapshot)),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsWidgets);
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (
    var attempt = 0;
    attempt < 100 && finder.evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsNothing);
}
