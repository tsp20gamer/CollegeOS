import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';

import 'attendance_engine.dart';

final class AttendanceStreakInsights {
  const AttendanceStreakInsights({
    required this.markedClasses,
    required this.currentPresentStreak,
    required this.longestPresentStreak,
    required this.perfectDays,
    required this.bestSubjectName,
    required this.bestSubjectStreak,
  });

  final int markedClasses;
  final int currentPresentStreak;
  final int longestPresentStreak;
  final int perfectDays;
  final String? bestSubjectName;
  final int bestSubjectStreak;

  bool get hasData => markedClasses > 0;
}

abstract final class AttendanceInsightsService {
  static AttendanceStreakInsights calculate({
    required AttendanceEngineSnapshot snapshot,
    required Semester semester,
    required DateTime asOf,
  }) {
    final results = AttendanceScheduleEngine.subjectResults(
      snapshot: snapshot,
      semester: semester,
    );
    final through = _dateOnly(asOf);
    final held =
        [
          for (final result in results)
            for (final record in result.history)
              if (record.status == ClassAttendanceStatus.present ||
                  record.status == ClassAttendanceStatus.absent)
                if (!_dateOnly(record.date).isAfter(through)) record,
        ]..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
        });

    var current = 0;
    for (final record in held.reversed) {
      if (record.status != ClassAttendanceStatus.present) break;
      current++;
    }

    var longest = 0;
    var running = 0;
    for (final record in held) {
      if (record.status == ClassAttendanceStatus.present) {
        running++;
        if (running > longest) longest = running;
      } else {
        running = 0;
      }
    }

    String? bestSubject;
    var bestSubjectStreak = 0;
    for (final result in results) {
      var subjectLongest = 0;
      var subjectRunning = 0;
      final subjectHeld =
          result.history
              .where(
                (record) =>
                    !_dateOnly(record.date).isAfter(through) &&
                    (record.status == ClassAttendanceStatus.present ||
                        record.status == ClassAttendanceStatus.absent),
              )
              .toList()
            ..sort((a, b) {
              final byDate = a.date.compareTo(b.date);
              return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
            });
      for (final record in subjectHeld) {
        if (record.status == ClassAttendanceStatus.present) {
          subjectRunning++;
          if (subjectRunning > subjectLongest) subjectLongest = subjectRunning;
        } else {
          subjectRunning = 0;
        }
      }
      if (subjectLongest > bestSubjectStreak) {
        bestSubjectStreak = subjectLongest;
        bestSubject = result.subject.name;
      }
    }

    var perfectDays = 0;
    var date = _dateOnly(semester.startDate);
    final today = _dateOnly(asOf);
    final semesterEnd = _dateOnly(semester.endDate);
    final end = today.isBefore(semesterEnd) ? today : semesterEnd;
    while (!date.isAfter(end)) {
      final day = AttendanceScheduleEngine.day(
        snapshot: snapshot,
        semester: semester,
        date: date,
      );
      if (day.state == AttendanceDayState.present) perfectDays++;
      date = date.add(const Duration(days: 1));
    }

    return AttendanceStreakInsights(
      markedClasses: held.length,
      currentPresentStreak: current,
      longestPresentStreak: longest,
      perfectDays: perfectDays,
      bestSubjectName: bestSubject,
      bestSubjectStreak: bestSubjectStreak,
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
