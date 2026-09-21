import 'package:college_os/core/database/database_enums.dart';

typedef CollegeTask = ({
  int id,
  int semesterId,
  int? subjectId,
  String title,
  String description,
  CollegeTaskType type,
  TaskPriority priority,
  DateTime? dueDate,
  int? dueTime,
  DateTime? reminderAt,
  bool isCompleted,
  DateTime? completedAt,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewCollegeTask = ({
  int semesterId,
  int? subjectId,
  String title,
  String description,
  CollegeTaskType type,
  TaskPriority priority,
  DateTime? dueDate,
  int? dueTime,
  DateTime? reminderAt,
});

abstract interface class TaskRepository {
  Stream<List<CollegeTask>> watchForSemester(int semesterId, {bool? completed});
  Future<List<CollegeTask>> getAllWithReminders();
  Future<int> create(NewCollegeTask task);
  Future<void> update(CollegeTask task);
  Future<void> setCompleted(int id, {required bool completed});
  Future<void> delete(int id);
}
