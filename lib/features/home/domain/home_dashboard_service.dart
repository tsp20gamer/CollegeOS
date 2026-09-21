import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:college_os/features/tasks/domain/task_service.dart';

abstract final class HomeDashboardService {
  static List<CollegeTask> nearestTasks({
    required Iterable<CollegeTask> tasks,
    required DateTime today,
    int limit = 3,
  }) {
    final visible = TaskService.filterAndSort(
      tasks: tasks,
      filter: TaskFilter.all,
      now: today,
    );
    return visible.take(limit).toList(growable: false);
  }

  static List<Exam> nearestExams({
    required Iterable<Exam> exams,
    required DateTime today,
    int limit = 2,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final upcoming =
        exams.where((exam) => !exam.examDate.isBefore(day)).toList()
          ..sort((a, b) {
            final byDate = a.examDate.compareTo(b.examDate);
            if (byDate != 0) return byDate;
            return (a.startTime ?? 1440).compareTo(b.startTime ?? 1440);
          });
    return upcoming.take(limit).toList(growable: false);
  }
}
