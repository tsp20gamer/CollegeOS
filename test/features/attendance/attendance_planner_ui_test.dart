import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_planner_screen.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'planner updates a projection and remains usable with large text',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1500);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceSubjectsProvider.overrideWith(
              (ref) => AsyncData([
                SubjectAttendanceResult(
                  subject: _subject,
                  metrics: AttendanceCalculator.calculate(
                    presentCount: 8,
                    absentCount: 2,
                    cancelledCount: 0,
                    target: .75,
                  ),
                  history: const [],
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 600),
                textScaler: TextScaler.linear(1.4),
                disableAnimations: true,
              ),
              child: const AttendancePlannerScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Planner'), findsOneWidget);
      expect(find.text('80.0%'), findsWidgets);
      final increaseMissed = find.byKey(
        const ValueKey('planner_increase_Classes missed'),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -360));
      await tester.pump();
      await tester.ensureVisible(increaseMissed);
      tester.widget<IconButton>(increaseMissed).onPressed!();
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, 360));
      await tester.pump();
      expect(find.text('75.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('planner projects the cost of the days it will be skipped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceSubjectsProvider.overrideWith((ref) => AsyncData(_results)),
          activeSemesterProvider.overrideWith((ref) => Stream.value(_semester)),
          attendanceEngineProvider.overrideWith(
            (ref) => Stream.value(_snapshot),
          ),
          collegeSettingsProvider.overrideWith(
            (ref) => Stream.value(_settings),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(480, 960),
              disableAnimations: true,
            ),
            child: const AttendancePlannerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip days'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Add the days you will miss'),
      findsOneWidget,
      reason: 'the plan prompt shows until a day is chosen',
    );

    // The picker opens on the only month the semester covers, so the day cell
    // is unambiguous whichever way today clamps into the semester.
    await tester.tap(find.byKey(const Key('planner_add_absent_day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('17'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final chip = find.byKey(const ValueKey('planner_skip_day_20260817'));
    expect(chip, findsOneWidget);
    expect(find.text('Mon, 17 Aug'), findsOneWidget);

    final impact = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Attendance after these absences'),
      120,
      scrollable: impact,
    );
    await tester.pumpAndSettle();

    // Overall attendance moves from every subject combined to every subject
    // plus the two classes this Monday holds: 12 of 16 becomes 12 of 18.
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('66.7%'), findsOneWidget);
    expect(find.textContaining('2 classes missed'), findsOneWidget);
    expect(
      find.textContaining('leaves overall attendance at 66.7%'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Subject by subject'),
      120,
      scrollable: impact,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('9 of 12'), findsOneWidget);
    expect(
      find.textContaining('1 missed'),
      findsNWidgets(2),
      reason: 'both subjects lose exactly one class',
    );
    expect(find.text('69.2%'), findsOneWidget);
    expect(find.text('60.0%'), findsOneWidget);
    expect(find.text('Other subjects are unaffected.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Removing the day returns to the empty plan prompt.
    await tester.scrollUntilVisible(chip, -120, scrollable: impact);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: chip, matching: find.byIcon(Icons.close_rounded)),
    );
    await tester.pumpAndSettle();
    expect(chip, findsNothing);
    expect(find.textContaining('Add the days you will miss'), findsOneWidget);
  });

  testWidgets('planner clears every chosen day at once', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceSubjectsProvider.overrideWith((ref) => AsyncData(_results)),
          activeSemesterProvider.overrideWith((ref) => Stream.value(_semester)),
          attendanceEngineProvider.overrideWith(
            (ref) => Stream.value(_snapshot),
          ),
          collegeSettingsProvider.overrideWith(
            (ref) => Stream.value(_settings),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(480, 960),
              disableAnimations: true,
            ),
            child: const AttendancePlannerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner_add_absent_day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('17'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final impact = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('planner_clear_days')),
      120,
      scrollable: impact,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner_clear_days')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Add the days you will miss'),
      findsOneWidget,
      reason: 'clearing the days returns the planner to its prompt',
    );
    expect(find.text('Attendance after these absences'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planner releases the timetable when returning to counts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var engineObserved = false;
    final container = ProviderContainer(
      overrides: [
        attendanceSubjectsProvider.overrideWith((ref) => AsyncData(_results)),
        activeSemesterProvider.overrideWith((ref) => Stream.value(_semester)),
        attendanceEngineProvider.overrideWith((ref) => Stream.value(_snapshot)),
        collegeSettingsProvider.overrideWith((ref) => Stream.value(_settings)),
      ],
      observers: [
        _EngineObserver(() {
          engineObserved = true;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(480, 960),
              disableAnimations: true,
            ),
            child: const AttendancePlannerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(engineObserved, isFalse);

    await tester.tap(find.text('Skip days'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(engineObserved, isTrue);

    // Switching back must release the timetable stream, not just hide it.
    await tester.tap(find.text('Class counts'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('planner ignores a dismissed date picker', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceSubjectsProvider.overrideWith((ref) => AsyncData(_results)),
          activeSemesterProvider.overrideWith((ref) => Stream.value(_semester)),
          attendanceEngineProvider.overrideWith(
            (ref) => Stream.value(_snapshot),
          ),
          collegeSettingsProvider.overrideWith(
            (ref) => Stream.value(_settings),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(480, 960)),
            child: const AttendancePlannerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip days'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('planner_add_absent_day')));
    await tester.pumpAndSettle();

    // Dismissing the dialog without choosing leaves the plan untouched.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('planner_skip_day_20260817')),
      findsNothing,
    );
    expect(find.textContaining('Add the days you will miss'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Records when the planner first subscribes to the attendance engine.
final class _EngineObserver extends ProviderObserver {
  _EngineObserver(this._onObserved);

  final void Function() _onObserved;

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (context.provider == attendanceEngineProvider) {
      _onObserved();
    }
  }
}

final _now = DateTime.utc(2026, 8, 1);

final Semester _semester = (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 31),
  isActive: true,
  createdAt: _now,
  updatedAt: _now,
);

final CollegeSettings _settings = (
  studentName: 'Alexandria Student',
  collegeName: 'City College',
  course: 'Bachelor of Technology',
  branch: 'Computer Science',
  academicYearStartDate: null,
  academicYearEndDate: null,
  defaultAttendanceTarget: .75,
  themeMode: CollegeThemeMode.light,
  onboardingCompleted: true,
  notificationsEnabled: false,
  automaticLocalBackup: false,
  classRemindersEnabled: true,
  classReminderMinutesBefore: 10,
);

// The classroom scenario: Maths at 9:00 and Physics at 10:00 every Monday.
final _snapshot = AttendanceEngineSnapshot(
  subjects: [_math, _physics],
  timetable: [_slot(1), _slot(2, subjectId: 2, start: 600)],
  attendance: [
    for (var index = 0; index < 9; index++)
      _record(100 + index, 1, 3 + index, ClassAttendanceStatus.present),
    for (var index = 0; index < 3; index++)
      _record(200 + index, 1, 12 + index, ClassAttendanceStatus.absent),
    for (var index = 0; index < 3; index++)
      _record(300 + index, 2, 3 + index, ClassAttendanceStatus.present),
    _record(400, 2, 6, ClassAttendanceStatus.absent),
  ],
  overrides: const [],
);

final _results = <SubjectAttendanceResult>[
  SubjectAttendanceResult(
    subject: _math,
    metrics: _metrics(present: 9, absent: 3),
    history: const [],
  ),
  SubjectAttendanceResult(
    subject: _physics,
    metrics: _metrics(present: 3, absent: 1),
    history: const [],
  ),
];

AttendanceMetrics _metrics({required int present, required int absent}) =>
    AttendanceCalculator.calculate(
      presentCount: present,
      absentCount: absent,
      cancelledCount: 0,
      target: .75,
    );

Subject _subjectOf({
  required int id,
  required String name,
  required String shortCode,
}) => (
  id: id,
  semesterId: 1,
  name: name,
  shortCode: shortCode,
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: _now,
  updatedAt: _now,
);

final _math = _subjectOf(id: 1, name: 'Mathematics', shortCode: 'MATH');
final _physics = _subjectOf(id: 2, name: 'Physics', shortCode: 'PHY');

AttendanceTimetableSlot _slot(int id, {int subjectId = 1, int start = 540}) => (
  id: id,
  semesterId: 1,
  subjectId: subjectId,
  weekday: DateTime.monday,
  startTime: start,
  endTime: start + 60,
  effectiveFrom: null,
  effectiveUntil: null,
);

ExplicitClassAttendance _record(
  int id,
  int subjectId,
  int day,
  ClassAttendanceStatus status,
) => (
  id: id,
  semesterId: 1,
  timetableEntryId: null,
  subjectId: subjectId,
  date: DateTime(2026, 8, day),
  startTime: 540,
  endTime: 600,
  status: status,
  note: '',
  manuallyModified: true,
  createdAt: _now,
  updatedAt: _now,
);

final Subject _subject = (
  id: 1,
  semesterId: 1,
  name: 'A very long subject name for accessibility testing',
  shortCode: 'LONG',
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4F8CFF,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
