import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/semesters/data/drift_semester_rollover_service.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/semesters/domain/semester_rollover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final semestersProvider = StreamProvider<List<Semester>>(
  (ref) => ref.watch(semesterRepositoryProvider).watchAll(),
);

final semesterRolloverServiceProvider = Provider<SemesterRolloverService>(
  (ref) => DriftSemesterRolloverService(ref.watch(appDatabaseProvider)),
);

final semesterRolloverControllerProvider =
    AsyncNotifierProvider<SemesterRolloverController, void>(
      SemesterRolloverController.new,
    );

final class SemesterRolloverController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SemesterRolloverResult?> rollover(
    SemesterRolloverRequest request,
  ) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(semesterRolloverServiceProvider)
          .rollover(request);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final semesterControllerProvider =
    AsyncNotifierProvider<SemesterController, void>(SemesterController.new);

final class SemesterController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> create(NewSemester semester) =>
      _run(() => ref.read(semesterRepositoryProvider).create(semester));

  Future<bool> updateSemester(Semester semester) =>
      _run(() => ref.read(semesterRepositoryProvider).update(semester));

  Future<bool> setActive(int id) =>
      _run(() => ref.read(semesterRepositoryProvider).setActive(id));

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
