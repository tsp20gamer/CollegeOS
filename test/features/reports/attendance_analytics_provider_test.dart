import 'dart:async';

import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_engine_repository.dart';
import 'package:college_os/features/reports/application/attendance_analytics_providers.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all-time provider reacts to changes from an older semester', () async {
    final semesters = [_semester(2, active: true), _semester(1)];
    final repository = _ReactiveAttendanceRepository({
      1: _snapshot(1, ClassAttendanceStatus.present),
      2: _snapshot(2, ClassAttendanceStatus.absent),
    });
    addTearDown(repository.close);
    final container = ProviderContainer(
      overrides: [
        semestersProvider.overrideWith((ref) => Stream.value(semesters)),
        activeSemesterProvider.overrideWith(
          (ref) => Stream.value(semesters.first),
        ),
        attendanceEngineRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      allSemesterAttendanceProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final initial = await _waitForBundles(container, 2);
    expect(repository.watchCount(2), 1);
    expect(repository.watchCount(1), 1);
    expect(
      initial
          .firstWhere((bundle) => bundle.semester.id == 1)
          .snapshot
          .attendance
          .single
          .status,
      ClassAttendanceStatus.present,
    );

    repository.emit(1, _snapshot(1, ClassAttendanceStatus.absent));
    final changed = await _waitForStatus(
      container,
      semesterId: 1,
      status: ClassAttendanceStatus.absent,
    );
    expect(changed, isTrue);
  });
}

Future<List<SemesterAttendanceBundle>> _waitForBundles(
  ProviderContainer container,
  int count,
) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    final value = container.read(allSemesterAttendanceProvider).value;
    if (value != null && value.length == count) return value;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('All-semester attendance did not become ready.');
}

Future<bool> _waitForStatus(
  ProviderContainer container, {
  required int semesterId,
  required ClassAttendanceStatus status,
}) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    final values = container.read(allSemesterAttendanceProvider).value;
    final bundle = values
        ?.where((item) => item.semester.id == semesterId)
        .firstOrNull;
    if (bundle?.snapshot.attendance.single.status == status) return true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return false;
}

Semester _semester(int id, {bool active = false}) => (
  id: id,
  name: 'Semester $id',
  semesterNumber: id,
  academicYear: '2026-2027',
  startDate: DateTime(2026, id, 1),
  endDate: DateTime(2026, id + 1, 1),
  isActive: active,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

AttendanceEngineSnapshot _snapshot(
  int semesterId,
  ClassAttendanceStatus status,
) => AttendanceEngineSnapshot(
  subjects: const [],
  timetable: const [],
  attendance: [
    (
      id: semesterId,
      semesterId: semesterId,
      timetableEntryId: null,
      subjectId: semesterId,
      date: DateTime(2026, semesterId, 1),
      startTime: 540,
      endTime: 600,
      status: status,
      note: '',
      manuallyModified: true,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
  ],
  overrides: const [],
);

final class _ReactiveAttendanceRepository
    implements AttendanceEngineRepository {
  _ReactiveAttendanceRepository(Map<int, AttendanceEngineSnapshot> initial)
    : _current = {...initial};

  final Map<int, AttendanceEngineSnapshot> _current;
  final Map<int, StreamController<AttendanceEngineSnapshot>> _controllers = {};
  final Map<int, int> _watchCounts = {};

  @override
  Stream<AttendanceEngineSnapshot> watchForSemester(int semesterId) async* {
    _watchCounts.update(semesterId, (value) => value + 1, ifAbsent: () => 1);
    yield _current[semesterId]!;
    yield* (_controllers[semesterId] ??=
            StreamController<AttendanceEngineSnapshot>.broadcast())
        .stream;
  }

  int watchCount(int semesterId) => _watchCounts[semesterId] ?? 0;

  void emit(int semesterId, AttendanceEngineSnapshot snapshot) {
    _current[semesterId] = snapshot;
    _controllers[semesterId]!.add(snapshot);
  }

  Future<void> close() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
  }

  @override
  Future<AttendanceEngineSnapshot> loadForSemester(int semesterId) async =>
      _current[semesterId]!;

  @override
  Future<void> clearDayOverride(int semesterId, DateTime date) =>
      throw UnimplementedError();
  @override
  Future<void> clearSession(int attendanceId) => throw UnimplementedError();
  @override
  Future<AttendanceUndo> markSession(
    ProjectedClassSession session,
    int semesterId,
    ClassAttendanceStatus status, {
    String note = '',
  }) => throw UnimplementedError();
  @override
  Future<AttendanceUndo> markWholeDay(
    List<ProjectedClassSession> sessions,
    int semesterId,
    ClassAttendanceStatus status,
  ) => throw UnimplementedError();
  @override
  Future<void> setDayOverride({
    required int semesterId,
    required DateTime date,
    required CalendarDayOverrideType type,
    String note = '',
  }) => throw UnimplementedError();
}
