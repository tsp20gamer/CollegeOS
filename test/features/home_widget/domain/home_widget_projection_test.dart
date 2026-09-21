import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/home_widget/domain/home_widget_projection.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 13, 10, 0);
  final subject = _subject();

  test('projects a current class and mixed attendance', () {
    final current = ScheduledClass(entry: _entry(), subject: subject);
    final projection = HomeWidgetProjectionBuilder.build(
      now: now,
      nextClass: NextClassResult(
        currentClasses: [current],
        nextClass: null,
        daysUntilNext: null,
      ),
      attendanceDay: AttendanceDay(
        date: now,
        state: AttendanceDayState.partial,
        sessions: [
          _session(subject, ClassAttendanceStatus.present, 570),
          _session(subject, ClassAttendanceStatus.absent, 630),
          _session(subject, ClassAttendanceStatus.unmarked, 690),
          _session(subject, ClassAttendanceStatus.cancelled, 750),
        ],
        override: null,
        isInsideSemester: true,
      ),
    );

    expect(projection.classLabel, 'HAPPENING NOW');
    expect(projection.classTitle, 'Mathematics');
    expect(projection.classTime, 'Until 10:30 AM');
    expect(projection.classMeta, 'A-201 · Dr Rao');
    expect(projection.attendanceSummary, '1 present · 1 absent');
    expect(projection.attendanceMeta, '1 unmarked · 1 cancelled');
    expect(projection.attendanceStatus, '1 pending');
    expect(projection.attendanceProgress, 67);
    expect(projection.dateKey, '2026-08-13');
  });

  test('projects tomorrow next class when nothing is current', () {
    final upcoming = ScheduledClass(entry: _entry(), subject: subject);
    final projection = HomeWidgetProjectionBuilder.build(
      now: now,
      nextClass: NextClassResult(
        currentClasses: const [],
        nextClass: upcoming,
        daysUntilNext: 1,
      ),
      attendanceDay: null,
    );

    expect(projection.classLabel, 'NEXT CLASS');
    expect(projection.classTime, 'Tomorrow · 9:30 AM');
    expect(projection.attendanceSummary, 'No active semester');
  });

  test('projects holiday without counting scheduled classes', () {
    final current = ScheduledClass(entry: _entry(), subject: subject);
    final projection = HomeWidgetProjectionBuilder.build(
      now: now,
      nextClass: NextClassResult(
        currentClasses: [current],
        nextClass: null,
        daysUntilNext: null,
      ),
      attendanceDay: AttendanceDay(
        date: now,
        state: AttendanceDayState.holiday,
        sessions: [_session(subject, ClassAttendanceStatus.absent, 570)],
        override: (
          id: 1,
          semesterId: 1,
          date: now,
          type: CalendarDayOverrideType.holiday,
          note: 'Independence Day',
        ),
        isInsideSemester: true,
      ),
    );

    expect(projection.attendanceSummary, 'Holiday');
    expect(projection.attendanceStatus, 'Holiday');
    expect(projection.attendanceProgress, 100);
    expect(projection.attendanceMeta, 'Independence Day');
    expect(projection.classLabel, 'TODAY');
    expect(projection.classTitle, 'Holiday');
    expect(projection.classTime, 'No classes scheduled');
  });
}

Subject _subject() => (
  id: 1,
  semesterId: 1,
  name: 'Mathematics',
  shortCode: 'MATH',
  professor: 'Dr Rao',
  room: 'A-101',
  attendanceTarget: 0.75,
  displayColor: 0xFF4758D6,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

TimetableEntry _entry() => (
  id: 1,
  semesterId: 1,
  subjectId: 1,
  weekday: DateTime.thursday,
  startTime: 570,
  endTime: 630,
  room: 'A-201',
  note: '',
);

ProjectedClassSession _session(
  Subject subject,
  ClassAttendanceStatus status,
  int startTime,
) => ProjectedClassSession(
  date: DateTime(2026, 8, 13),
  subject: subject,
  startTime: startTime,
  endTime: startTime + 60,
  status: status,
  note: '',
  manuallyModified: false,
);
