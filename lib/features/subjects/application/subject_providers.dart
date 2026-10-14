import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeSemesterProvider = StreamProvider<Semester?>((ref) {
  return ref.watch(semesterRepositoryProvider).watchAll().map((semesters) {
    for (final semester in semesters) {
      if (semester.isActive) return semester;
    }
    return null;
  });
});

final activeSemesterSubjectsProvider = StreamProvider<List<Subject>>((ref) {
  final activeSemester = ref.watch(activeSemesterProvider).value;
  if (activeSemester == null) return Stream.value(const []);
  return ref
      .watch(subjectRepositoryProvider)
      .watchForSemester(activeSemester.id, includeArchived: true);
});

/// Every subject in every semester, archived ones included.
///
/// Used where the whole local set matters, such as the stored default
/// attendance target applying to subjects outside the active semester.
final allSubjectsProvider = StreamProvider<List<Subject>>((ref) {
  return ref.watch(subjectRepositoryProvider).watchAll();
});

final subjectCommandProvider =
    AsyncNotifierProvider<SubjectCommandController, void>(
      SubjectCommandController.new,
    );

final class SubjectCommandController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> create(NewSubject subject) =>
      _run(() => ref.read(subjectRepositoryProvider).create(subject));

  Future<bool> updateSubject(Subject subject) =>
      _run(() => ref.read(subjectRepositoryProvider).update(subject));

  Future<bool> setArchived(int id, {required bool archived}) => _run(
    () =>
        ref.read(subjectRepositoryProvider).setArchived(id, archived: archived),
  );

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
