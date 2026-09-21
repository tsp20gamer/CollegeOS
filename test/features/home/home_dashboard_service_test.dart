import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/home/domain/home_dashboard_service.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'nearest tasks prioritizes overdue then dated work and excludes completed',
    () {
      final today = DateTime(2026, 8, 12);
      final result = HomeDashboardService.nearestTasks(
        tasks: [
          _task(id: 1, title: 'Undated'),
          _task(id: 2, title: 'Tomorrow', dueDate: DateTime(2026, 8, 13)),
          _task(id: 3, title: 'Overdue', dueDate: DateTime(2026, 8, 10)),
          _task(id: 4, title: 'Completed', dueDate: today, isCompleted: true),
          _task(id: 5, title: 'Today', dueDate: today),
        ],
        today: today,
      );
      expect(result.map((task) => task.title), [
        'Overdue',
        'Today',
        'Tomorrow',
      ]);
    },
  );

  test('nearest exams excludes past exams and orders date then start time', () {
    final today = DateTime(2026, 8, 12);
    final result = HomeDashboardService.nearestExams(
      exams: [
        _exam(id: 1, name: 'Past', date: DateTime(2026, 8, 11)),
        _exam(id: 2, name: 'Late today', date: today, start: 12 * 60),
        _exam(id: 3, name: 'Early today', date: today, start: 9 * 60),
        _exam(id: 4, name: 'Tomorrow', date: DateTime(2026, 8, 13)),
      ],
      today: today,
    );
    expect(result.map((exam) => exam.name), ['Early today', 'Late today']);
  });
}

CollegeTask _task({
  required int id,
  required String title,
  DateTime? dueDate,
  bool isCompleted = false,
}) => (
  id: id,
  semesterId: 1,
  subjectId: null,
  title: title,
  description: '',
  type: CollegeTaskType.general,
  priority: TaskPriority.medium,
  dueDate: dueDate,
  dueTime: null,
  reminderAt: null,
  isCompleted: isCompleted,
  completedAt: isCompleted ? DateTime.utc(2026, 8, 1) : null,
  createdAt: DateTime.utc(2026, 8, id),
  updatedAt: DateTime.utc(2026, 8, id),
);

Exam _exam({
  required int id,
  required String name,
  required DateTime date,
  int? start,
}) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  name: name,
  examType: 'Written',
  examDate: date,
  startTime: start,
  endTime: null,
  room: '',
  syllabus: '',
  maxMarks: null,
  obtainedMarks: null,
  reminderAt: null,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);
