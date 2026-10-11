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
        reminderMinutesBefore: null,
      ));
      final earlyId = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'A-101',
        note: '',
        reminderMinutesBefore: null,
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
        reminderMinutesBefore: null,
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
        reminderMinutesBefore: null,
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
        reminderMinutesBefore: null,
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
        reminderMinutesBefore: null,
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
        reminderMinutesBefore: null,
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
      reminderMinutesBefore: null,
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

  test(
    'stores a class reminder and carries it across schedule versions',
    () async {
      final id = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'A-101',
        note: '',
        reminderMinutesBefore: 45,
      ));
      expect(
        (await repository.watchForSemester(semesterId).first)
            .single
            .reminderMinutesBefore,
        45,
        reason: 'a custom 45-minute lead time round-trips',
      );

      // A schedule change from a later date creates a new version of the class,
      // which must carry the reminder forward instead of dropping it.
      await repository.update((
        id: id,
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'B-204',
        note: '',
        reminderMinutesBefore: 45,
      ), effectiveFrom: DateTime(2026, 10, 1));
      final versions = await database.timetableDao
          .watchForSemester(semesterId)
          .first;
      expect(versions, hasLength(2));
      expect(
        versions.map((row) => row.reminderMinutesBefore),
        everyElement(45),
        reason: 'both the historical and the current version keep the reminder',
      );

      // Clearing the reminder is a normal value, not a special case.
      final current = versions.singleWhere(
        (row) => row.effectiveFrom == DateTime(2026, 10, 1),
      );
      await repository.update((
        id: current.id,
        semesterId: current.semesterId,
        subjectId: current.subjectId,
        weekday: current.weekday,
        startTime: current.startTime,
        endTime: current.endTime,
        room: current.room,
        note: current.note,
        reminderMinutesBefore: null,
      ), effectiveFrom: DateTime(2026, 10, 5));
      expect(
        (await repository
                .watchForSemester(
                  semesterId,
                  effectiveOn: DateTime(2026, 10, 6),
                )
                .first)
            .single
            .reminderMinutesBefore,
        equals(null),
      );

      // The database enforces the same range the form does.
      expect(
        () => repository.create((
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: DateTime.tuesday,
          startTime: 9 * 60,
          endTime: 10 * 60,
          room: '',
          note: '',
          reminderMinutesBefore: 20000,
        )),
        throwsA(anything),
        reason: 'a lead time beyond seven days is rejected by the schema',
      );
    },
  );

  test(
    'applying one reminder time rewrites current and future classes only',
    () async {
      final blank = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: 'A-101',
        note: 'Lecture',
        reminderMinutesBefore: null,
      ));
      final withOwn = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        weekday: DateTime.tuesday,
        startTime: 11 * 60,
        endTime: 12 * 60,
        room: 'B-204',
        note: 'Lab',
        reminderMinutesBefore: 5,
      ));
      // A class whose effectiveness already ended cannot remind anyone again.
      final ended = await database.timetableDao.insertEntry(
        TimetableEntriesCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: DateTime.friday,
          startTime: 15 * 60,
          endTime: 16 * 60,
          reminderMinutesBefore: const Value(45),
          effectiveFrom: Value(DateTime(2026, 8, 1)),
          effectiveUntil: Value(DateTime(2026, 9, 30)),
        ),
      );
      // A second semester keeps its own reminders.
      final otherSemesterId = await database.semestersDao.insertSemester(
        SemestersCompanion.insert(
          name: 'Semester 2',
          semesterNumber: 2,
          academicYear: '2026-2027',
          startDate: DateTime(2027, 1, 5),
          endDate: DateTime(2027, 5, 30),
        ),
      );
      final otherSubjectId = await database.subjectsDao.insertSubject(
        SubjectsCompanion.insert(
          semesterId: otherSemesterId,
          name: 'Networks',
          displayColor: 0xFF0EA5E9,
        ),
      );
      final other = await repository.create((
        semesterId: otherSemesterId,
        subjectId: otherSubjectId,
        weekday: DateTime.monday,
        startTime: 9 * 60,
        endTime: 10 * 60,
        room: '',
        note: '',
        reminderMinutesBefore: 5,
      ));

      final before = (await database.select(database.timetableEntries).get())
          .firstWhere((row) => row.id == withOwn);
      final updated = await repository.applyReminderToAll(semesterId, 30);

      expect(updated, 2, reason: 'the ended class is left out of the rewrite');
      final rows = {
        for (final row
            in await database.select(database.timetableEntries).get())
          row.id: row,
      };
      expect(rows[blank]!.reminderMinutesBefore, 30);
      expect(rows[withOwn]!.reminderMinutesBefore, 30);
      expect(
        rows[ended]!.reminderMinutesBefore,
        45,
        reason: 'a class that already ended keeps its own reminder',
      );
      expect(
        rows[other]!.reminderMinutesBefore,
        5,
        reason: 'another semester is never touched',
      );

      // Only the reminder changed: the class itself is preserved exactly.
      final after = rows[withOwn]!;
      expect(after.subjectId, before.subjectId);
      expect(after.weekday, before.weekday);
      expect(after.startTime, before.startTime);
      expect(after.endTime, before.endTime);
      expect(after.room, before.room);
      expect(after.note, before.note);
      expect(after.effectiveFrom, before.effectiveFrom);
      expect(after.effectiveUntil, before.effectiveUntil);
    },
  );

  test(
    'applying a reminder refuses a lead time the schema would reject',
    () async {
      expect(
        () => repository.applyReminderToAll(semesterId, 7 * 24 * 60 + 1),
        throwsArgumentError,
      );
    },
  );
}
