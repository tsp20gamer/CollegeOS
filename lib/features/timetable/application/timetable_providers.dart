import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localMinuteProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

final timetableEntriesProvider = StreamProvider<List<TimetableEntry>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  final now = DateTime.now();
  final effectiveDate = now.isBefore(semester.startDate)
      ? semester.startDate
      : now.isAfter(semester.endDate)
      ? semester.endDate
      : now;
  return ref
      .watch(timetableRepositoryProvider)
      .watchForSemester(semester.id, effectiveOn: effectiveDate);
});

final timetableEntriesOnProvider =
    StreamProvider.family<List<TimetableEntry>, DateTime>((ref, date) {
      final semester = ref.watch(activeSemesterProvider).value;
      if (semester == null) return Stream.value(const []);
      return ref
          .watch(timetableRepositoryProvider)
          .watchForSemester(semester.id, effectiveOn: date);
    });

final timetableScheduleProvider = Provider<AsyncValue<List<ScheduledClass>>>((
  ref,
) {
  final entries = ref.watch(timetableEntriesProvider);
  final subjects = ref.watch(activeSemesterSubjectsProvider);
  return entries.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (entryRows) => subjects.when(
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
      data: (subjectRows) {
        final byId = {
          for (final subject in subjectRows)
            if (!subject.isArchived) subject.id: subject,
        };
        return AsyncData(
          entryRows
              .where((entry) => byId.containsKey(entry.subjectId))
              .map(
                (entry) => ScheduledClass(
                  entry: entry,
                  subject: byId[entry.subjectId]!,
                ),
              )
              .toList(growable: false),
        );
      },
    ),
  );
});

final nextClassProvider = Provider<AsyncValue<NextClassResult>>((ref) {
  final now = ref.watch(localMinuteProvider).value ?? DateTime.now();
  final semester = ref.watch(activeSemesterProvider);
  final snapshot = ref.watch(attendanceEngineProvider);
  if (semester.isLoading || snapshot.isLoading) return const AsyncLoading();
  if (semester.hasError) {
    return AsyncError(semester.error!, semester.stackTrace!);
  }
  if (snapshot.hasError) {
    return AsyncError(snapshot.error!, snapshot.stackTrace!);
  }
  if (semester.value == null || snapshot.value == null) {
    return AsyncData(NextClassService.calculate(schedule: const [], now: now));
  }
  return AsyncData(
    AttendanceAwareNextClassService.calculate(
      snapshot: snapshot.value!,
      semester: semester.value!,
      now: now,
    ),
  );
});

final timetableCommandProvider =
    AsyncNotifierProvider<TimetableCommandController, void>(
      TimetableCommandController.new,
    );

final class TimetableCommandController extends AsyncNotifier<void> {
  /// True when the student asked for a class reminder and Android refused
  /// notification permission, so the UI can explain why nothing will arrive.
  bool reminderPermissionDenied = false;

  @override
  Future<void> build() async {}

  Future<bool> create(NewTimetableEntry entry) => _run(() async {
    await _ensureReminderDelivery(entry.reminderMinutesBefore);
    await ref.read(timetableRepositoryProvider).create(entry);
  });

  Future<bool> createOneDay(NewTimetableEntry entry, DateTime date) =>
      _run(() async {
        await _ensureReminderDelivery(entry.reminderMinutesBefore);
        await ref.read(timetableRepositoryProvider).createOneDay(entry, date);
      });

  Future<bool> updateEntry(TimetableEntry entry, {DateTime? effectiveFrom}) =>
      _run(() async {
        await _ensureReminderDelivery(entry.reminderMinutesBefore);
        await ref
            .read(timetableRepositoryProvider)
            .update(entry, effectiveFrom: effectiveFrom);
      });

  /// Permission is requested in context, only when the class has a reminder.
  ///
  /// The projection itself is reactive: the class reminder provider rebuilds
  /// from the stored timetable, so a saved reminder is scheduled without a
  /// second code path that could drift from startup reconciliation. A platform
  /// failure never blocks the class itself from being saved.
  Future<void> _ensureReminderDelivery(int? minutesBefore) async {
    if (minutesBefore == null) {
      reminderPermissionDenied = false;
      return;
    }
    try {
      reminderPermissionDenied = !await ref
          .read(notificationCoordinatorProvider)
          .ensureEnabledForClassReminder(minutesBefore);
    } catch (_) {
      reminderPermissionDenied = true;
    }
  }

  Future<bool> deleteEntry(int id, {DateTime? effectiveFrom}) => _run(
    () => ref
        .read(timetableRepositoryProvider)
        .delete(id, effectiveFrom: effectiveFrom),
  );

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
