import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('skips a cancelled class and selects the next class today', () {
    final snapshot = _snapshot(
      attendance: [
        _record(
          timetableId: 1,
          date: DateTime(2026, 8, 24),
          status: ClassAttendanceStatus.cancelled,
        ),
      ],
    );
    final result = AttendanceAwareNextClassService.calculate(
      snapshot: snapshot,
      semester: _semester,
      now: DateTime(2026, 8, 24, 8, 30),
    );

    expect(result.nextClass?.entry.id, 2);
    expect(result.daysUntilNext, 0);
  });

  test('one-day extra class is selected before the next weekly class', () {
    final snapshot = _snapshot(
      extra: (
        id: 3,
        semesterId: 1,
        subjectId: 1,
        weekday: DateTime.tuesday,
        startTime: 480,
        endTime: 540,
        effectiveFrom: DateTime(2026, 8, 25),
        effectiveUntil: DateTime(2026, 8, 25),
      ),
    );
    final result = AttendanceAwareNextClassService.calculate(
      snapshot: snapshot,
      semester: _semester,
      now: DateTime(2026, 8, 24, 18),
    );

    expect(result.nextClass?.entry.id, 3);
    expect(result.daysUntilNext, 1);
  });

  test('holiday masks all classes for next-class projection', () {
    final snapshot = _snapshot(
      overrides: [
        (
          id: 1,
          semesterId: 1,
          date: DateTime(2026, 8, 24),
          type: CalendarDayOverrideType.holiday,
          note: '',
        ),
      ],
    );
    final result = AttendanceAwareNextClassService.calculate(
      snapshot: snapshot,
      semester: _semester,
      now: DateTime(2026, 8, 24, 8),
    );

    expect(result.nextClass, isNull);
  });
}

AttendanceEngineSnapshot _snapshot({
  List<ExplicitClassAttendance> attendance = const [],
  List<DayOverride> overrides = const [],
  AttendanceTimetableSlot? extra,
}) => AttendanceEngineSnapshot(
  subjects: [_subject],
  timetable: [
    (
      id: 1,
      semesterId: 1,
      subjectId: 1,
      weekday: DateTime.monday,
      startTime: 540,
      endTime: 600,
      effectiveFrom: DateTime(2026, 8, 1),
      effectiveUntil: DateTime(2026, 8, 24),
    ),
    (
      id: 2,
      semesterId: 1,
      subjectId: 1,
      weekday: DateTime.monday,
      startTime: 660,
      endTime: 720,
      effectiveFrom: DateTime(2026, 8, 1),
      effectiveUntil: DateTime(2026, 8, 24),
    ),
    ?extra,
  ],
  attendance: attendance,
  overrides: overrides,
);

ExplicitClassAttendance _record({
  required int timetableId,
  required DateTime date,
  required ClassAttendanceStatus status,
}) => (
  id: 1,
  semesterId: 1,
  timetableEntryId: timetableId,
  subjectId: 1,
  date: date,
  startTime: 540,
  endTime: 600,
  status: status,
  note: '',
  manuallyModified: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
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
