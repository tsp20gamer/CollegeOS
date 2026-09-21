import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:college_os/features/tasks/domain/task_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 12, 14, 30);

  test('sorts overdue, today, upcoming, then no deadline', () {
    final tasks = [
      _task(id: 1, title: 'No deadline'),
      _task(id: 2, title: 'Upcoming', date: DateTime(2026, 8, 13)),
      _task(id: 3, title: 'Today later', date: now, time: 17 * 60),
      _task(id: 4, title: 'Overdue date', date: DateTime(2026, 8, 11)),
      _task(id: 5, title: 'Overdue time', date: now, time: 13 * 60),
    ];

    final result = TaskService.filterAndSort(
      tasks: tasks,
      filter: TaskFilter.all,
      now: now,
    );
    expect(result.map((task) => task.title), [
      'Overdue date',
      'Overdue time',
      'Today later',
      'Upcoming',
      'No deadline',
    ]);
  });

  test('filters today, upcoming, and completed without mixing states', () {
    final tasks = [
      _task(id: 1, title: 'Today', date: now),
      _task(id: 2, title: 'Future', date: DateTime(2026, 8, 14)),
      _task(id: 3, title: 'Past', date: DateTime(2026, 8, 10)),
      _task(id: 4, title: 'Done', completed: true),
    ];
    expect(
      TaskService.filterAndSort(
        tasks: tasks,
        filter: TaskFilter.today,
        now: now,
      ).map((task) => task.title),
      ['Today'],
    );
    expect(
      TaskService.filterAndSort(
        tasks: tasks,
        filter: TaskFilter.upcoming,
        now: now,
      ).map((task) => task.title),
      ['Future'],
    );
    expect(
      TaskService.filterAndSort(
        tasks: tasks,
        filter: TaskFilter.completed,
        now: now,
      ).map((task) => task.title),
      ['Done'],
    );
  });

  test('uses priority as a tie breaker for equal deadlines', () {
    final date = DateTime(2026, 8, 13);
    final tasks = [
      _task(id: 1, title: 'Low', date: date, priority: TaskPriority.low),
      _task(id: 2, title: 'High', date: date, priority: TaskPriority.high),
      _task(id: 3, title: 'Medium', date: date),
    ];
    final result = TaskService.filterAndSort(
      tasks: tasks,
      filter: TaskFilter.all,
      now: now,
    );
    expect(result.map((task) => task.title), ['High', 'Medium', 'Low']);
  });

  test('today filter includes a task whose due time has passed today', () {
    final result = TaskService.filterAndSort(
      tasks: [_task(id: 1, title: 'Past time', date: now, time: 10 * 60)],
      filter: TaskFilter.today,
      now: now,
    );
    expect(result.map((task) => task.title), ['Past time']);
    expect(TaskService.dueState(result.single, now), TaskDueState.overdue);
  });

  test('effective deadline keeps date-only work at the end of its day', () {
    expect(
      TaskService.effectiveDeadline(
        _task(id: 1, title: 'Date only', date: DateTime(2026, 8, 12)),
      ),
      DateTime(2026, 8, 12, 23, 59),
    );
  });
}

CollegeTask _task({
  required int id,
  required String title,
  DateTime? date,
  int? time,
  TaskPriority priority = TaskPriority.medium,
  bool completed = false,
}) => (
  id: id,
  semesterId: 1,
  subjectId: null,
  title: title,
  description: '',
  type: CollegeTaskType.general,
  priority: priority,
  dueDate: date,
  dueTime: time,
  reminderAt: null,
  isCompleted: completed,
  completedAt: completed ? DateTime.utc(2026, 8, 1) : null,
  createdAt: DateTime.utc(2026, 8, id),
  updatedAt: DateTime.utc(2026, 8, id),
);
