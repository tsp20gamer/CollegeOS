import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/notifications/domain/class_reminder_plan.dart';
import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday, inside the semester.
  final now = DateTime(2026, 8, 10, 7, 30);

  test('projects one alarm for each class and nothing else', () {
    final reminders = _plan(
      now: now,
      entries: [
        _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, lead: 10),
        _entry(id: 2, weekday: DateTime.wednesday, start: 10 * 60, lead: 30),
        // No reminder chosen: never projected.
        _entry(id: 3, weekday: DateTime.tuesday, start: 11 * 60, lead: null),
      ],
    );

    expect(reminders, hasLength(2));
    expect(reminders.map((item) => item.entityId), [1, 2]);
    expect(
      reminders.every(
        (item) => item.type == NotificationEntityType.classReminder,
      ),
      isTrue,
    );
    final first = reminders.singleWhere((item) => item.entityId == 1);
    expect(first.scheduledAt, DateTime(2026, 8, 10, 8, 50));
    expect(first.title, 'Algorithms');
    // The locale's time format supplies its own separator space, so the test
    // pins the start time and the room instead of the exact spacing.
    expect(first.body, startsWith('Starts at 9:00'));
    expect(first.body, endsWith('• A-1'));
    expect(
      reminders.singleWhere((item) => item.entityId == 2).scheduledAt,
      DateTime(2026, 8, 12, 9, 30),
    );
  });

  test('skips holidays and college closures to the next occurrence', () {
    final reminders = _plan(
      now: now,
      entries: [
        _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, lead: 10),
      ],
      overrides: [
        (
          id: 1,
          semesterId: 1,
          date: DateTime(2026, 8, 10),
          type: CalendarDayOverrideType.holiday,
          note: 'Holiday',
        ),
        (
          id: 2,
          semesterId: 1,
          date: DateTime(2026, 8, 17),
          type: CalendarDayOverrideType.collegeClosed,
          note: 'Closure',
        ),
      ],
    );

    expect(reminders, hasLength(1));
    expect(
      reminders.single.scheduledAt,
      DateTime(2026, 8, 24, 8, 50),
      reason: 'the next two Mondays are a holiday and a closure',
    );
  });

  test('skips a cancelled class and keeps every other occurrence', () {
    final reminders = _plan(
      now: now,
      entries: [
        _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, lead: 10),
      ],
      attendance: [
        (
          id: 1,
          semesterId: 1,
          timetableEntryId: 1,
          subjectId: 1,
          date: DateTime(2026, 8, 10),
          startTime: 9 * 60,
          endTime: 10 * 60,
          status: ClassAttendanceStatus.cancelled,
          note: '',
          manuallyModified: false,
          createdAt: DateTime.utc(2026, 8, 10),
          updatedAt: DateTime.utc(2026, 8, 10),
        ),
      ],
    );

    expect(reminders, hasLength(1));
    expect(reminders.single.scheduledAt, DateTime(2026, 8, 17, 8, 50));
  });

  test('moves to the next occurrence once a reminder is in the past', () {
    final reminders = _plan(
      // Monday 09:05, so today's 08:50 reminder is gone.
      now: DateTime(2026, 8, 10, 9, 5),
      entries: [
        _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, lead: 10),
      ],
    );

    expect(reminders.single.scheduledAt, DateTime(2026, 8, 17, 8, 50));
  });

  test('supports at-start and long custom lead times', () {
    final reminders = _plan(
      now: now,
      entries: [
        _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, lead: 0),
        _entry(
          id: 2,
          weekday: DateTime.wednesday,
          start: 9 * 60,
          lead: 24 * 60,
        ),
      ],
    );

    expect(
      reminders.singleWhere((item) => item.entityId == 1).scheduledAt,
      DateTime(2026, 8, 10, 9),
    );
    expect(
      reminders.singleWhere((item) => item.entityId == 2).scheduledAt,
      DateTime(2026, 8, 11, 9),
      reason: 'a one-day lead is scheduled the previous morning',
    );
  });

  test('ignores archived subjects and classes past the semester end', () {
    final entry = _entry(
      id: 1,
      weekday: DateTime.friday,
      start: 9 * 60,
      lead: 10,
    );

    expect(_plan(now: now, entries: [entry], archived: true), isEmpty);

    expect(
      _plan(
        now: DateTime(2026, 8, 13, 7, 30),
        entries: [entry],
        semesterEnd: DateTime(2026, 8, 13),
      ),
      isEmpty,
      reason: 'the semester ends on Thursday, so Friday has no class',
    );
  });

  test('keeps the lookahead bounded while a long closure lasts', () {
    final closures = [
      for (var day = 0; day <= maxClassReminderLookaheadDays; day++)
        (
          id: day + 1,
          semesterId: 1,
          date: DateTime(2026, 8, 10).add(Duration(days: day)),
          type: CalendarDayOverrideType.holiday,
          note: 'Closure',
        ),
    ];

    expect(
      _plan(
        now: now,
        entries: [
          _entry(id: 1, weekday: DateTime.monday, start: 9 * 60, lead: 10),
        ],
        overrides: closures,
      ),
      isEmpty,
      reason: 'the next eligible occurrence is rebuilt on the next app run',
    );
  });
}

List<CollegeOsNotification> _plan({
  required DateTime now,
  required List<TimetableEntry> entries,
  List<ExplicitClassAttendance> attendance = const [],
  List<DayOverride> overrides = const [],
  bool archived = false,
  DateTime? semesterEnd,
}) => ClassReminderPlan.next(
  snapshot: AttendanceEngineSnapshot(
    subjects: [_subject(archived: archived)],
    timetable: [
      for (final entry in entries)
        (
          id: entry.id,
          semesterId: entry.semesterId,
          subjectId: entry.subjectId,
          weekday: entry.weekday,
          startTime: entry.startTime,
          endTime: entry.endTime,
          effectiveFrom: null,
          effectiveUntil: null,
        ),
    ],
    attendance: attendance,
    overrides: overrides,
  ),
  semester: semesterEnd == null ? _semester : _semesterEnding(semesterEnd),
  entries: entries,
  now: now,
);

Subject _subject({required bool archived}) => (
  id: 1,
  semesterId: 1,
  name: 'Algorithms',
  shortCode: 'CS201',
  professor: 'Dr Rao',
  room: 'A-1',
  attendanceTarget: 0.75,
  displayColor: 0xFF2563EB,
  isArchived: archived,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

TimetableEntry _entry({
  required int id,
  required int weekday,
  required int start,
  required int? lead,
}) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  weekday: weekday,
  startTime: start,
  endTime: start + 60,
  room: '',
  note: '',
  reminderMinutesBefore: lead,
);

final Semester _semester = (
  id: 1,
  name: 'Semester 1',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 31),
  isActive: true,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

Semester _semesterEnding(DateTime endDate) => (
  id: _semester.id,
  name: _semester.name,
  semesterNumber: _semester.semesterNumber,
  academicYear: _semester.academicYear,
  startDate: _semester.startDate,
  endDate: endDate,
  isActive: _semester.isActive,
  createdAt: _semester.createdAt,
  updatedAt: _semester.updatedAt,
);
