import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';

enum AttendanceDayState {
  outsideSemester,
  holiday,
  collegeClosed,
  noClasses,
  unmarked,
  present,
  absent,
  partial,
  partiallyMarked,
}

typedef AttendanceTimetableSlot = ({
  int id,
  int semesterId,
  int subjectId,
  int weekday,
  int startTime,
  int endTime,
  DateTime? effectiveFrom,
  DateTime? effectiveUntil,
});

typedef ExplicitClassAttendance = ({
  int id,
  int semesterId,
  int? timetableEntryId,
  int subjectId,
  DateTime date,
  int startTime,
  int endTime,
  ClassAttendanceStatus status,
  String note,
  bool manuallyModified,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef DayOverride = ({
  int id,
  int semesterId,
  DateTime date,
  CalendarDayOverrideType type,
  String note,
});

/// The holidays every semester gets without a stored calendar row.
///
/// These are rules, not data: nothing is written per day, so turning one off
/// simply reveals the classes that were always there — exactly what deleting a
/// stored holiday range does. A stored `calendar_day_overrides` row always wins
/// over them, including a `normal` row, which is how a one-off working Sunday
/// or a college that runs classes on a second Saturday is expressed.
final class DefaultHolidayPolicy {
  const DefaultHolidayPolicy({
    this.sundayOff = false,
    this.secondSaturdayOff = false,
    this.governmentHolidaysOff = false,
  });

  /// No derived holidays. The default for snapshots that predate the rules.
  static const DefaultHolidayPolicy none = DefaultHolidayPolicy();

  final bool sundayOff;
  final bool secondSaturdayOff;
  final bool governmentHolidaysOff;

  /// The holiday [date] inherits from the rules, or null on a normal day.
  ///
  /// A Sunday is reported as itself before the second-Saturday and national
  /// checks, because those two can only ever describe a different day.
  String? labelFor(DateTime date) {
    if (sundayOff && date.weekday == DateTime.sunday) {
      return 'Sunday';
    }
    if (secondSaturdayOff && isSecondSaturday(date)) {
      return 'Second Saturday';
    }
    if (governmentHolidaysOff) return governmentHolidayName(date);
    return null;
  }

  /// True on the second Saturday of [date]'s month (its day falls in 8–14).
  static bool isSecondSaturday(DateTime date) =>
      date.weekday == DateTime.saturday && (date.day - 1) ~/ 7 == 1;

  /// The fixed-date national holiday name for [date], or null.
  ///
  /// The dates are constants rather than stored events, so no yearly holiday
  /// file is needed and the rule applies to every year automatically.
  static String? governmentHolidayName(DateTime date) {
    if (date.month == DateTime.january && date.day == 26) {
      return 'Republic Day';
    }
    if (date.month == DateTime.august && date.day == 15) {
      return 'Independence Day';
    }
    if (date.month == DateTime.october && date.day == 2) {
      return 'Gandhi Jayanti';
    }
    return null;
  }
}

typedef AttendanceCalendarEvent = ({
  int id,
  int semesterId,
  String title,
  AcademicCalendarEventType type,
  DateTime startDate,
  DateTime endDate,
  String note,
});

final class AttendanceEngineSnapshot {
  const AttendanceEngineSnapshot({
    required this.subjects,
    required this.timetable,
    required this.attendance,
    required this.overrides,
    this.calendarEvents = const [],
    this.defaultHolidays = DefaultHolidayPolicy.none,
  });

  final List<Subject> subjects;
  final List<AttendanceTimetableSlot> timetable;
  final List<ExplicitClassAttendance> attendance;
  final List<DayOverride> overrides;
  final List<AttendanceCalendarEvent> calendarEvents;
  final DefaultHolidayPolicy defaultHolidays;
}

final class ProjectedClassSession {
  const ProjectedClassSession({
    required this.date,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.note,
    required this.manuallyModified,
    this.attendanceId,
    this.timetableEntryId,
    this.isOneDayException = false,
  });

  final int? attendanceId;
  final int? timetableEntryId;
  final bool isOneDayException;
  final DateTime date;
  final Subject subject;
  final int startTime;
  final int endTime;
  final ClassAttendanceStatus status;
  final String note;
  final bool manuallyModified;

  bool get isMarked => status != ClassAttendanceStatus.unmarked;
}

final class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.state,
    required this.sessions,
    required this.override,
    required this.isInsideSemester,
  });

  final DateTime date;
  final AttendanceDayState state;
  final List<ProjectedClassSession> sessions;
  final DayOverride? override;
  final bool isInsideSemester;

  int get unmarkedCount => sessions
      .where((session) => session.status == ClassAttendanceStatus.unmarked)
      .length;
}

final class SubjectAttendanceResult {
  const SubjectAttendanceResult({
    required this.subject,
    required this.metrics,
    required this.history,
    this.excludedDays = const [],
  });

  final Subject subject;
  final AttendanceMetrics metrics;
  final List<ExplicitClassAttendance> history;
  final List<DayOverride> excludedDays;
}

final class PendingAttendanceGroup {
  const PendingAttendanceGroup({required this.date, required this.sessions});

  final DateTime date;
  final List<ProjectedClassSession> sessions;
}

abstract final class AttendanceScheduleEngine {
  static AttendanceDay day({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime date,
  }) {
    final target = _dateOnly(date);
    final inside =
        !target.isBefore(semester.startDate) &&
        !target.isAfter(semester.endDate);
    final explicitOverride = snapshot.overrides
        .where((item) => _sameDate(item.date, target))
        .firstOrNull;
    // Precedence is the student's own row, then a stored holiday range, then
    // the derived default rules. A stored `normal` row therefore keeps a
    // Sunday or second Saturday as a working day.
    final override =
        explicitOverride ??
        _eventOverrideForDate(snapshot.calendarEvents, target) ??
        _defaultHolidayOverride(snapshot, semester.id, target);
    if (!inside) {
      return AttendanceDay(
        date: target,
        state: AttendanceDayState.outsideSemester,
        sessions: const [],
        override: override,
        isInsideSemester: false,
      );
    }
    if (override?.type == CalendarDayOverrideType.holiday ||
        override?.type == CalendarDayOverrideType.collegeClosed) {
      return AttendanceDay(
        date: target,
        state: override!.type == CalendarDayOverrideType.holiday
            ? AttendanceDayState.holiday
            : AttendanceDayState.collegeClosed,
        sessions: const [],
        override: override,
        isInsideSemester: true,
      );
    }

    final subjectById = {
      for (final subject in snapshot.subjects) subject.id: subject,
    };
    final explicitBySlot = <int, ExplicitClassAttendance>{};
    final manual = <ExplicitClassAttendance>[];
    for (final record in snapshot.attendance.where(
      (record) => _sameDate(record.date, target),
    )) {
      if (record.timetableEntryId == null) {
        manual.add(record);
      } else {
        explicitBySlot[record.timetableEntryId!] = record;
      }
    }
    final sessions = <ProjectedClassSession>[];
    for (final slot in snapshot.timetable) {
      if (slot.weekday != target.weekday || !_activeOn(slot, target)) continue;
      final subject = subjectById[slot.subjectId];
      if (subject == null) continue;
      final record = explicitBySlot[slot.id];
      sessions.add(
        ProjectedClassSession(
          attendanceId: record?.id,
          timetableEntryId: slot.id,
          date: target,
          subject: subject,
          startTime: record?.startTime ?? slot.startTime,
          endTime: record?.endTime ?? slot.endTime,
          status: record?.status ?? ClassAttendanceStatus.unmarked,
          note: record?.note ?? '',
          manuallyModified: record?.manuallyModified ?? false,
          isOneDayException:
              slot.effectiveFrom != null &&
              slot.effectiveUntil != null &&
              _sameDate(slot.effectiveFrom!, target) &&
              _sameDate(slot.effectiveUntil!, target),
        ),
      );
    }
    for (final record in manual) {
      final subject = subjectById[record.subjectId];
      if (subject == null) continue;
      sessions.add(
        ProjectedClassSession(
          attendanceId: record.id,
          date: target,
          subject: subject,
          startTime: record.startTime,
          endTime: record.endTime,
          status: record.status,
          note: record.note,
          manuallyModified: record.manuallyModified,
        ),
      );
    }
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return AttendanceDay(
      date: target,
      state: _state(override, sessions),
      sessions: List.unmodifiable(sessions),
      override: override,
      isInsideSemester: true,
    );
  }

  static List<AttendanceDay> month({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime month,
  }) {
    final count = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var dayNumber = 1; dayNumber <= count; dayNumber++)
        day(
          snapshot: snapshot,
          semester: semester,
          date: DateTime(month.year, month.month, dayNumber),
        ),
    ];
  }

  static List<SubjectAttendanceResult> subjectResults({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
  }) {
    final exclusions = _allExclusions(snapshot, semester);
    final excludedDates = exclusions
        .where(
          (item) =>
              item.type == CalendarDayOverrideType.holiday ||
              item.type == CalendarDayOverrideType.collegeClosed,
        )
        .map((item) => _dateOnly(item.date))
        .toSet();
    return snapshot.subjects
        .where((subject) => !subject.isArchived)
        .map((subject) {
          final history =
              snapshot.attendance
                  .where(
                    (record) =>
                        record.subjectId == subject.id &&
                        !record.date.isBefore(semester.startDate) &&
                        !record.date.isAfter(semester.endDate) &&
                        !excludedDates.contains(_dateOnly(record.date)),
                  )
                  .toList()
                ..sort((a, b) {
                  final date = b.date.compareTo(a.date);
                  return date != 0 ? date : b.startTime.compareTo(a.startTime);
                });
          final present = history
              .where((record) => record.status == ClassAttendanceStatus.present)
              .length;
          final absent = history
              .where((record) => record.status == ClassAttendanceStatus.absent)
              .length;
          final cancelled = history
              .where(
                (record) => record.status == ClassAttendanceStatus.cancelled,
              )
              .length;
          final subjectExcludedDays =
              exclusions
                  .where(
                    (item) =>
                        excludedDates.contains(_dateOnly(item.date)) &&
                        !item.date.isBefore(semester.startDate) &&
                        !item.date.isAfter(semester.endDate) &&
                        snapshot.timetable.any(
                          (slot) =>
                              slot.subjectId == subject.id &&
                              slot.weekday == item.date.weekday &&
                              _activeOn(slot, item.date),
                        ),
                  )
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          return SubjectAttendanceResult(
            subject: subject,
            metrics: AttendanceCalculator.calculate(
              presentCount: present,
              absentCount: absent,
              cancelledCount: cancelled,
              target: subject.attendanceTarget,
            ),
            history: List.unmodifiable(history),
            excludedDays: List.unmodifiable(subjectExcludedDays),
          );
        })
        .toList(growable: false);
  }

  static int pendingCount({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime through,
  }) {
    return pendingGroups(
      snapshot: snapshot,
      semester: semester,
      through: through,
    ).fold(0, (count, group) => count + group.sessions.length);
  }

  static List<PendingAttendanceGroup> pendingGroups({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime through,
  }) {
    var date = _dateOnly(semester.startDate);
    final throughDate = _dateOnly(through);
    final semesterEnd = _dateOnly(semester.endDate);
    final end = throughDate.isBefore(semesterEnd) ? throughDate : semesterEnd;
    final currentMinutes = through.hour * 60 + through.minute;
    final result = <PendingAttendanceGroup>[];
    while (!date.isAfter(end)) {
      final value = day(snapshot: snapshot, semester: semester, date: date);
      if (value.state != AttendanceDayState.holiday &&
          value.state != AttendanceDayState.collegeClosed) {
        final pending = value.sessions
            .where(
              (session) =>
                  session.status == ClassAttendanceStatus.unmarked &&
                  (!_sameDate(date, throughDate) ||
                      session.endTime <= currentMinutes),
            )
            .toList(growable: false);
        if (pending.isNotEmpty) {
          result.add(PendingAttendanceGroup(date: date, sessions: pending));
        }
      }
      date = date.add(const Duration(days: 1));
    }
    return List.unmodifiable(result);
  }

  static bool _activeOn(AttendanceTimetableSlot slot, DateTime date) =>
      (slot.effectiveFrom == null || !date.isBefore(slot.effectiveFrom!)) &&
      (slot.effectiveUntil == null || !date.isAfter(slot.effectiveUntil!));

  static AttendanceDayState _state(
    DayOverride? override,
    List<ProjectedClassSession> sessions,
  ) {
    if (override?.type == CalendarDayOverrideType.holiday) {
      return AttendanceDayState.holiday;
    }
    if (override?.type == CalendarDayOverrideType.collegeClosed) {
      return AttendanceDayState.collegeClosed;
    }
    final held = sessions
        .where((session) => session.status != ClassAttendanceStatus.cancelled)
        .toList();
    if (held.isEmpty) return AttendanceDayState.noClasses;
    final present = held
        .where((session) => session.status == ClassAttendanceStatus.present)
        .length;
    final absent = held
        .where((session) => session.status == ClassAttendanceStatus.absent)
        .length;
    final unmarked = held.length - present - absent;
    if (unmarked == held.length) return AttendanceDayState.unmarked;
    if (unmarked > 0) return AttendanceDayState.partiallyMarked;
    if (present == held.length) return AttendanceDayState.present;
    if (absent == held.length) return AttendanceDayState.absent;
    return AttendanceDayState.partial;
  }
}

/// The derived-holiday day row for [date], or null when the rules leave it a
/// normal day.
///
/// It is built on demand rather than stored, so the same date answers
/// identically for every read while nothing is written to the database. The ID
/// is zero because no row exists to edit or delete.
DayOverride? _defaultHolidayOverride(
  AttendanceEngineSnapshot snapshot,
  int semesterId,
  DateTime date,
) {
  final label = snapshot.defaultHolidays.labelFor(date);
  if (label == null) return null;
  return (
    id: 0,
    semesterId: semesterId,
    date: _dateOnly(date),
    type: CalendarDayOverrideType.holiday,
    note: label,
  );
}

DayOverride? _eventOverrideForDate(
  List<AttendanceCalendarEvent> events,
  DateTime date,
) {
  for (final event in events) {
    if (date.isBefore(event.startDate) || date.isAfter(event.endDate)) continue;
    final type = switch (event.type) {
      AcademicCalendarEventType.holiday => CalendarDayOverrideType.holiday,
      AcademicCalendarEventType.collegeClosed =>
        CalendarDayOverrideType.collegeClosed,
      _ => null,
    };
    if (type != null) {
      return (
        id: -event.id,
        semesterId: event.semesterId,
        date: _dateOnly(date),
        type: type,
        note: event.note.isEmpty
            ? event.title
            : '${event.title}: ${event.note}',
      );
    }
  }
  return null;
}

List<DayOverride> _allExclusions(
  AttendanceEngineSnapshot snapshot,
  Semester semester,
) {
  final byDate = <DateTime, DayOverride>{
    for (final override in snapshot.overrides)
      if (override.type == CalendarDayOverrideType.holiday ||
          override.type == CalendarDayOverrideType.collegeClosed)
        _dateOnly(override.date): override,
  };
  for (
    var date = _dateOnly(semester.startDate);
    !date.isAfter(semester.endDate);
    date = date.add(const Duration(days: 1))
  ) {
    byDate.putIfAbsent(
      date,
      () =>
          _eventOverrideForDate(snapshot.calendarEvents, date) ??
          _defaultHolidayOverride(snapshot, semester.id, date) ??
          (
            id: 0,
            semesterId: semester.id,
            date: date,
            type: CalendarDayOverrideType.normal,
            note: '',
          ),
    );
  }
  return byDate.values
      .where((item) => item.type != CalendarDayOverrideType.normal)
      .toList(growable: false);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
