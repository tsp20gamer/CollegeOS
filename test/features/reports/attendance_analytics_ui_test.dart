import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/reports/application/attendance_analytics_providers.dart';
import 'package:college_os/features/reports/presentation/screens/reports_screen.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches from monthly to weighted all-time analytics', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final today = DateUtils.dateOnly(DateTime.now());
    final active = _semester(
      id: 2,
      number: 2,
      start: DateTime(today.year, today.month, 1),
      end: DateTime(today.year, today.month + 3, 0),
      active: true,
    );
    final previous = _semester(
      id: 1,
      number: 1,
      start: DateTime(today.year - 1, 8, 1),
      end: DateTime(today.year - 1, 12, 31),
    );
    final activeSubject = _subject(2, 2, 'Mathematics', 'MATH');
    final previousSubject = _subject(1, 1, 'Programming', 'C');
    final bundles = [
      SemesterAttendanceBundle(
        semester: previous,
        snapshot: _snapshot(
          previousSubject,
          previous.startDate,
          present: 1,
          absent: 1,
        ),
      ),
      SemesterAttendanceBundle(
        semester: active,
        snapshot: _snapshot(activeSubject, today, present: 9, absent: 1),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          semestersProvider.overrideWith(
            (ref) => Stream.value([active, previous]),
          ),
          allSemesterAttendanceProvider.overrideWith(
            (ref) => Stream.value(bundles),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ReportsScreen()),
      ),
    );
    await _pumpUntil(tester, find.text('90.0%'));
    expect(find.text('Attendance Analytics'), findsOneWidget);
    final ring = find.byKey(const Key('analytics_overall_ring'));
    expect(ring, findsOneWidget);
    expect(tester.getSize(ring).width, greaterThanOrEqualTo(112));
    expect(
      tester.getSize(find.byKey(const Key('analytics_summary_card'))).height,
      lessThanOrEqualTo(270),
    );
    expect(
      tester.getSize(find.byKey(const Key('analytics_trend_card'))).height,
      lessThanOrEqualTo(225),
    );

    await tester.tap(find.text('All Time'));
    await tester.pumpAndSettle();
    expect(find.text('83.3%'), findsOneWidget);
    expect(find.textContaining('2 semesters'), findsOneWidget);
    expect(find.byKey(const Key('analytics_trend_bar_S1')), findsOneWidget);
    expect(find.byKey(const Key('analytics_trend_bar_S2')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('analytics_trend_bar_S1'))).width,
      58,
    );
  });
}

Semester _semester({
  required int id,
  required int number,
  required DateTime start,
  required DateTime end,
  bool active = false,
}) => (
  id: id,
  name: 'Semester $number',
  semesterNumber: number,
  academicYear: '${start.year}-${end.year}',
  startDate: start,
  endDate: end,
  isActive: active,
  createdAt: start.toUtc(),
  updatedAt: start.toUtc(),
);

Subject _subject(int id, int semesterId, String name, String code) => (
  id: id,
  semesterId: semesterId,
  name: name,
  shortCode: code,
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

AttendanceEngineSnapshot _snapshot(
  Subject subject,
  DateTime date, {
  required int present,
  required int absent,
}) => AttendanceEngineSnapshot(
  subjects: [subject],
  timetable: const [],
  attendance: [
    for (var index = 0; index < present + absent; index++)
      (
        id: index + 1,
        semesterId: subject.semesterId,
        timetableEntryId: null,
        subjectId: subject.id,
        date: date,
        startTime: 480 + index,
        endTime: 481 + index,
        status: index < present
            ? ClassAttendanceStatus.present
            : ClassAttendanceStatus.absent,
        note: '',
        manuallyModified: true,
        createdAt: date.toUtc(),
        updatedAt: date.toUtc(),
      ),
  ],
  overrides: const [],
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}
