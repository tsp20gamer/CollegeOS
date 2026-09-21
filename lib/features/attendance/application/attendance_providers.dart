import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_engine_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:college_os/features/attendance/domain/weekly_attendance_summary.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';

final weeklyAttendanceSummaryProvider = Provider<WeeklyAttendanceSummary?>((
  ref,
) {
  final semester = ref.watch(activeSemesterProvider).value;
  final snapshot = ref.watch(attendanceEngineProvider).value;
  final now = ref.watch(localMinuteProvider).value ?? DateTime.now();
  if (semester == null || snapshot == null) return null;
  return WeeklyAttendanceSummary.build(
    snapshot: snapshot,
    semester: semester,
    now: now,
  );
});

final attendanceEngineProvider = StreamProvider<AttendanceEngineSnapshot?>((
  ref,
) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(null);
  return ref
      .watch(attendanceEngineRepositoryProvider)
      .watchForSemester(semester.id)
      .map<AttendanceEngineSnapshot?>((value) => value);
});

final attendanceDayProvider =
    Provider.family<AsyncValue<AttendanceDay?>, DateTime>((ref, date) {
      final semester = ref.watch(activeSemesterProvider);
      final snapshot = ref.watch(attendanceEngineProvider);
      if (semester.isLoading || snapshot.isLoading) {
        return const AsyncLoading();
      }
      if (semester.hasError) {
        return AsyncError(semester.error!, semester.stackTrace!);
      }
      if (snapshot.hasError) {
        return AsyncError(snapshot.error!, snapshot.stackTrace!);
      }
      if (semester.value == null || snapshot.value == null) {
        return const AsyncData(null);
      }
      return AsyncData(
        AttendanceScheduleEngine.day(
          snapshot: snapshot.value!,
          semester: semester.value!,
          date: date,
        ),
      );
    });

final attendanceSubjectsProvider =
    Provider<AsyncValue<List<SubjectAttendanceResult>>>((ref) {
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
        return const AsyncData([]);
      }
      return AsyncData(
        AttendanceScheduleEngine.subjectResults(
          snapshot: snapshot.value!,
          semester: semester.value!,
        ),
      );
    });

final subjectAttendanceProvider =
    Provider.family<AsyncValue<SubjectAttendanceResult?>, int>((
      ref,
      subjectId,
    ) {
      return ref.watch(attendanceSubjectsProvider).whenData((values) {
        for (final value in values) {
          if (value.subject.id == subjectId) return value;
        }
        return null;
      });
    });

final pendingAttendanceProvider = Provider<AsyncValue<int>>((ref) {
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
    return const AsyncData(0);
  }
  return AsyncData(
    AttendanceScheduleEngine.pendingCount(
      snapshot: snapshot.value!,
      semester: semester.value!,
      through: DateTime.now(),
    ),
  );
});

final pendingAttendanceGroupsProvider =
    Provider<AsyncValue<List<PendingAttendanceGroup>>>((ref) {
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
        return const AsyncData([]);
      }
      return AsyncData(
        AttendanceScheduleEngine.pendingGroups(
          snapshot: snapshot.value!,
          semester: semester.value!,
          through: DateTime.now(),
        ),
      );
    });

final attendanceCommandProvider =
    AsyncNotifierProvider<AttendanceCommandController, void>(
      AttendanceCommandController.new,
    );

final attendanceUndoProvider =
    NotifierProvider<AttendanceUndoController, AttendanceUndo?>(
      AttendanceUndoController.new,
    );

class AttendanceUndoController extends Notifier<AttendanceUndo?> {
  @override
  AttendanceUndo? build() => null;
  void remember(AttendanceUndo action) => state = action;
  void clear() => state = null;
}

final class AttendanceCommandController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> markSession(
    ProjectedClassSession session,
    int semesterId,
    ClassAttendanceStatus status, {
    String note = '',
  }) => _runUndoable(
    () => ref
        .read(attendanceEngineRepositoryProvider)
        .markSession(session, semesterId, status, note: note),
  );

  Future<bool> markPendingGroup(
    PendingAttendanceGroup group,
    int semesterId,
    ClassAttendanceStatus status,
  ) => _runUndoable(
    () => ref
        .read(attendanceEngineRepositoryProvider)
        .markWholeDay(group.sessions, semesterId, status),
  );

  Future<bool> markWholeDay(
    AttendanceDay day,
    int semesterId,
    ClassAttendanceStatus status,
  ) => _runUndoable(
    () => ref
        .read(attendanceEngineRepositoryProvider)
        .markWholeDay(day.sessions, semesterId, status),
  );

  Future<bool> markHoliday(int semesterId, DateTime date) => _run(
    () => ref
        .read(attendanceEngineRepositoryProvider)
        .setDayOverride(
          semesterId: semesterId,
          date: date,
          type: CalendarDayOverrideType.holiday,
        ),
  );

  Future<bool> undoHoliday(int semesterId, DateTime date) => _run(
    () => ref
        .read(attendanceEngineRepositoryProvider)
        .clearDayOverride(semesterId, date),
  );

  Future<bool> clearSession(int attendanceId) => _run(
    () =>
        ref.read(attendanceEngineRepositoryProvider).clearSession(attendanceId),
  );

  Future<bool> _run(Future<Object?> Function() action) async {
    if (state.isLoading) return false;
    ref.read(attendanceUndoProvider.notifier).clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> _runUndoable(Future<AttendanceUndo> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final undo = await action();
      ref.read(attendanceUndoProvider.notifier).remember(undo);
    });
    return !state.hasError;
  }
}
