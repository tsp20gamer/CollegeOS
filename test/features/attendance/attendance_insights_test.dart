import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_insights.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates present streaks and perfect days from class records', () {
    final semester = _semester();
    final subject = _subject();
    final snapshot = AttendanceEngineSnapshot(
      subjects: [subject],
      timetable: [
        for (var weekday = 1; weekday <= 5; weekday++)
          (
            id: weekday,
            semesterId: 1,
            subjectId: 1,
            weekday: weekday,
            startTime: 540,
            endTime: 600,
            effectiveFrom: DateTime(2026, 8, 3),
            effectiveUntil: DateTime(2026, 8, 31),
          ),
      ],
      attendance: [
        _record(1, DateTime(2026, 8, 3), ClassAttendanceStatus.present),
        _record(2, DateTime(2026, 8, 4), ClassAttendanceStatus.present),
        _record(3, DateTime(2026, 8, 5), ClassAttendanceStatus.absent),
        _record(4, DateTime(2026, 8, 6), ClassAttendanceStatus.present),
        _record(5, DateTime(2026, 8, 7), ClassAttendanceStatus.present),
      ],
      overrides: const [],
    );

    final insights = AttendanceInsightsService.calculate(
      snapshot: snapshot,
      semester: semester,
      asOf: DateTime(2026, 8, 7, 18),
    );

    expect(insights.markedClasses, 5);
    expect(insights.currentPresentStreak, 2);
    expect(insights.longestPresentStreak, 2);
    expect(insights.perfectDays, 4);
    expect(insights.bestSubjectName, 'Mathematics');
    expect(insights.bestSubjectStreak, 2);
  });

  test('holiday records are excluded from streaks and perfect days', () {
    final snapshot = AttendanceEngineSnapshot(
      subjects: [_subject()],
      timetable: [
        (
          id: 1,
          semesterId: 1,
          subjectId: 1,
          weekday: DateTime.monday,
          startTime: 540,
          endTime: 600,
          effectiveFrom: DateTime(2026, 8, 1),
          effectiveUntil: DateTime(2026, 8, 31),
        ),
      ],
      attendance: [
        _record(1, DateTime(2026, 8, 3), ClassAttendanceStatus.present),
      ],
      overrides: [
        (
          id: 1,
          semesterId: 1,
          date: DateTime(2026, 8, 3),
          type: CalendarDayOverrideType.holiday,
          note: '',
        ),
      ],
    );

    final insights = AttendanceInsightsService.calculate(
      snapshot: snapshot,
      semester: _semester(),
      asOf: DateTime(2026, 8, 3, 18),
    );

    expect(insights.hasData, isFalse);
    expect(insights.perfectDays, 0);
  });
}

Semester _semester() => (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 12, 20),
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Subject _subject() => (
  id: 1,
  semesterId: 1,
  name: 'Mathematics',
  shortCode: 'MATH',
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF4F8CFF,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ExplicitClassAttendance _record(
  int id,
  DateTime date,
  ClassAttendanceStatus status,
) => (
  id: id,
  semesterId: 1,
  timetableEntryId: date.day - 2,
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
