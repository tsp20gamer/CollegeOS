import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/reports/application/attendance_analytics_providers.dart';
import 'package:college_os/features/reports/presentation/screens/reports_screen.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/data/drift_semester_repository.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The subject is seeded with the app's default target of 75%; the student then
/// chooses 90%. Every attendance readout has to report the choice, not the
/// value the subject happened to be created with.
const double _chosenTarget = 0.9;

late AppDatabase _database;
late DriftSubjectRepository _subjects;
late DriftSemesterRepository _semesters;
late int _subjectId;
late int _semesterId;

void main() {
  setUp(() async {
    _database = AppDatabase.forTesting(NativeDatabase.memory());
    await DriftOnboardingRepository(_database).completeSetup(_setup);
    _subjects = DriftSubjectRepository(_database.subjectsDao);
    _semesters = DriftSemesterRepository(_database.semestersDao);
    _semesterId = (await _database.semestersDao.findActive())!.id;
    _subjectId = await _subjects.create((
      semesterId: _semesterId,
      name: 'Operating Systems',
      shortCode: 'OS',
      professor: 'Dr Rao',
      room: 'B-204',
      attendanceTarget: 0.75,
      displayColor: 0xFF2563EB,
    ));
  });

  tearDown(() => _database.close());

  test(
    'choosing a target re-targets the subjects that already exist',
    () async {
      expect((await _subjects.findById(_subjectId))!.attendanceTarget, 0.75);

      expect(await _chooseTarget(), isTrue);

      expect(
        (await _database.settingsDao.getSettings()).defaultAttendanceTarget,
        _chosenTarget,
      );
      expect(
        (await _subjects.findById(_subjectId))!.attendanceTarget,
        _chosenTarget,
      );
    },
  );

  testWidgets('Attendance reports the chosen target for every subject', (
    tester,
  ) async {
    expect(await _chooseTarget(), isTrue);
    final subject = (await _subjects.findById(_subjectId))!;
    final semester = (await _semesters.findById(_semesterId))!;

    // The card is fed straight from the stored subject, so a target that never
    // reached the database could not show up on screen.
    expect(subject.attendanceTarget, _chosenTarget);

    _useTallCanvas(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeSemesterProvider.overrideWith((ref) => Stream.value(semester)),
          attendanceEngineProvider.overrideWith(
            (ref) => Stream.value(_snapshot(subject, semester)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AttendanceScreen()),
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Subject View'));
    expect(find.textContaining('Target 75%'), findsNothing);

    await tester.tap(find.text('Subject View'));
    await _pumpUntilFound(tester, find.textContaining('Target 90%'));
    expect(find.textContaining('Target 90%'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('Analytics reports the chosen target for every subject', (
    tester,
  ) async {
    expect(await _chooseTarget(), isTrue);
    final subject = (await _subjects.findById(_subjectId))!;
    final semester = (await _semesters.findById(_semesterId))!;
    expect(subject.attendanceTarget, _chosenTarget);

    _useTallCanvas(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          semestersProvider.overrideWith((ref) => Stream.value([semester])),
          allSemesterAttendanceProvider.overrideWith(
            (ref) => Stream.value([
              SemesterAttendanceBundle(
                semester: semester,
                snapshot: _snapshot(subject, semester),
              ),
            ]),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ReportsScreen()),
      ),
    );
    await _pumpUntilFound(tester, find.textContaining('Target 90%'));
    expect(find.textContaining('Target 90%'), findsOneWidget);
    expect(find.textContaining('Target 75%'), findsNothing);

    await _disposeTree(tester);
  });
}

/// Applies [_chosenTarget] the way the Settings screen's target dialog does,
/// through the controller that dialog saves with.
Future<bool> _chooseTarget() async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(_database)],
  );
  addTearDown(container.dispose);
  return container
      .read(settingsPreferenceControllerProvider.notifier)
      .setDefaultAttendanceTarget(_chosenTarget);
}

/// One attended class today, built from the stored subject so the readouts read
/// the target that is actually persisted.
AttendanceEngineSnapshot _snapshot(Subject subject, Semester semester) {
  final today = DateUtils.dateOnly(DateTime.now());
  final timestamp = today.toUtc();
  return AttendanceEngineSnapshot(
    subjects: [subject],
    timetable: [
      (
        id: 1,
        semesterId: semester.id,
        subjectId: subject.id,
        weekday: today.weekday,
        startTime: 540,
        endTime: 600,
        effectiveFrom: today.subtract(const Duration(days: 10)),
        effectiveUntil: null,
      ),
    ],
    attendance: [
      (
        id: 1,
        semesterId: semester.id,
        timetableEntryId: 1,
        subjectId: subject.id,
        date: today,
        startTime: 540,
        endTime: 600,
        status: ClassAttendanceStatus.present,
        note: '',
        manuallyModified: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ],
    overrides: const [],
  );
}

void _useTallCanvas(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

final DateTime _today = DateUtils.dateOnly(DateTime.now());

final CollegeSetup _setup = CollegeSetup(
  studentName: 'Test Student',
  collegeName: 'City College',
  course: 'B.Tech',
  branch: 'Computer Science',
  semesterNumber: 3,
  academicYear: '${_today.year}-${_today.year + 1}',
  semesterStartDate: _today.subtract(const Duration(days: 30)),
  semesterEndDate: _today.add(const Duration(days: 120)),
  defaultAttendanceTarget: 0.75,
);
