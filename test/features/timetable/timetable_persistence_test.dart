import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/timetable/data/drift_timetable_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftTimetableRepository repository;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTimetableRepository(database.timetableDao);
    semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
      ),
    );
    subjectId = await database.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semesterId,
        name: 'Operating Systems',
        displayColor: 0xFF2563EB,
      ),
    );
  });

  tearDown(() => database.close());

  test(
    'creates, chronologically queries, updates, and deletes entries',
    () async {
      final lateId = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.tuesday,
        startTime: 11 * 60,
        endTime: 12 * 60,
        room: ' Lab 4 ',
        note: ' Practical ',
      ));
      final earlyId = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'A-101',
        note: '',
      ));

      final rows = await repository.watchForSemester(semesterId).first;
      expect(rows.map((entry) => entry.id), [earlyId, lateId]);
      expect(rows.last.room, 'Lab 4');
      expect(rows.last.note, 'Practical');

      final changed = rows.last;
      await repository.update((
        id: changed.id,
        semesterId: changed.semesterId,
        subjectId: changed.subjectId,
        weekday: DateTime.wednesday,
        startTime: 13 * 60,
        endTime: 14 * 60,
        room: 'B-204',
        note: 'Updated',
      ));
      final updated =
          (await repository.watchForSemester(semesterId).first).last;
      expect(updated.weekday, DateTime.wednesday);
      expect(updated.room, 'B-204');

      await repository.delete(earlyId);
      expect(await repository.watchForSemester(semesterId).first, hasLength(1));
    },
  );

  test('enforces valid time ranges and subject relationships', () async {
    expect(
      () => repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 10 * 60,
        endTime: 9 * 60,
        room: '',
        note: '',
      )),
      throwsA(anything),
    );
    expect(
      () => repository.create((
        semesterId: semesterId,
        subjectId: 999,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: '',
        note: '',
      )),
      throwsA(anything),
    );
  });

  test(
    'future schedule changes preserve historical marked attendance',
    () async {
      final physicsId = await database.subjectsDao.insertSubject(
        SubjectsCompanion.insert(
          semesterId: semesterId,
          name: 'Physics',
          displayColor: 0xFF7C3AED,
        ),
      );
      final originalId = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'A-101',
        note: '',
      ));
      final historicalDate = DateTime(2026, 9, 28);
      await database.attendanceEngineDao.upsertAttendance(
        ScheduledClassAttendanceCompanion.insert(
          semesterId: semesterId,
          timetableEntryId: Value(originalId),
          subjectId: subjectId,
          date: historicalDate,
          startTime: 9 * 60,
          endTime: 10 * 60,
          attendanceStatus: ClassAttendanceStatus.present,
        ),
      );

      await repository.update((
        id: originalId,
        semesterId: semesterId,
        subjectId: physicsId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'Lab 1',
        note: 'October schedule',
      ), effectiveFrom: DateTime(2026, 10, 1));

      final versions = await database.timetableDao
          .watchForSemester(semesterId)
          .first;
      expect(versions, hasLength(2));
      final oldVersion = versions.singleWhere((row) => row.id == originalId);
      final newVersion = versions.singleWhere((row) => row.id != originalId);
      expect(oldVersion.subjectId, subjectId);
      expect(oldVersion.effectiveUntil, DateTime(2026, 9, 30));
      expect(newVersion.subjectId, physicsId);
      expect(newVersion.effectiveFrom, DateTime(2026, 10, 1));

      final attendance = await database
          .select(database.scheduledClassAttendance)
          .get();
      expect(attendance, hasLength(1));
      expect(attendance.single.subjectId, subjectId);
      expect(attendance.single.timetableEntryId, originalId);
      expect(attendance.single.date, historicalDate);

      await repository.delete(
        newVersion.id,
        effectiveFrom: DateTime(2026, 11, 1),
      );
      final afterDelete = await database.timetableDao
          .watchForSemester(semesterId)
          .first;
      expect(
        afterDelete
            .singleWhere((row) => row.id == newVersion.id)
            .effectiveUntil,
        DateTime(2026, 10, 31),
      );
      expect(
        await database.select(database.scheduledClassAttendance).get(),
        hasLength(1),
      );
    },
  );

  test('one-day extra class appears only on its exception date', () async {
    final date = DateTime(2026, 9, 15);
    final id = await repository.createOneDay((
      semesterId: semesterId,
      subjectId: subjectId,
      weekday: date.weekday,
      startTime: 14 * 60,
      endTime: 15 * 60,
      room: 'Extra Lab',
      note: 'One-day workshop',
    ), date);

    final onDate = await repository
        .watchForSemester(semesterId, effectiveOn: date)
        .first;
    final dayBefore = await repository
        .watchForSemester(
          semesterId,
          effectiveOn: date.subtract(const Duration(days: 1)),
        )
        .first;
    final dayAfter = await repository
        .watchForSemester(
          semesterId,
          effectiveOn: date.add(const Duration(days: 1)),
        )
        .first;

    expect(onDate.single.id, id);
    expect(onDate.single.room, 'Extra Lab');
    expect(dayBefore, isEmpty);
    expect(dayAfter, isEmpty);
    final stored =
        (await database.timetableDao.watchForSemester(semesterId).first).single;
    expect(stored.effectiveFrom, date);
    expect(stored.effectiveUntil, date);
  });
}
