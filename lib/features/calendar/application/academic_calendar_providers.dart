import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/calendar/data/drift_academic_calendar_repository.dart';
import 'package:college_os/features/calendar/domain/academic_calendar_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final academicCalendarRepositoryProvider = Provider<AcademicCalendarRepository>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    return DriftAcademicCalendarRepository(database.academicCalendarDao);
  },
);

final activeSemesterCalendarEventsProvider =
    StreamProvider<List<AcademicCalendarEvent>>((ref) {
      final semester = ref.watch(activeSemesterProvider).value;
      if (semester == null) return Stream.value(const []);
      return ref
          .watch(academicCalendarRepositoryProvider)
          .watchForSemester(semester.id);
    });

final academicCalendarCommandProvider =
    AsyncNotifierProvider<AcademicCalendarCommandController, void>(
      AcademicCalendarCommandController.new,
    );

final class AcademicCalendarCommandController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> create(NewAcademicCalendarEvent event) =>
      _run(() => ref.read(academicCalendarRepositoryProvider).create(event));

  Future<bool> updateEvent(AcademicCalendarEvent event) =>
      _run(() => ref.read(academicCalendarRepositoryProvider).update(event));

  Future<bool> deleteEvent(int id) =>
      _run(() => ref.read(academicCalendarRepositoryProvider).delete(id));

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
