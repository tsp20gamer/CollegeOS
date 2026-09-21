import 'package:college_os/features/tasks/domain/task_repository.dart';

enum TaskFilter { all, today, upcoming, completed }

enum TaskDueState { overdue, today, upcoming, noDeadline, completed }

abstract final class TaskService {
  static List<CollegeTask> filterAndSort({
    required Iterable<CollegeTask> tasks,
    required TaskFilter filter,
    required DateTime now,
  }) {
    final selected = tasks
        .where((task) {
          return switch (filter) {
            TaskFilter.all => !task.isCompleted,
            TaskFilter.today => !task.isCompleted && _isDueOn(task, now),
            TaskFilter.upcoming =>
              !task.isCompleted && _isAfterToday(task, now),
            TaskFilter.completed => task.isCompleted,
          };
        })
        .toList(growable: false);
    return selected..sort((a, b) => compare(a, b, now));
  }

  static TaskDueState dueState(CollegeTask task, DateTime now) {
    if (task.isCompleted) return TaskDueState.completed;
    final dueDate = task.dueDate;
    if (dueDate == null) return TaskDueState.noDeadline;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (day.isBefore(today)) return TaskDueState.overdue;
    if (day.isAfter(today)) return TaskDueState.upcoming;
    if (task.dueTime case final dueTime?) {
      final due = DateTime(
        today.year,
        today.month,
        today.day,
        dueTime ~/ 60,
        dueTime % 60,
      );
      if (due.isBefore(now)) return TaskDueState.overdue;
    }
    return TaskDueState.today;
  }

  static int compare(CollegeTask a, CollegeTask b, DateTime now) {
    final stateOrder = _order(
      dueState(a, now),
    ).compareTo(_order(dueState(b, now)));
    if (stateOrder != 0) return stateOrder;
    final aDate = _deadline(a);
    final bDate = _deadline(b);
    if (aDate != null && bDate != null) {
      final deadlineOrder = aDate.compareTo(bDate);
      if (deadlineOrder != 0) return deadlineOrder;
    }
    final priorityOrder = b.priority.index.compareTo(a.priority.index);
    if (priorityOrder != 0) return priorityOrder;
    return a.createdAt.compareTo(b.createdAt);
  }

  static DateTime? effectiveDeadline(CollegeTask task) => _deadline(task);

  static DateTime? _deadline(CollegeTask task) {
    final date = task.dueDate;
    if (date == null) return null;
    final minutes = task.dueTime;
    return DateTime(
      date.year,
      date.month,
      date.day,
      minutes == null ? 23 : minutes ~/ 60,
      minutes == null ? 59 : minutes % 60,
    );
  }

  static int _order(TaskDueState state) => switch (state) {
    TaskDueState.overdue => 0,
    TaskDueState.today => 1,
    TaskDueState.upcoming => 2,
    TaskDueState.noDeadline => 3,
    TaskDueState.completed => 4,
  };

  static bool _isDueOn(CollegeTask task, DateTime date) {
    final dueDate = task.dueDate;
    return dueDate != null &&
        dueDate.year == date.year &&
        dueDate.month == date.month &&
        dueDate.day == date.day;
  }

  static bool _isAfterToday(CollegeTask task, DateTime date) {
    final dueDate = task.dueDate;
    if (dueDate == null) return false;
    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).isAfter(DateTime(date.year, date.month, date.day));
  }
}
