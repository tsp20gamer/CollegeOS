import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/weekly_attendance_summary.dart';
import 'package:college_os/features/notifications/domain/pending_attendance_reminder.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final Semester semester = (
  id: 1,
  name: 'Semester',
  semesterNumber: 1,
  academicYear: '2026-2027',
  startDate: DateTime(2026, 8, 1),
  endDate: DateTime(2026, 8, 31),
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
final Subject subject = (
  id: 1,
  semesterId: 1,
  name: 'Math',
  shortCode: 'M',
  professor: '',
  room: '',
  attendanceTarget: .75,
  displayColor: 0xFF7367F0,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
AttendanceEngineSnapshot snapshot({
  List<ExplicitClassAttendance> marks = const [],
  bool holiday = false,
}) => AttendanceEngineSnapshot(
  subjects: [subject],
  timetable: [
    for (final id in [1, 2])
      (
        id: id,
        semesterId: 1,
        subjectId: 1,
        weekday: DateTime.monday,
        startTime: 480 + id * 60,
        endTime: 540 + id * 60,
        effectiveFrom: semester.startDate,
        effectiveUntil: semester.endDate,
      ),
  ],
  attendance: marks,
  overrides: [
    if (holiday)
      (
        id: 1,
        semesterId: 1,
        date: DateTime(2026, 8, 17),
        type: CalendarDayOverrideType.holiday,
        note: '',
      ),
  ],
);
ExplicitClassAttendance mark(int slot, int day, ClassAttendanceStatus status) =>
    (
      id: day * 10 + slot,
      semesterId: 1,
      timetableEntryId: slot,
      subjectId: 1,
      date: DateTime(2026, 8, day),
      startTime: 480 + slot * 60,
      endTime: 540 + slot * 60,
      status: status,
      note: '',
      manuallyModified: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test(
    'reminds 15 minutes after final class with correct count and disjoint ID',
    () {
      final reminder = PendingAttendanceReminder.next(
        snapshot: snapshot(),
        semester: semester,
        now: DateTime(2026, 8, 17, 8),
      )!;
      expect(reminder.scheduledAt, DateTime(2026, 8, 17, 11, 15));
      expect(reminder.body, startsWith('2 classes'));
      expect(notificationId(reminder.type, reminder.entityId), 0);
      expect(
        parseNotificationPayload('attendance:1')?.type,
        NotificationEntityType.attendance,
      );
      expect(parseNotificationPayload('attendance:2'), isNull);
    },
  );
  test(
    'holiday, all marked and cancelled days are skipped; boundaries respected',
    () {
      for (final data in [
        snapshot(holiday: true),
        snapshot(
          marks: [
            mark(1, 17, ClassAttendanceStatus.present),
            mark(2, 17, ClassAttendanceStatus.cancelled),
          ],
        ),
      ]) {
        expect(
          PendingAttendanceReminder.next(
            snapshot: data,
            semester: semester,
            now: DateTime(2026, 8, 17, 8),
          )!.scheduledAt,
          DateTime(2026, 8, 24, 11, 15),
        );
      }
      expect(
        PendingAttendanceReminder.next(
          snapshot: snapshot(),
          semester: semester,
          now: DateTime(2026, 9, 1),
        ),
        isNull,
      );
    },
  );
  test(
    'past alarm is not repeatedly postponed; no-class weekend uses next weekday',
    () {
      for (final now in [DateTime(2026, 8, 17, 12), DateTime(2026, 8, 23, 8)]) {
        expect(
          PendingAttendanceReminder.next(
            snapshot: snapshot(),
            semester: semester,
            now: now,
          )!.scheduledAt,
          DateTime(2026, 8, 24, 11, 15),
        );
      }
    },
  );
  test(
    'week counts real marks and compares with prior week; target uses fractions',
    () {
      final summary = WeeklyAttendanceSummary.build(
        snapshot: snapshot(
          marks: [
            mark(1, 10, ClassAttendanceStatus.present),
            mark(2, 10, ClassAttendanceStatus.present),
            mark(1, 17, ClassAttendanceStatus.present),
            mark(2, 17, ClassAttendanceStatus.absent),
          ],
        ),
        semester: semester,
        now: DateTime(2026, 8, 18),
      );
      expect(summary.current.percentage, 50);
      expect(summary.current.absent, 1);
      expect(summary.change, -50);
      expect(summary.needsAttention, hasLength(1));
    },
  );
  test('weekly summary excludes holidays and future unmarked sessions', () {
    final summary = WeeklyAttendanceSummary.build(
      snapshot: snapshot(
        holiday: true,
        marks: [mark(1, 17, ClassAttendanceStatus.absent)],
      ),
      semester: semester,
      now: DateTime(2026, 8, 18),
    );
    expect(summary.current.held, 0);
    expect(summary.current.percentage, isNull);
    expect(summary.current.unmarked, 0);
    expect(summary.change, isNull);
    expect(
      WeeklyAttendanceSummary.build(
        snapshot: snapshot(),
        semester: semester,
        now: DateTime(2026, 8, 17, 8),
      ).current.unmarked,
      0,
    );
  });
}
