import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final semesterTasksProvider = StreamProvider<List<CollegeTask>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  return ref.watch(taskRepositoryProvider).watchForSemester(semester.id);
});

final taskCommandProvider = AsyncNotifierProvider<TaskCommandController, void>(
  TaskCommandController.new,
);

final class TaskCommandController extends AsyncNotifier<void> {
  bool reminderPermissionDenied = false;
  bool reminderSchedulingFailed = false;

  @override
  Future<void> build() async {}

  Future<bool> create(NewCollegeTask task) => _run(() async {
    reminderSchedulingFailed = false;
    reminderPermissionDenied = !await ref
        .read(notificationCoordinatorProvider)
        .ensureEnabledForReminder(task.reminderAt);
    final id = await ref.read(taskRepositoryProvider).create(task);
    await _tryNotification(
      () => ref
          .read(notificationCoordinatorProvider)
          .syncTask(
            id: id,
            title: task.title,
            type: task.type,
            reminderAt: task.reminderAt,
            completed: false,
          ),
      reportFailure: task.reminderAt != null,
    );
  });

  Future<bool> updateTask(CollegeTask task) => _run(() async {
    reminderSchedulingFailed = false;
    reminderPermissionDenied = !await ref
        .read(notificationCoordinatorProvider)
        .ensureEnabledForReminder(task.reminderAt);
    await ref.read(taskRepositoryProvider).update(task);
    await _tryNotification(
      () => ref
          .read(notificationCoordinatorProvider)
          .syncTask(
            id: task.id,
            title: task.title,
            type: task.type,
            reminderAt: task.reminderAt,
            completed: task.isCompleted,
          ),
      reportFailure: task.reminderAt != null,
    );
  });

  Future<bool> setCompleted(CollegeTask task, {required bool completed}) =>
      _run(() async {
        await ref
            .read(taskRepositoryProvider)
            .setCompleted(task.id, completed: completed);
        await _tryNotification(
          () => ref
              .read(notificationCoordinatorProvider)
              .syncTask(
                id: task.id,
                title: task.title,
                type: task.type,
                reminderAt: task.reminderAt,
                completed: completed,
              ),
        );
      });

  Future<bool> deleteTask(int id) => _run(() async {
    await ref.read(taskRepositoryProvider).delete(id);
    await _tryNotification(
      () => ref
          .read(notificationCoordinatorProvider)
          .cancel(NotificationEntityType.task, id),
    );
  });

  Future<void> _tryNotification(
    Future<void> Function() action, {
    bool reportFailure = false,
  }) async {
    try {
      await action();
    } catch (_) {
      // Reminder intent is durable and startup reconciliation will retry.
      if (reportFailure) reminderSchedulingFailed = true;
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
