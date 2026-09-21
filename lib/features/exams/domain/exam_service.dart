import 'package:college_os/features/exams/domain/exam_repository.dart';

abstract final class ExamService {
  static List<Exam> upcoming(Iterable<Exam> exams, DateTime today) {
    final base = _utcDate(today);
    final result = exams
        .where((exam) => !_utcDate(exam.examDate).isBefore(base))
        .toList(growable: false);
    return result..sort(_compareAscending);
  }

  static List<Exam> past(Iterable<Exam> exams, DateTime today) {
    final base = _utcDate(today);
    final result = exams
        .where((exam) => _utcDate(exam.examDate).isBefore(base))
        .toList(growable: false);
    return result..sort((a, b) => _compareAscending(b, a));
  }

  static int daysUntil(DateTime examDate, DateTime today) =>
      _utcDate(examDate).difference(_utcDate(today)).inDays;

  static String countdown(DateTime examDate, DateTime today) {
    final days = daysUntil(examDate, today);
    return switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      > 1 => 'In $days days',
      -1 => 'Yesterday',
      _ => '${-days} days ago',
    };
  }

  static int _compareAscending(Exam a, Exam b) {
    final date = a.examDate.compareTo(b.examDate);
    if (date != 0) return date;
    return (a.startTime ?? 1440).compareTo(b.startTime ?? 1440);
  }

  static DateTime _utcDate(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
