import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/reports/domain/attendance_report.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('week report counts class records and excludes holiday ranges', () {
    final report = AttendanceReportService.build(
      snapshot: AttendanceEngineSnapshot(
        subjects: [_subject],
        timetable: [
          _slot(1, DateTime.monday),
          _slot(2, DateTime.tuesday),
          _slot(3, DateTime.wednesday),
        ],
        attendance: [
          _mark(1, 1, 17, ClassAttendanceStatus.present),
          _mark(2, 2, 18, ClassAttendanceStatus.absent),
          _mark(3, 3, 19, ClassAttendanceStatus.present),
        ],
        overrides: const [],
        calendarEvents: [
          (
            id: 1,
            semesterId: 1,
            title: 'Holiday',
            type: AcademicCalendarEventType.holiday,
            startDate: DateTime(2026, 8, 19),
            endDate: DateTime(2026, 8, 19),
            note: '',
          ),
        ],
      ),
      semester: _semester,
      startDate: DateTime(2026, 8, 17),
      endDate: DateTime(2026, 8, 23),
      asOf: DateTime(2026, 8, 24),
    );

    expect(report.present, 1);
    expect(report.absent, 1);
    expect(report.held, 2);
    expect(report.percentage, 50);
  });

  test('month and subject filter keep ended unmarked classes explicit', () {
    final report = AttendanceReportService.build(
      snapshot: AttendanceEngineSnapshot(
        subjects: [_subject, _otherSubject],
        timetable: [_slot(1, DateTime.monday)],
        attendance: const [],
        overrides: const [],
      ),
      semester: _semester,
      startDate: DateTime(2026, 8),
      endDate: DateTime(2026, 8, 31),
      asOf: DateTime(2026, 8, 18),
      subjectId: _subject.id,
    );

    expect(report.rows, hasLength(1));
    expect(report.rows.single.subjectId, _subject.id);
    expect(report.unmarked, 1);
    expect(report.percentage, isNull);
  });

  test('range helpers use Monday weeks and real calendar month ends', () {
    final week = AttendanceReportService.weekContaining(DateTime(2026, 8, 20));
    expect(week.start, DateTime(2026, 8, 17));
    expect(week.end, DateTime(2026, 8, 23));
    final month = AttendanceReportService.monthContaining(DateTime(2028, 2, 5));
    expect(month.start, DateTime(2028, 2, 1));
    expect(month.end, DateTime(2028, 2, 29));
  });

  test('combined overall percentage is weighted by held classes', () {
    final first = AttendanceReportData(
      startDate: _reportStart,
      endDate: _reportEnd,
      rows: [
        SubjectAttendanceReportRow(
          semesterId: 1,
          semesterName: 'Semester 1',
          subjectId: 1,
          subjectName: 'Mathematics',
          shortCode: 'MATH',
          present: 9,
          absent: 1,
          cancelled: 0,
          unmarked: 0,
          target: .75,
        ),
      ],
    );
    final second = AttendanceReportData(
      startDate: _reportStart,
      endDate: _reportEnd,
      rows: [
        SubjectAttendanceReportRow(
          semesterId: 2,
          semesterName: 'Semester 2',
          subjectId: 2,
          subjectName: 'Programming',
          shortCode: 'C',
          present: 1,
          absent: 1,
          cancelled: 0,
          unmarked: 0,
          target: .75,
        ),
      ],
    );
    final combined = AttendanceReportService.combine([first, second]);
    expect(combined.present, 10);
    expect(combined.held, 12);
    expect(combined.percentage, closeTo(83.333, .001));
  });
}

final _reportStart = DateTime(2026, 8, 1);
final _reportEnd = DateTime(2026, 8, 31);

final Semester _semester = (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 13),
  endDate: DateTime(2026, 12, 15),
  isActive: true,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

final Subject _subject = (
  id: 1,
  semesterId: 1,
  name: 'Mathematics',
  shortCode: 'MATH',
  professor: 'Professor Rao',
  room: 'A-101',
  attendanceTarget: 0.75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

final Subject _otherSubject = (
  id: 2,
  semesterId: 1,
  name: 'English',
  shortCode: 'ENG',
  professor: '',
  room: '',
  attendanceTarget: 0.75,
  displayColor: 0xFF208A5D,
  isArchived: false,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);

AttendanceTimetableSlot _slot(int id, int weekday) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  weekday: weekday,
  startTime: 540,
  endTime: 600,
  effectiveFrom: null,
  effectiveUntil: null,
);

ExplicitClassAttendance _mark(
  int id,
  int timetableId,
  int day,
  ClassAttendanceStatus status,
) => (
  id: id,
  semesterId: 1,
  timetableEntryId: timetableId,
  subjectId: 1,
  date: DateTime(2026, 8, day),
  startTime: 540,
  endTime: 600,
  status: status,
  note: '',
  manuallyModified: true,
  createdAt: DateTime(2026, 8, day),
  updatedAt: DateTime(2026, 8, day),
);
