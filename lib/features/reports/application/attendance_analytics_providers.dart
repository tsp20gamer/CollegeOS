import 'dart:async';

import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class SemesterAttendanceBundle {
  const SemesterAttendanceBundle({
    required this.semester,
    required this.snapshot,
  });

  final Semester semester;
  final AttendanceEngineSnapshot snapshot;
}

final allSemesterAttendanceProvider =
    StreamProvider<List<SemesterAttendanceBundle>>((ref) {
      final semesters = ref.watch(semestersProvider);
      if (semesters.isLoading) return Stream.value(const []);
      if (semesters.hasError) {
        return Stream.error(semesters.error!, semesters.stackTrace);
      }
      final activeSemesterState = ref.watch(activeSemesterProvider);
      if (activeSemesterState.isLoading) return Stream.value(const []);
      if (activeSemesterState.hasError) {
        return Stream.error(
          activeSemesterState.error!,
          activeSemesterState.stackTrace,
        );
      }
      final activeSemester = activeSemesterState.value;
      final activeSnapshot = ref.watch(attendanceEngineProvider);
      if (activeSemester != null && activeSnapshot.isLoading) {
        return Stream.value(const []);
      }
      if (activeSnapshot.hasError) {
        return Stream.error(activeSnapshot.error!, activeSnapshot.stackTrace);
      }
      final seeded = <int, AttendanceEngineSnapshot>{};
      if (activeSemester != null && activeSnapshot.value != null) {
        seeded[activeSemester.id] = activeSnapshot.value!;
      }
      return _combineSemesterStreams(
        semesters.value ?? const [],
        ref.watch(attendanceEngineRepositoryProvider).watchForSemester,
        seeded: seeded,
      );
    });

Stream<List<SemesterAttendanceBundle>> _combineSemesterStreams(
  List<Semester> semesters,
  Stream<AttendanceEngineSnapshot> Function(int semesterId) watch, {
  Map<int, AttendanceEngineSnapshot> seeded = const {},
}) {
  if (semesters.isEmpty) return Stream.value(const []);
  late final StreamController<List<SemesterAttendanceBundle>> controller;
  final snapshots = List<AttendanceEngineSnapshot?>.filled(
    semesters.length,
    null,
  );
  for (var index = 0; index < semesters.length; index++) {
    snapshots[index] = seeded[semesters[index].id];
  }
  final subscriptions = <StreamSubscription<AttendanceEngineSnapshot>>[];

  void emitWhenReady() {
    if (snapshots.any((snapshot) => snapshot == null) || controller.isClosed) {
      return;
    }
    controller.add([
      for (var index = 0; index < semesters.length; index++)
        SemesterAttendanceBundle(
          semester: semesters[index],
          snapshot: snapshots[index]!,
        ),
    ]);
  }

  controller = StreamController<List<SemesterAttendanceBundle>>(
    onListen: () {
      for (var index = 0; index < semesters.length; index++) {
        if (snapshots[index] != null) continue;
        subscriptions.add(
          watch(semesters[index].id).listen((snapshot) {
            snapshots[index] = snapshot;
            emitWhenReady();
          }, onError: controller.addError),
        );
      }
      emitWhenReady();
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}
