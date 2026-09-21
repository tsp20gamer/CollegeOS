import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/college_tasks.dart';
import 'package:drift/drift.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [CollegeTasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.attachedDatabase);

  Stream<List<TaskRow>> watchForSemester(int semesterId, {bool? completed}) {
    final query = select(collegeTasks)
      ..where((row) {
        final inSemester = row.semesterId.equals(semesterId);
        return completed == null
            ? inSemester
            : inSemester & row.isCompleted.equals(completed);
      })
      ..orderBy([
        (row) => OrderingTerm.asc(row.dueDate),
        (row) => OrderingTerm.desc(row.priority),
        (row) => OrderingTerm.asc(row.createdAt),
      ]);
    return query.watch();
  }

  Future<int> insertTask(CollegeTasksCompanion task) =>
      into(collegeTasks).insert(task);

  Future<List<TaskRow>> getAllWithReminders() =>
      (select(collegeTasks)..where((row) => row.reminderAt.isNotNull())).get();

  Future<bool> updateTask(CollegeTasksCompanion task) =>
      update(collegeTasks).replace(task);

  Future<int> setCompleted(int id, {required bool completed}) {
    final now = DateTime.now().toUtc();
    return (update(collegeTasks)..where((row) => row.id.equals(id))).write(
      CollegeTasksCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> deleteById(int id) =>
      (delete(collegeTasks)..where((row) => row.id.equals(id))).go();
}
