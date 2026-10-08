import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';

const timetableWeekdays = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
];

const timetableDayNames = <int, String>{
  DateTime.monday: 'Monday',
  DateTime.tuesday: 'Tuesday',
  DateTime.wednesday: 'Wednesday',
  DateTime.thursday: 'Thursday',
  DateTime.friday: 'Friday',
  DateTime.saturday: 'Saturday',
};

const timetableDayShortNames = <int, String>{
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
};

final class ScheduledClass {
  const ScheduledClass({required this.entry, required this.subject});

  final TimetableEntry entry;
  final Subject subject;
}

abstract final class TimetableOverlapService {
  static List<TimetableEntry> findOverlaps({
    required Iterable<TimetableEntry> entries,
    required int weekday,
    required int startTime,
    required int endTime,
    int? excludingId,
  }) => entries
      .where(
        (entry) =>
            entry.id != excludingId &&
            entry.weekday == weekday &&
            startTime < entry.endTime &&
            entry.startTime < endTime,
      )
      .toList(growable: false);
}

final class NextClassResult {
  const NextClassResult({
    required this.currentClasses,
    required this.nextClass,
    required this.daysUntilNext,
  });

  final List<ScheduledClass> currentClasses;
  final ScheduledClass? nextClass;
  final int? daysUntilNext;

  ScheduledClass? get currentClass =>
      currentClasses.isEmpty ? null : currentClasses.first;
  bool get nextIsToday => daysUntilNext == 0;
}

abstract final class NextClassService {
  static NextClassResult calculate({
    required Iterable<ScheduledClass> schedule,
    required DateTime now,
  }) {
    final ordered = schedule.toList(growable: false)
      ..sort((a, b) {
        final day = a.entry.weekday.compareTo(b.entry.weekday);
        return day != 0 ? day : a.entry.startTime.compareTo(b.entry.startTime);
      });
    final minute = now.hour * 60 + now.minute;
    final current =
        ordered
            .where(
              (item) =>
                  item.entry.weekday == now.weekday &&
                  item.entry.startTime <= minute &&
                  minute < item.entry.endTime,
            )
            .toList(growable: false)
          ..sort((a, b) => b.entry.startTime.compareTo(a.entry.startTime));

    final laterToday = ordered.where(
      (item) =>
          item.entry.weekday == now.weekday && item.entry.startTime > minute,
    );
    if (laterToday.isNotEmpty) {
      return NextClassResult(
        currentClasses: current,
        nextClass: laterToday.first,
        daysUntilNext: 0,
      );
    }

    for (var daysAhead = 1; daysAhead <= DateTime.daysPerWeek; daysAhead++) {
      final weekday =
          ((now.weekday - 1 + daysAhead) % DateTime.daysPerWeek) + 1;
      final matches = ordered.where((item) => item.entry.weekday == weekday);
      if (matches.isNotEmpty) {
        return NextClassResult(
          currentClasses: current,
          nextClass: matches.first,
          daysUntilNext: daysAhead,
        );
      }
    }
    return NextClassResult(
      currentClasses: current,
      nextClass: null,
      daysUntilNext: null,
    );
  }
}

/// Resolves the next class from the linked day projection, so holidays,
/// cancellations and one-day extra classes are respected by Home and widgets.
abstract final class AttendanceAwareNextClassService {
  static NextClassResult calculate({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final semesterStart = DateTime(
      semester.startDate.year,
      semester.startDate.month,
      semester.startDate.day,
    );
    final semesterEnd = DateTime(
      semester.endDate.year,
      semester.endDate.month,
      semester.endDate.day,
    );
    if (today.isAfter(semesterEnd)) return _empty();

    final firstDate = today.isBefore(semesterStart) ? semesterStart : today;
    final minute = now.hour * 60 + now.minute;
    var current = const <ScheduledClass>[];
    for (
      var date = firstDate;
      !date.isAfter(semesterEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final day = AttendanceScheduleEngine.day(
        snapshot: snapshot,
        semester: semester,
        date: date,
      );
      final schedule =
          day.sessions
              .where(
                (session) =>
                    session.timetableEntryId != null &&
                    session.status != ClassAttendanceStatus.cancelled,
              )
              .map(_scheduled)
              .toList(growable: false)
            ..sort((a, b) => a.entry.startTime.compareTo(b.entry.startTime));
      final daysAhead = date.difference(today).inDays;
      if (daysAhead == 0) {
        current =
            schedule
                .where(
                  (item) =>
                      item.entry.startTime <= minute &&
                      minute < item.entry.endTime,
                )
                .toList(growable: false)
              ..sort((a, b) => b.entry.startTime.compareTo(a.entry.startTime));
        final later = schedule.where((item) => item.entry.startTime > minute);
        if (later.isNotEmpty) {
          return NextClassResult(
            currentClasses: current,
            nextClass: later.first,
            daysUntilNext: 0,
          );
        }
      } else if (schedule.isNotEmpty) {
        return NextClassResult(
          currentClasses: current,
          nextClass: schedule.first,
          daysUntilNext: daysAhead,
        );
      }
    }
    return NextClassResult(
      currentClasses: current,
      nextClass: null,
      daysUntilNext: null,
    );
  }

  static ScheduledClass _scheduled(ProjectedClassSession session) =>
      ScheduledClass(
        entry: (
          id: session.timetableEntryId!,
          semesterId: session.subject.semesterId,
          subjectId: session.subject.id,
          weekday: session.date.weekday,
          startTime: session.startTime,
          endTime: session.endTime,
          room: session.subject.room,
          note: session.note,
          // Reminder intent lives on the timetable entry, which this projected
          // session does not carry; the class list reads the stored entry.
          reminderMinutesBefore: null,
        ),
        subject: session.subject,
      );

  static NextClassResult _empty() => const NextClassResult(
    currentClasses: [],
    nextClass: null,
    daysUntilNext: null,
  );
}
