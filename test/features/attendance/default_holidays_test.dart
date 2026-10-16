import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The derived-holiday rules: Sundays, second Saturdays and the three fixed
/// national dates are holidays without a stored calendar row, and an explicit
/// `normal` day override puts a single date back to work.
void main() {
  group('default holiday policy', () {
    test('Sunday excludes its classes and names the holiday', () {
      final day = _day(_snapshot(), DateTime(2026, 8, 23));

      expect(day.state, AttendanceDayState.holiday);
      expect(day.sessions, isEmpty);
      expect(day.override?.note, 'Sunday');
    });

    test('with Sundays off, a Sunday timetable slot stays hidden', () {
      // A class can be scheduled on a Sunday; the rule is what excludes it.
      final day = _day(_snapshot(), DateTime(2026, 8, 23));

      expect(day.state, AttendanceDayState.holiday);
      expect(day.sessions, isEmpty);
    });

    test('turning Sunday off projects the slot normally again', () {
      final day = _day(
        _snapshot(policy: const DefaultHolidayPolicy()),
        DateTime(2026, 8, 23),
      );

      expect(day.state, AttendanceDayState.unmarked);
      expect(day.sessions, hasLength(1));
    });

    test('second Saturday excludes its classes, first Saturday does not', () {
      final policy = const DefaultHolidayPolicy(secondSaturdayOff: true);

      // 1 August 2026 and 8 August 2026 are the first and second Saturdays.
      expect(
        _day(_snapshot(policy: policy), DateTime(2026, 8, 1)).state,
        AttendanceDayState.unmarked,
      );
      final second = _day(_snapshot(policy: policy), DateTime(2026, 8, 8));
      expect(second.state, AttendanceDayState.holiday);
      expect(second.override?.note, 'Second Saturday');
      expect(second.sessions, isEmpty);
    });

    test('second Saturday rule can be turned off on its own', () {
      final day = _day(
        _snapshot(policy: const DefaultHolidayPolicy(sundayOff: true)),
        DateTime(2026, 8, 8),
      );

      expect(day.state, AttendanceDayState.unmarked);
      expect(day.sessions, hasLength(1));
    });

    test('the three fixed national dates are holidays every year', () {
      final policy = const DefaultHolidayPolicy(governmentHolidaysOff: true);

      expect(
        _day(_snapshot(policy: policy), DateTime(2027, 1, 26)).override?.note,
        'Republic Day',
      );
      // 15 August 2026 is also a Saturday, and the national rule names it
      // because it is not the second Saturday of the month.
      expect(
        _day(_snapshot(policy: policy), DateTime(2026, 8, 15)).override?.note,
        'Independence Day',
      );
      expect(
        _day(_snapshot(policy: policy), DateTime(2026, 10, 2)).override?.note,
        'Gandhi Jayanti',
      );
    });

    test(
      'an explicit normal override makes a default holiday a working day',
      () {
        final day = _day(
          _snapshot(
            overrides: [
              (
                id: 4,
                semesterId: 1,
                date: DateTime(2026, 8, 23),
                type: CalendarDayOverrideType.normal,
                note: 'Makeup class',
              ),
            ],
          ),
          DateTime(2026, 8, 23),
        );

        expect(day.state, AttendanceDayState.unmarked);
        expect(day.sessions, hasLength(1));
      },
    );

    test('a stored holiday override is unaffected by the rules', () {
      final day = _day(
        _snapshot(
          overrides: [
            (
              id: 5,
              semesterId: 1,
              date: DateTime(2026, 8, 24),
              type: CalendarDayOverrideType.holiday,
              note: 'Local festival',
            ),
          ],
        ),
        DateTime(2026, 8, 24),
      );

      expect(day.state, AttendanceDayState.holiday);
      expect(day.override?.note, 'Local festival');
    });
  });

  group('default holidays in the linked views', () {
    test('next class skips a second Saturday and a national holiday', () {
      final result = AttendanceAwareNextClassService.calculate(
        snapshot: _snapshot(),
        semester: _semester,
        now: DateTime(2026, 8, 8, 8),
      );

      // 8 August is the second Saturday and 15 August is Independence Day, so
      // the next eligible class is the Saturday after both.
      expect(result.daysUntilNext, 14);
    });

    test('excluded days are listed per subject without touching marks', () {
      final results = AttendanceScheduleEngine.subjectResults(
        snapshot: _snapshot(),
        semester: _semester,
      );

      final excluded = results.single.excludedDays
          .map((day) => day.date)
          .toList(growable: false);
      expect(excluded, contains(DateTime(2026, 8, 8)));
      expect(excluded, contains(DateTime(2026, 8, 15)));
      expect(excluded, contains(DateTime(2026, 8, 23)));
      // Percentages count explicit marks only, so nothing is invented here.
      expect(results.single.metrics.attendancePercentage, isNull);
    });

    test('pending groups never ask about a default holiday', () {
      final groups = AttendanceScheduleEngine.pendingGroups(
        snapshot: _snapshot(),
        semester: _semester,
        through: DateTime(2026, 8, 31),
      );

      expect(
        groups.any((group) => group.date == DateTime(2026, 8, 8)),
        isFalse,
      );
      expect(
        groups.any((group) => group.date == DateTime(2026, 8, 15)),
        isFalse,
      );
      expect(groups.any((group) => group.date == DateTime(2026, 8, 1)), isTrue);
    });
  });
}

AttendanceDay _day(AttendanceEngineSnapshot snapshot, DateTime date) =>
    AttendanceScheduleEngine.day(
      snapshot: snapshot,
      semester: _semester,
      date: date,
    );

/// A semester with a Saturday class and a Sunday class.
///
/// Both are scheduled so the tests can prove the rules, not the timetable, are
/// what exclude a day: turning a rule off has to bring the class straight back.
AttendanceEngineSnapshot _snapshot({
  DefaultHolidayPolicy policy = const DefaultHolidayPolicy(
    sundayOff: true,
    secondSaturdayOff: true,
    governmentHolidaysOff: true,
  ),
  List<DayOverride> overrides = const [],
}) => AttendanceEngineSnapshot(
  subjects: [_subject],
  timetable: [
    (
      id: 1,
      semesterId: 1,
      subjectId: 1,
      weekday: DateTime.saturday,
      startTime: 540,
      endTime: 600,
      effectiveFrom: DateTime(2026, 7, 1),
      effectiveUntil: DateTime(2026, 9, 30),
    ),
    (
      id: 2,
      semesterId: 1,
      subjectId: 1,
      weekday: DateTime.sunday,
      startTime: 600,
      endTime: 660,
      effectiveFrom: DateTime(2026, 7, 1),
      effectiveUntil: DateTime(2026, 9, 30),
    ),
  ],
  attendance: const [],
  overrides: overrides,
  defaultHolidays: policy,
);

final Semester _semester = (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 31),
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final Subject _subject = (
  id: 1,
  semesterId: 1,
  name: 'Mathematics',
  shortCode: 'MATH',
  professor: '',
  room: 'A-1',
  attendanceTarget: .75,
  displayColor: 0xFF4F8CFF,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
