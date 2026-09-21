import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/tasks_dao.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:drift/drift.dart';

final class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._dao);

  final TasksDao _dao;

  @override
  Stream<List<CollegeTask>> watchForSemester(
    int semesterId, {
    bool? completed,
  }) => _dao
      .watchForSemester(semesterId, completed: completed)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<int> create(NewCollegeTask task) => _dao.insertTask(
    CollegeTasksCompanion.insert(
      semesterId: task.semesterId,
      subjectId: Value(task.subjectId),
      title: task.title.trim(),
      description: Value(task.description.trim()),
      type: task.type,
      priority: task.priority,
      dueDate: Value(task.dueDate),
      dueTime: Value(task.dueTime),
      reminderAt: Value(task.reminderAt),
    ),
  );

  @override
  Future<void> update(CollegeTask task) async {
    final updated = await _dao.updateTask(
      CollegeTasksCompanion.insert(
        id: Value(task.id),
        semesterId: task.semesterId,
        subjectId: Value(task.subjectId),
        title: task.title.trim(),
        description: Value(task.description.trim()),
        type: task.type,
        priority: task.priority,
        dueDate: Value(task.dueDate),
        dueTime: Value(task.dueTime),
        reminderAt: Value(task.reminderAt),
        isCompleted: Value(task.isCompleted),
        completedAt: Value(task.completedAt),
        createdAt: Value(task.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (!updated) throw StateError('Task ${task.id} does not exist.');
  }

  @override
  Future<void> setCompleted(int id, {required bool completed}) async {
    final changed = await _dao.setCompleted(id, completed: completed);
    if (changed == 0) throw StateError('Task $id does not exist.');
  }

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  @override
  Future<List<CollegeTask>> getAllWithReminders() async =>
      (await _dao.getAllWithReminders()).map(_map).toList(growable: false);

  CollegeTask _map(TaskRow row) => (
    id: row.id,
    semesterId: row.semesterId,
    subjectId: row.subjectId,
    title: row.title,
    description: row.description,
    type: row.type,
    priority: row.priority,
    dueDate: row.dueDate,
    dueTime: row.dueTime,
    reminderAt: row.reminderAt,
    isCompleted: row.isCompleted,
    completedAt: row.completedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
