import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timetable projection', () {
    test('generates Monday and Tuesday but not a weekend without entries', () {
      final snapshot = _snapshot(timetable: [_slot(1), _slot(2, weekday: 2)]);
      expect(_day(snapshot, DateTime(2026, 8, 17)).sessions, hasLength(1));
      expect(_day(snapshot, DateTime(2026, 8, 18)).sessions, hasLength(1));
      expect(
        _day(snapshot, DateTime(2026, 8, 16)).state,
        AttendanceDayState.noClasses,
      );
    });

    test('does not generate outside semester boundaries', () {
      final snapshot = _snapshot(timetable: [_slot(1)]);
      expect(
        _day(snapshot, DateTime(2026, 7, 27)).state,
        AttendanceDayState.outsideSemester,
      );
      expect(
        _day(snapshot, DateTime(2026, 12, 21)).state,
        AttendanceDayState.outsideSemester,
      );
    });

    test('effective timetable versions preserve historical schedules', () {
      final snapshot = _snapshot(
        subjects: [_subject, _physics],
        timetable: [
          _slot(
            1,
            effectiveFrom: DateTime(2026, 8, 1),
            effectiveUntil: DateTime(2026, 9, 30),
          ),
          _slot(2, subjectId: 2, effectiveFrom: DateTime(2026, 10, 1)),
        ],
      );
      expect(
        _day(snapshot, DateTime(2026, 9, 28)).sessions.single.subject.name,
        'Mathematics',
      );
      expect(
        _day(snapshot, DateTime(2026, 10, 5)).sessions.single.subject.name,
        'Physics',
      );
    });
  });

  group('linked day actions and summaries', () {
    test('unmarked classes stay unmarked', () {
      final day = _day(_snapshot(timetable: [_slot(1)]), DateTime(2026, 8, 17));
      expect(day.state, AttendanceDayState.unmarked);
      expect(day.unmarkedCount, 1);
    });

    test('all present and all absent derive whole-day states', () {
      final timetable = [_slot(1), _slot(2, start: 600)];
      expect(
        _day(
          _snapshot(
            timetable: timetable,
            attendance: [
              _mark(1, ClassAttendanceStatus.present),
              _mark(2, ClassAttendanceStatus.present, start: 600),
            ],
          ),
          DateTime(2026, 8, 17),
        ).state,
        AttendanceDayState.present,
      );
      expect(
        _day(
          _snapshot(
            timetable: timetable,
            attendance: [
              _mark(1, ClassAttendanceStatus.absent),
              _mark(2, ClassAttendanceStatus.absent, start: 600),
            ],
          ),
          DateTime(2026, 8, 17),
        ).state,
        AttendanceDayState.absent,
      );
    });

    test('whole-day present changed to one absent becomes partial', () {
      final day = _day(
        _snapshot(
          timetable: [_slot(1), _slot(2, start: 600)],
          attendance: [
            _mark(1, ClassAttendanceStatus.present),
            _mark(2, ClassAttendanceStatus.absent, start: 600),
          ],
        ),
        DateTime(2026, 8, 17),
      );
      expect(day.state, AttendanceDayState.partial);
    });

    test('one marked and one unmarked is partially marked', () {
      final day = _day(
        _snapshot(
          timetable: [_slot(1), _slot(2, start: 600)],
          attendance: [_mark(1, ClassAttendanceStatus.present)],
        ),
        DateTime(2026, 8, 17),
      );
      expect(day.state, AttendanceDayState.partiallyMarked);
    });

    test('multiple same-subject classes remain separate', () {
      final day = _day(
        _snapshot(timetable: [_slot(1), _slot(2, start: 600)]),
        DateTime(2026, 8, 17),
      );
      expect(day.sessions, hasLength(2));
      expect(day.sessions.map((item) => item.startTime), [540, 600]);
    });

    test('cancelled does not become an absent class', () {
      final snapshot = _snapshot(
        timetable: [_slot(1), _slot(2, start: 600)],
        attendance: [
          _mark(1, ClassAttendanceStatus.present),
          _mark(2, ClassAttendanceStatus.cancelled, start: 600),
        ],
      );
      final result = AttendanceScheduleEngine.subjectResults(
        snapshot: snapshot,
        semester: _semester,
      ).single;
      expect(result.metrics.presentCount, 1);
      expect(result.metrics.absentCount, 0);
      expect(result.metrics.cancelledCount, 1);
    });

    test(
      'holiday excludes marks and undo makes preserved marks count again',
      () {
        final marked = _mark(1, ClassAttendanceStatus.present);
        final holidaySnapshot = _snapshot(
          timetable: [_slot(1)],
          attendance: [marked],
          overrides: [_override(CalendarDayOverrideType.holiday)],
        );
        final holidayDay = _day(holidaySnapshot, DateTime(2026, 8, 17));
        expect(holidayDay.state, AttendanceDayState.holiday);
        expect(holidayDay.sessions, isEmpty);
        final holidayResult = AttendanceScheduleEngine.subjectResults(
          snapshot: holidaySnapshot,
          semester: _semester,
        ).single;
        expect(holidayResult.metrics.heldClasses, 0);
        expect(holidayResult.excludedDays, hasLength(1));
        expect(
          holidayResult.excludedDays.single.type,
          CalendarDayOverrideType.holiday,
        );
        final undone = _snapshot(timetable: [_slot(1)], attendance: [marked]);
        final undoneDay = _day(undone, DateTime(2026, 8, 17));
        expect(undoneDay.sessions, hasLength(1));
        expect(undoneDay.sessions.single.status, ClassAttendanceStatus.present);
        final undoneResult = AttendanceScheduleEngine.subjectResults(
          snapshot: undone,
          semester: _semester,
        ).single;
        expect(undoneResult.metrics.presentCount, 1);
        expect(undoneResult.excludedDays, isEmpty);
      },
    );
  });

  group('subject calculations', () {
    test('calendar marks update percentage and safe bunks', () {
      final attendance = <ExplicitClassAttendance>[
        for (var index = 0; index < 18; index++)
          _mark(index + 1, ClassAttendanceStatus.present, day: index + 1),
        for (var index = 18; index < 22; index++)
          _mark(index + 1, ClassAttendanceStatus.absent, day: index + 1),
      ];
      final metrics = AttendanceScheduleEngine.subjectResults(
        snapshot: _snapshot(attendance: attendance),
        semester: _semester,
      ).single.metrics;
      expect(metrics.attendancePercentage, closeTo(81.818, 0.001));
      expect(metrics.safeBunks, 2);
    });

    test('below target reports required consecutive classes', () {
      final attendance = <ExplicitClassAttendance>[
        for (var index = 0; index < 14; index++)
          _mark(index + 1, ClassAttendanceStatus.present, day: index + 1),
        for (var index = 14; index < 21; index++)
          _mark(index + 1, ClassAttendanceStatus.absent, day: index + 1),
      ];
      final metrics = AttendanceScheduleEngine.subjectResults(
        snapshot: _snapshot(attendance: attendance),
        semester: _semester,
      ).single.metrics;
      expect(metrics.attendancePercentage, closeTo(66.666, 0.001));
      expect(metrics.classesRequired, 7);
    });
  });
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
final _subject = (
  id: 1,
  semesterId: 1,
  name: 'Mathematics',
  shortCode: 'MATH',
  professor: 'Professor Rao',
  room: 'A-101',
  attendanceTarget: 0.75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: _now,
  updatedAt: _now,
);
final _physics = (
  id: 2,
  semesterId: 1,
  name: 'Physics',
  shortCode: 'PHY',
  professor: 'Professor Sen',
  room: 'Lab',
  attendanceTarget: 0.75,
  displayColor: 0xFF208A5D,
  isArchived: false,
  createdAt: _now,
  updatedAt: _now,
);

AttendanceEngineSnapshot _snapshot({
  List<dynamic>? subjects,
  List<AttendanceTimetableSlot> timetable = const [],
  List<ExplicitClassAttendance> attendance = const [],
  List<DayOverride> overrides = const [],
}) => AttendanceEngineSnapshot(
  subjects: (subjects ?? [_subject]).cast(),
  timetable: timetable,
  attendance: attendance,
  overrides: overrides,
);

AttendanceTimetableSlot _slot(
  int id, {
  int subjectId = 1,
  int weekday = DateTime.monday,
  int start = 540,
  DateTime? effectiveFrom,
  DateTime? effectiveUntil,
}) => (
  id: id,
  semesterId: 1,
  subjectId: subjectId,
  weekday: weekday,
  startTime: start,
  endTime: start + 60,
  effectiveFrom: effectiveFrom,
  effectiveUntil: effectiveUntil,
);

ExplicitClassAttendance _mark(
  int id,
  ClassAttendanceStatus status, {
  int day = 17,
  int start = 540,
}) => (
  id: id,
  semesterId: 1,
  timetableEntryId: id,
  subjectId: 1,
  date: DateTime(2026, 8, day),
  startTime: start,
  endTime: start + 60,
  status: status,
  note: '',
  manuallyModified: true,
  createdAt: _now,
  updatedAt: _now,
);

DayOverride _override(CalendarDayOverrideType type) =>
    (id: 1, semesterId: 1, date: DateTime(2026, 8, 17), type: type, note: '');

AttendanceDay _day(AttendanceEngineSnapshot snapshot, DateTime date) =>
    AttendanceScheduleEngine.day(
      snapshot: snapshot,
      semester: _semester,
      date: date,
    );
