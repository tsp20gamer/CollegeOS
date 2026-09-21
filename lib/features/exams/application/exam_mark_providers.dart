import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final semesterExamsProvider = StreamProvider<List<Exam>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  return ref.watch(examRepositoryProvider).watchForSemester(semester.id);
});

final semesterMarksProvider = StreamProvider<List<Mark>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  return ref.watch(marksRepositoryProvider).watchForSemester(semester.id);
});

final subjectMarksProvider = StreamProvider.family<List<Mark>, int>(
  (ref, subjectId) =>
      ref.watch(marksRepositoryProvider).watchForSubject(subjectId),
);

final performanceSubjectProvider = FutureProvider.family<Subject?, int>(
  (ref, subjectId) => ref.watch(subjectRepositoryProvider).findById(subjectId),
);

final examCommandProvider = AsyncNotifierProvider<ExamCommandController, void>(
  ExamCommandController.new,
);

final class ExamCommandController extends AsyncNotifier<void> {
  bool reminderPermissionDenied = false;
  bool reminderSchedulingFailed = false;

  @override
  Future<void> build() async {}

  Future<bool> create(NewExam exam) => _run(() async {
    reminderSchedulingFailed = false;
    reminderPermissionDenied = !await ref
        .read(notificationCoordinatorProvider)
        .ensureEnabledForReminder(exam.reminderAt);
    final id = await ref.read(examRepositoryProvider).create(exam);
    await _tryNotification(
      () => ref
          .read(notificationCoordinatorProvider)
          .syncExam(id: id, name: exam.name, reminderAt: exam.reminderAt),
      reportFailure: exam.reminderAt != null,
    );
  });
  Future<bool> updateExam(Exam exam) => _run(() async {
    reminderSchedulingFailed = false;
    reminderPermissionDenied = !await ref
        .read(notificationCoordinatorProvider)
        .ensureEnabledForReminder(exam.reminderAt);
    await ref.read(examRepositoryProvider).update(exam);
    await _tryNotification(
      () => ref
          .read(notificationCoordinatorProvider)
          .syncExam(id: exam.id, name: exam.name, reminderAt: exam.reminderAt),
      reportFailure: exam.reminderAt != null,
    );
  });
  Future<bool> deleteExam(int id) => _run(() async {
    await ref.read(examRepositoryProvider).delete(id);
    await _tryNotification(
      () => ref
          .read(notificationCoordinatorProvider)
          .cancel(NotificationEntityType.exam, id),
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

final markCommandProvider = AsyncNotifierProvider<MarkCommandController, void>(
  MarkCommandController.new,
);

final class MarkCommandController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> create(NewMark mark) =>
      _run(() => ref.read(marksRepositoryProvider).create(mark));
  Future<bool> updateMark(Mark mark) =>
      _run(() => ref.read(marksRepositoryProvider).update(mark));
  Future<bool> deleteMark(int id) =>
      _run(() => ref.read(marksRepositoryProvider).delete(id));

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
