import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/data/drift_attendance_engine_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('attendance engine stream emits one coherent snapshot', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
        isActive: const Value(true),
      ),
    );
    final snapshot = await DriftAttendanceEngineRepository(
      database.attendanceEngineDao,
    ).watchForSemester(semesterId).first.timeout(const Duration(seconds: 5));
    expect(snapshot.subjects, isEmpty);
    expect(snapshot.attendance, isEmpty);
  });

  test(
    'attendance engine stream does not spin without database changes',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final semesterId = await database.semestersDao.insertSemester(
        SemestersCompanion.insert(
          name: 'Semester 1',
          semesterNumber: 1,
          academicYear: '2026-2027',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 12, 20),
        ),
      );
      var emissions = 0;
      final subscription = DriftAttendanceEngineRepository(
        database.attendanceEngineDao,
      ).watchForSemester(semesterId).listen((_) => emissions++);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(emissions, 1);
    },
  );

  test('Riverpod linked engine settles after active semester loads', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
        isActive: const Value(true),
      ),
    );
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    var notifications = 0;
    container.listen(
      attendanceEngineProvider,
      (_, _) => notifications++,
      fireImmediately: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(container.read(attendanceEngineProvider).value, isNotNull);
    expect(notifications, lessThan(10));
  });

  test('bulk upsert persists multiple scheduled marks', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
      ),
    );
    final subjectId = await database.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semesterId,
        name: 'Math',
        displayColor: 0xFF4758D6,
      ),
    );
    final first = await database.timetableDao.insertEntry(
      TimetableEntriesCompanion.insert(
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: 1,
        startTime: 540,
        endTime: 600,
      ),
    );
    final second = await database.timetableDao.insertEntry(
      TimetableEntriesCompanion.insert(
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: 1,
        startTime: 600,
        endTime: 660,
      ),
    );
    await database.attendanceEngineDao
        .upsertMany([
          for (final entry in [(first, 540), (second, 600)])
            ScheduledClassAttendanceCompanion.insert(
              semesterId: semesterId,
              timetableEntryId: Value(entry.$1),
              subjectId: subjectId,
              date: DateTime(2026, 8, 17),
              startTime: entry.$2,
              endTime: entry.$2 + 60,
              attendanceStatus: ClassAttendanceStatus.present,
            ),
        ])
        .timeout(const Duration(seconds: 5));
    expect(
      await database.select(database.scheduledClassAttendance).get(),
      hasLength(2),
    );
  });
}
