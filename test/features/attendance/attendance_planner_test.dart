import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_planner.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'projects attended and missed classes without mutating current data',
    () {
      final current = AttendanceCalculator.calculate(
        presentCount: 8,
        absentCount: 2,
        cancelledCount: 1,
        target: .75,
      );

      final plan = AttendancePlannerService.project(
        current: current,
        plannedPresent: 2,
        plannedAbsent: 1,
      );

      expect(current.presentCount, 8);
      expect(current.absentCount, 2);
      expect(plan.projected.presentCount, 10);
      expect(plan.projected.absentCount, 3);
      expect(plan.projected.cancelledCount, 1);
      expect(plan.projected.attendancePercentage, closeTo(76.923, .001));
      expect(plan.plannedClasses, 3);
    },
  );

  test('uses the exact calculator at the target boundary', () {
    final current = AttendanceCalculator.calculate(
      presentCount: 3,
      absentCount: 1,
      cancelledCount: 0,
      target: .75,
    );
    final missed = AttendancePlannerService.project(
      current: current,
      plannedPresent: 0,
      plannedAbsent: 1,
    );
    final recovered = AttendancePlannerService.project(
      current: current,
      plannedPresent: 1,
      plannedAbsent: 0,
    );

    expect(missed.projected.isAtOrAboveTarget, isFalse);
    expect(recovered.projected.isAtOrAboveTarget, isTrue);
  });

  test('rejects negative planned counts', () {
    final current = AttendanceCalculator.calculate(
      presentCount: 1,
      absentCount: 0,
      cancelledCount: 0,
      target: .75,
    );
    expect(
      () => AttendancePlannerService.project(
        current: current,
        plannedPresent: -1,
        plannedAbsent: 0,
      ),
      throwsArgumentError,
    );
  });

  group('skip day planning', () {
    test('skips every unmarked class on each chosen day, cumulatively', () {
      final plan = _plan([DateTime(2026, 8, 17), DateTime(2026, 8, 18)]);

      expect(plan.days, hasLength(2));
      expect(plan.days.first.date, DateTime(2026, 8, 17));
      expect(plan.days.first.skippableCount, 2);
      expect(plan.days.last.skippableCount, 1);
      expect(plan.skippedClassCount, 3);
      expect(plan.contributingDayCount, 2);
      expect(plan.changesAnything, isTrue);

      // Ordered by the first class the plan would miss: Monday 9:00 first.
      expect(plan.subjects.map((impact) => impact.subject.shortCode), [
        'MATH',
        'PHY',
      ]);
      final math = plan.subjects.first;
      expect(math.skippedClasses, 2);
      expect(math.current.presentCount, 9);
      expect(math.current.heldClasses, 12);
      expect(math.projected.heldClasses, 14);
      expect(math.projected.attendancePercentage, closeTo(64.285, .001));
      expect(math.current.isAtOrAboveTarget, isTrue);
      expect(math.projected.isAtOrAboveTarget, isFalse);
      expect(math.projected.classesRequired, 6);

      final physics = plan.subjects.last;
      expect(physics.skippedClasses, 1);
      expect(physics.projected.attendancePercentage, closeTo(60, .001));

      // Overall attendance is every subject combined, on the settings target.
      expect(plan.overallCurrent.presentCount, 12);
      expect(plan.overallCurrent.heldClasses, 16);
      expect(plan.overallCurrent.attendancePercentage, closeTo(75, .001));
      expect(plan.overallProjected.heldClasses, 19);
      expect(plan.overallProjected.attendancePercentage, closeTo(63.157, .001));
      expect(plan.overallProjected.isAtOrAboveTarget, isFalse);
      expect(plan.overallPercentagePointChange, closeTo(-11.842, .001));
    });

    test('counts a repeated date once and sorts the chosen days', () {
      final plan = _plan([
        DateTime(2026, 8, 18),
        DateTime(2026, 8, 17),
        DateTime(2026, 8, 17, 12),
      ]);

      expect(plan.days.map((day) => day.date).toList(), [
        DateTime(2026, 8, 17),
        DateTime(2026, 8, 18),
      ]);
      expect(plan.skippedClassCount, 3);
    });

    test('already marked and cancelled classes never move', () {
      final snapshot = _snapshot(
        attendance: [
          ..._history,
          _record(
            900,
            1,
            17,
            ClassAttendanceStatus.present,
            timetableEntryId: 1,
          ),
          _record(
            901,
            2,
            17,
            ClassAttendanceStatus.cancelled,
            timetableEntryId: 2,
          ),
        ],
      );
      final plan = _plan([DateTime(2026, 8, 17)], snapshot: snapshot);

      // The present mark counts as attendance; the cancelled class is held by
      // nobody, so neither is treated as a class the plan could lose.
      expect(plan.days.single.skippableCount, 0);
      expect(plan.days.single.alreadyMarkedCount, 1);
      expect(plan.changesAnything, isFalse);
      expect(plan.subjects, isEmpty);
      expect(
        plan.overallProjected.attendancePercentage,
        plan.overallCurrent.attendancePercentage,
      );
    });

    test('holidays and dates outside the semester cost nothing', () {
      final snapshot = _snapshot(
        overrides: [_override(CalendarDayOverrideType.holiday)],
      );
      final plan = _plan([
        DateTime(2026, 8, 17),
        DateTime(2026, 7, 27),
      ], snapshot: snapshot);

      // Days are sorted, so the out-of-semester date lands first.
      expect(plan.days.first.state, AttendanceDayState.outsideSemester);
      expect(plan.days.first.isOutsideSemester, isTrue);
      expect(plan.days.first.skippableSessions, isEmpty);
      expect(plan.days.last.state, AttendanceDayState.holiday);
      expect(plan.days.last.isExcluded, isTrue);
      expect(plan.days.last.skippableSessions, isEmpty);
      expect(plan.contributingDayCount, 0);
      expect(plan.skippedClassCount, 0);
      expect(plan.overallProjected.heldClasses, 16);
    });

    test('archived subjects stay out of the plan and the totals', () {
      final snapshot = _snapshot(
        subjects: [..._subjects, _archivedSubject],
        timetable: [..._timetable, _slot(4, subjectId: 3)],
      );
      final plan = _plan([DateTime(2026, 8, 17)], snapshot: snapshot);

      expect(plan.days.single.skippableCount, 2);
      expect(plan.subjects.map((impact) => impact.subject.id), [1, 2]);
      expect(plan.overallCurrent.heldClasses, 16);
    });

    test('no chosen days leaves attendance untouched', () {
      final plan = _plan(const []);
      expect(plan.days, isEmpty);
      expect(plan.changesAnything, isFalse);
      expect(
        plan.overallProjected.heldClasses,
        plan.overallCurrent.heldClasses,
      );
    });

    test('summary explains an empty plan without numbers', () {
      expect(
        _plan(const []).summaryMessage,
        'No unmarked classes fall on these days, so your attendance does not change yet.',
      );
    });

    test('summary states the cost and the resulting standing', () {
      final message = _plan([DateTime(2026, 8, 17)]).summaryMessage;
      expect(message, contains('Missing 2 classes over 1 day'));
      expect(message, contains('leaves overall attendance at 66.7%'));
      expect(message, contains('You would fall below 75%.'));
    });
  });

  group('overall metrics', () {
    test('combine every subject and honor the caller target', () {
      final results = AttendanceScheduleEngine.subjectResults(
        snapshot: _snapshot(),
        semester: _semester,
      );
      final overall = AttendancePlannerService.overallMetrics(
        subjects: results,
        target: .8,
      );

      expect(overall.presentCount, 12);
      expect(overall.absentCount, 4);
      expect(overall.heldClasses, 16);
      expect(overall.attendancePercentage, closeTo(75, .001));
      expect(overall.isAtOrAboveTarget, isFalse);
      expect(overall.classesRequired, 4);
    });

    test('fall back to the default target when the caller is unusable', () {
      final overall = AttendancePlannerService.overallMetrics(
        subjects: const [],
        target: 0,
      );
      expect(overall.target, .75);
      expect(overall.hasClasses, isFalse);
    });
  });
}

SkipDayPlan _plan(
  List<DateTime> dates, {
  AttendanceEngineSnapshot? snapshot,
  double overallTarget = .75,
}) {
  final engine = snapshot ?? _snapshot();
  return AttendancePlannerService.planSkipDays(
    snapshot: engine,
    semester: _semester,
    dates: dates,
    subjectResults: AttendanceScheduleEngine.subjectResults(
      snapshot: engine,
      semester: _semester,
    ),
    overallTarget: overallTarget,
  );
}

final _now = DateTime.utc(2026, 8, 1);

final _semester = (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 12, 20),
  isActive: true,
  createdAt: _now,
  updatedAt: _now,
);

Subject _subject({
  required int id,
  required String name,
  required String shortCode,
  bool isArchived = false,
}) => (
  id: id,
  semesterId: 1,
  name: name,
  shortCode: shortCode,
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4758D6,
  isArchived: isArchived,
  createdAt: _now,
  updatedAt: _now,
);

final _math = _subject(id: 1, name: 'Mathematics', shortCode: 'MATH');
final _physics = _subject(id: 2, name: 'Physics', shortCode: 'PHY');
final _archivedSubject = _subject(
  id: 3,
  name: 'Retired Elective',
  shortCode: 'RET',
  isArchived: true,
);
final _subjects = [_math, _physics];

/// Monday 9:00 Maths, Monday 10:00 Physics, Tuesday 9:00 Maths.
final _timetable = <AttendanceTimetableSlot>[
  _slot(1),
  _slot(2, subjectId: 2, start: 600),
  _slot(3, weekday: DateTime.tuesday),
];

/// Nine attended and three missed Maths classes, plus Physics at 3 and 1.
final _history = <ExplicitClassAttendance>[
  for (var index = 0; index < 9; index++)
    _record(100 + index, 1, 3 + index, ClassAttendanceStatus.present),
  for (var index = 0; index < 3; index++)
    _record(200 + index, 1, 12 + index, ClassAttendanceStatus.absent),
  for (var index = 0; index < 3; index++)
    _record(300 + index, 2, 3 + index, ClassAttendanceStatus.present),
  _record(400, 2, 6, ClassAttendanceStatus.absent),
];

AttendanceEngineSnapshot _snapshot({
  List<Subject>? subjects,
  List<AttendanceTimetableSlot>? timetable,
  List<ExplicitClassAttendance>? attendance,
  List<DayOverride> overrides = const [],
}) => AttendanceEngineSnapshot(
  subjects: subjects ?? _subjects,
  timetable: timetable ?? _timetable,
  attendance: attendance ?? _history,
  overrides: overrides,
);

AttendanceTimetableSlot _slot(
  int id, {
  int subjectId = 1,
  int weekday = DateTime.monday,
  int start = 540,
}) => (
  id: id,
  semesterId: 1,
  subjectId: subjectId,
  weekday: weekday,
  startTime: start,
  endTime: start + 60,
  effectiveFrom: null,
  effectiveUntil: null,
);

ExplicitClassAttendance _record(
  int id,
  int subjectId,
  int day,
  ClassAttendanceStatus status, {
  int? timetableEntryId,
}) => (
  id: id,
  semesterId: 1,
  timetableEntryId: timetableEntryId,
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

DayOverride _override(CalendarDayOverrideType type) =>
    (id: 1, semesterId: 1, date: DateTime(2026, 8, 17), type: type, note: '');
