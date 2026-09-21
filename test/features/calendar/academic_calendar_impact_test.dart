import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/calendar/domain/academic_calendar_impact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts timetable classes affected by a calendar range', () {
    final impact = AcademicCalendarImpactService.calculate(
      snapshot: AttendanceEngineSnapshot(
        subjects: [_subject],
        timetable: [_slot(1, DateTime.monday), _slot(2, DateTime.tuesday)],
        attendance: const [],
        overrides: const [],
      ),
      semester: _semester,
      startDate: DateTime(2026, 8, 17),
      endDate: DateTime(2026, 8, 23),
    );
    expect(impact.calendarDays, 7);
    expect(impact.classDays, 2);
    expect(impact.scheduledClasses, 2);
  });

  test('clips impact to semester boundaries', () {
    final impact = AcademicCalendarImpactService.calculate(
      snapshot: AttendanceEngineSnapshot(
        subjects: [_subject],
        timetable: [_slot(1, DateTime.monday)],
        attendance: const [],
        overrides: const [],
      ),
      semester: _semester,
      startDate: DateTime(2025),
      endDate: DateTime(2025, 1, 2),
    );
    expect(impact.calendarDays, 0);
    expect(impact.scheduledClasses, 0);
  });
}

final _semester = (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 13),
  endDate: DateTime(2026, 12, 15),
  isActive: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

final _subject = (
  id: 1,
  semesterId: 1,
  name: 'Mathematics',
  shortCode: 'MATH',
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

AttendanceTimetableSlot _slot(int id, int weekday) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  weekday: weekday,
  startTime: 540,
  endTime: 600,
  effectiveFrom: _semester.startDate,
  effectiveUntil: _semester.endDate,
);
