import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';

import 'attendance_calculator.dart';

/// A read-only what-if projection. Planned classes are never persisted.
final class AttendancePlan {
  const AttendancePlan({
    required this.current,
    required this.projected,
    required this.plannedPresent,
    required this.plannedAbsent,
  });

  final AttendanceMetrics current;
  final AttendanceMetrics projected;
  final int plannedPresent;
  final int plannedAbsent;

  int get plannedClasses => plannedPresent + plannedAbsent;

  double get percentagePointChange =>
      (projected.attendancePercentage ?? 0) -
      (current.attendancePercentage ?? 0);
}

/// One date the student is planning to skip, resolved against the timetable.
final class PlannedSkipDay {
  const PlannedSkipDay({
    required this.date,
    required this.state,
    required this.skippableSessions,
    required this.alreadyMarkedCount,
  });

  final DateTime date;
  final AttendanceDayState state;

  /// Classes that would still change: unmarked and not cancelled.
  ///
  /// Classes that already carry a present, absent, or cancelled mark are never
  /// moved by a plan, which is what keeps the planner read-only.
  final List<ProjectedClassSession> skippableSessions;

  /// Classes on this date that already carry a present or absent mark.
  final int alreadyMarkedCount;

  int get skippableCount => skippableSessions.length;

  bool get contributes => skippableSessions.isNotEmpty;

  bool get isExcluded =>
      state == AttendanceDayState.holiday ||
      state == AttendanceDayState.collegeClosed;

  bool get isOutsideSemester => state == AttendanceDayState.outsideSemester;
}

/// How a planned skip changes one subject.
final class SubjectSkipImpact {
  const SubjectSkipImpact({
    required this.subject,
    required this.skippedClasses,
    required this.current,
    required this.projected,
  });

  final Subject subject;

  /// Classes of this subject that the plan would miss.
  final int skippedClasses;

  final AttendanceMetrics current;
  final AttendanceMetrics projected;

  double get percentagePointChange =>
      (projected.attendancePercentage ?? 0) -
      (current.attendancePercentage ?? 0);
}

/// The cumulative effect of skipping every class on the planned dates.
final class SkipDayPlan {
  const SkipDayPlan({
    required this.days,
    required this.subjects,
    required this.overallCurrent,
    required this.overallProjected,
  });

  final List<PlannedSkipDay> days;

  /// Only subjects whose attendance would change, in skip order.
  final List<SubjectSkipImpact> subjects;

  final AttendanceMetrics overallCurrent;
  final AttendanceMetrics overallProjected;

  int get skippedClassCount =>
      days.fold(0, (total, day) => total + day.skippableCount);

  int get contributingDayCount => days.where((day) => day.contributes).length;

  bool get changesAnything => skippedClassCount > 0;

  double get overallPercentagePointChange =>
      (overallProjected.attendancePercentage ?? 0) -
      (overallCurrent.attendancePercentage ?? 0);

  /// The one-sentence outcome the impact card shows and announces.
  String get summaryMessage {
    if (!changesAnything) {
      return 'No unmarked classes fall on these days, so your attendance does not change yet.';
    }
    final classes = skippedClassCount;
    final days = contributingDayCount;
    final projected = overallProjected;
    final target = '${(projected.target * 100).toStringAsFixed(0)}%';
    final standing = projected.isAtOrAboveTarget
        ? 'You would stay at or above $target.'
        : 'You would fall below $target.';
    final percentage = projected.attendancePercentage;
    return 'Missing $classes ${classes == 1 ? 'class' : 'classes'} over '
        '$days ${days == 1 ? 'day' : 'days'} leaves overall attendance at '
        "${percentage == null ? '—' : '${percentage.toStringAsFixed(1)}%'}. "
        '$standing';
  }
}

abstract final class AttendancePlannerService {
  static AttendancePlan project({
    required AttendanceMetrics current,
    required int plannedPresent,
    required int plannedAbsent,
  }) {
    if (plannedPresent < 0 || plannedAbsent < 0) {
      throw ArgumentError('Planned attendance counts cannot be negative.');
    }
    return AttendancePlan(
      current: current,
      plannedPresent: plannedPresent,
      plannedAbsent: plannedAbsent,
      projected: AttendanceCalculator.calculate(
        presentCount: current.presentCount + plannedPresent,
        absentCount: current.absentCount + plannedAbsent,
        cancelledCount: current.cancelledCount,
        target: current.target,
      ),
    );
  }

  /// Combines every subject into one overall attendance record.
  ///
  /// Uses the same calculator as a single subject, so the overall record earns
  /// the same target, safe-bunk, and recovery numbers.
  static AttendanceMetrics overallMetrics({
    required Iterable<SubjectAttendanceResult> subjects,
    required double target,
  }) {
    var present = 0;
    var absent = 0;
    var cancelled = 0;
    for (final item in subjects) {
      present += item.metrics.presentCount;
      absent += item.metrics.absentCount;
      cancelled += item.metrics.cancelledCount;
    }
    return AttendanceCalculator.calculate(
      presentCount: present,
      absentCount: absent,
      cancelledCount: cancelled,
      target: _usableTarget(target),
    );
  }

  /// Projects the outcome of missing every unmarked class on [dates].
  ///
  /// Dates are de-duplicated and sorted, so adding the same day twice counts
  /// once. Archived subjects stay out of the totals, matching the rest of the
  /// app, and days that are holidays or outside the semester contribute
  /// nothing while keeping their state so the UI can explain why.
  static SkipDayPlan planSkipDays({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required Iterable<DateTime> dates,
    required List<SubjectAttendanceResult> subjectResults,
    required double overallTarget,
  }) {
    final activeSubjectIds = <int>{
      for (final subject in snapshot.subjects)
        if (!subject.isArchived) subject.id,
    };
    final byId = <int, SubjectAttendanceResult>{
      for (final result in subjectResults) result.subject.id: result,
    };
    final orderedDates = <DateTime>{
      for (final date in dates) _dateOnly(date),
    }.toList()..sort();

    final days = <PlannedSkipDay>[];
    final skippedBySubject = <int, int>{};
    for (final date in orderedDates) {
      final day = AttendanceScheduleEngine.day(
        snapshot: snapshot,
        semester: semester,
        date: date,
      );
      final skippable = day.sessions
          .where(
            (session) =>
                session.status == ClassAttendanceStatus.unmarked &&
                activeSubjectIds.contains(session.subject.id) &&
                byId.containsKey(session.subject.id),
          )
          .toList(growable: false);
      for (final session in skippable) {
        skippedBySubject.update(
          session.subject.id,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      days.add(
        PlannedSkipDay(
          date: day.date,
          state: day.state,
          skippableSessions: List.unmodifiable(skippable),
          alreadyMarkedCount: day.sessions
              .where(
                (session) =>
                    session.status == ClassAttendanceStatus.present ||
                    session.status == ClassAttendanceStatus.absent,
              )
              .length,
        ),
      );
    }

    final impacts = <SubjectSkipImpact>[];
    for (final entry in skippedBySubject.entries) {
      final result = byId[entry.key];
      if (result == null) continue;
      impacts.add(
        SubjectSkipImpact(
          subject: result.subject,
          skippedClasses: entry.value,
          current: result.metrics,
          projected: AttendanceCalculator.calculate(
            presentCount: result.metrics.presentCount,
            absentCount: result.metrics.absentCount + entry.value,
            cancelledCount: result.metrics.cancelledCount,
            target: result.metrics.target,
          ),
        ),
      );
    }

    final overallCurrent = overallMetrics(
      subjects: subjectResults,
      target: overallTarget,
    );
    final skippedClasses = impacts.fold(
      0,
      (total, impact) => total + impact.skippedClasses,
    );
    return SkipDayPlan(
      days: List.unmodifiable(days),
      subjects: List.unmodifiable(impacts),
      overallCurrent: overallCurrent,
      overallProjected: AttendanceCalculator.calculate(
        presentCount: overallCurrent.presentCount,
        absentCount: overallCurrent.absentCount + skippedClasses,
        cancelledCount: overallCurrent.cancelledCount,
        target: overallCurrent.target,
      ),
    );
  }
}

/// Keeps a caller-supplied target inside the calculator's accepted range.
double _usableTarget(double target) =>
    !target.isFinite || target <= 0 || target > 1
    ? kDefaultAttendanceTarget
    : target;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
