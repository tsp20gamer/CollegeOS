import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Calendar and Classes render the same attendance snapshot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateUtils.dateOnly(DateTime.now());
    final timestamp = now.toUtc();
    final math = (
      id: 1,
      semesterId: 1,
      name: 'Mathematics',
      shortCode: 'MATH',
      professor: 'Professor Rao',
      room: 'A-101',
      attendanceTarget: 0.75,
      displayColor: 0xFF4758D6,
      isArchived: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final english = (
      id: 2,
      semesterId: 1,
      name: 'English',
      shortCode: 'ENG',
      professor: 'Professor Sen',
      room: 'B-201',
      attendanceTarget: 0.75,
      displayColor: 0xFF208A5D,
      isArchived: false,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final snapshot = AttendanceEngineSnapshot(
      subjects: [math, english],
      timetable: [
        (
          id: 1,
          semesterId: 1,
          subjectId: 1,
          weekday: now.weekday,
          startTime: 540,
          endTime: 600,
          effectiveFrom: now.subtract(const Duration(days: 10)),
          effectiveUntil: null,
        ),
        (
          id: 2,
          semesterId: 1,
          subjectId: 2,
          weekday: now.weekday,
          startTime: 600,
          endTime: 660,
          effectiveFrom: now.subtract(const Duration(days: 10)),
          effectiveUntil: null,
        ),
      ],
      attendance: [
        (
          id: 1,
          semesterId: 1,
          timetableEntryId: 1,
          subjectId: 1,
          date: now,
          startTime: 540,
          endTime: 600,
          status: ClassAttendanceStatus.present,
          note: '',
          manuallyModified: true,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
        (
          id: 2,
          semesterId: 1,
          timetableEntryId: 2,
          subjectId: 2,
          date: now,
          startTime: 600,
          endTime: 660,
          status: ClassAttendanceStatus.absent,
          note: '',
          manuallyModified: true,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
      overrides: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSemesterProvider.overrideWith(
            (ref) => Stream.value((
              id: 1,
              name: 'Semester 1',
              semesterNumber: 1,
              academicYear: '${now.year}-${now.year + 1}',
              startDate: now.subtract(const Duration(days: 10)),
              endDate: now.add(const Duration(days: 120)),
              isActive: true,
              createdAt: timestamp,
              updatedAt: timestamp,
            )),
          ),
          attendanceEngineProvider.overrideWith(
            (ref) => Stream.value(snapshot),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AttendanceScreen()),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Partial attendance'));
    final calendar = find.byKey(const Key('attendance_month_calendar'));
    expect(calendar, findsOneWidget);
    expect(tester.getSize(calendar).height, lessThanOrEqualTo(330));
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('Subject View'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Subject attendance'), findsOneWidget);
    expect(find.text('Mathematics'), findsWidgets);
    expect(find.text('English'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('the month calendar never reserves the system bottom inset', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      systemPadding: const FakeViewPadding(top: 24, bottom: 96),
    );

    final calendar = tester.getRect(
      find.byKey(const Key('attendance_month_calendar')),
    );
    final grid = find.byKey(const Key('attendance_month_grid'));
    final gridRect = tester.getRect(grid);
    final cells = find.descendant(of: grid, matching: find.byType(InkWell));
    final lastCell = tester.getRect(cells.last);
    final today = DateUtils.dateOnly(DateTime.now());
    final leading = DateTime(today.year, today.month).weekday - 1;
    final weekCount =
        (leading + DateUtils.getDaysInMonth(today.year, today.month) + 6) ~/ 7;

    expect(gridRect.height, weekCount * AppLayout.compactCalendarDayExtent);
    expect(lastCell.bottom, gridRect.bottom);
    // Only the card's own padding sits below the last week. The navigation-bar
    // inset is not card content, so it must stay outside the calendar.
    expect(calendar.bottom - gridRect.bottom, AppSpacing.sm);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

/// The system navigation-bar inset must never become padding inside the
/// month grid: the card would show an empty band under its last week.
Future<void> _pumpCalendar(
  WidgetTester tester, {
  required FakeViewPadding systemPadding,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = systemPadding;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  final now = DateUtils.dateOnly(DateTime.now());
  final timestamp = now.toUtc();
  const snapshot = AttendanceEngineSnapshot(
    subjects: [],
    timetable: [],
    attendance: [],
    overrides: [],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeSemesterProvider.overrideWith(
          (ref) => Stream.value((
            id: 1,
            name: 'Semester 1',
            semesterNumber: 1,
            academicYear: '${now.year}-${now.year + 1}',
            startDate: DateTime(now.year, 1, 1),
            endDate: DateTime(now.year, 12, 31),
            isActive: true,
            createdAt: timestamp,
            updatedAt: timestamp,
          )),
        ),
        attendanceEngineProvider.overrideWith((ref) => Stream.value(snapshot)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: AttendanceScreen()),
      ),
    ),
  );
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('attendance_month_calendar')),
  );
  // Let the screen's settle-in motion finish, so the geometry assertions
  // below measure the layout at rest.
  await tester.pump(const Duration(milliseconds: 600));
}
