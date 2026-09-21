import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/data/drift_attendance_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftAttendanceRepository repository;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAttendanceRepository(database.attendanceDao);
    semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
        isActive: const Value(true),
      ),
    );
    subjectId = await database.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semesterId,
        name: 'Mathematics',
        shortCode: const Value('MATH'),
        attendanceTarget: const Value(0.8),
        displayColor: 0xFF2563EB,
      ),
    );
  });

  tearDown(() => database.close());

  test('creates, updates, and deletes the source session record', () async {
    final id = await repository.create((
      subjectId: subjectId,
      date: DateTime(2026, 8, 12, 21, 30),
      period: 2,
      status: AttendanceStatus.present,
      note: 'Lecture',
    ));

    final original = (await repository.watchForSubject(subjectId).first).single;
    expect(original.id, id);
    expect(original.date, DateTime(2026, 8, 12));
    expect(original.status, AttendanceStatus.present);

    await repository.update((
      id: original.id,
      subjectId: original.subjectId,
      date: original.date,
      period: 3,
      status: AttendanceStatus.absent,
      note: 'Corrected',
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
    ));
    final updated = (await repository.watchForSubject(subjectId).first).single;
    expect(updated.period, 3);
    expect(updated.status, AttendanceStatus.absent);
    expect(updated.note, 'Corrected');

    await repository.delete(id);
    expect(await repository.watchForSubject(subjectId).first, isEmpty);
  });

  test(
    'semester summaries react and exclude cancelled and archived subjects',
    () async {
      await repository.create((
        subjectId: subjectId,
        date: DateTime(2026, 8, 12),
        period: 1,
        status: AttendanceStatus.present,
        note: '',
      ));
      await repository.create((
        subjectId: subjectId,
        date: DateTime(2026, 8, 13),
        period: 1,
        status: AttendanceStatus.absent,
        note: '',
      ));
      await repository.create((
        subjectId: subjectId,
        date: DateTime(2026, 8, 14),
        period: 1,
        status: AttendanceStatus.cancelled,
        note: '',
      ));

      final summary =
          (await repository.watchSummariesForSemester(semesterId).first).single;
      expect(summary.name, 'Mathematics');
      expect(summary.attendanceTarget, 0.8);
      expect(summary.counts, (present: 1, absent: 1, cancelled: 1, held: 2));

      await database.subjectsDao.setArchived(subjectId, archived: true);
      expect(
        await repository.watchSummariesForSemester(semesterId).first,
        isEmpty,
      );
    },
  );

  test('foreign keys reject sessions for a missing subject', () async {
    expect(
      () => repository.create((
        subjectId: 999,
        date: DateTime(2026, 8, 12),
        period: 1,
        status: AttendanceStatus.present,
        note: '',
      )),
      throwsA(anything),
    );
  });

  test(
    'date query and likely-duplicate lookup use local calendar dates',
    () async {
      await repository.create((
        subjectId: subjectId,
        date: DateTime(2026, 8, 12, 23, 59),
        period: 2,
        status: AttendanceStatus.present,
        note: '',
      ));
      await repository.create((
        subjectId: subjectId,
        date: DateTime(2026, 8, 13),
        period: 2,
        status: AttendanceStatus.absent,
        note: '',
      ));

      final onDate = await repository.watchForDate(DateTime(2026, 8, 12)).first;
      expect(onDate, hasLength(1));
      expect(onDate.single.status, AttendanceStatus.present);
      expect(
        await repository.findLikelyDuplicate(
          subjectId: subjectId,
          date: DateTime(2026, 8, 12, 1),
          period: 2,
        ),
        isNotNull,
      );
      expect(
        await repository.findLikelyDuplicate(
          subjectId: subjectId,
          date: DateTime(2026, 8, 12),
          period: 3,
        ),
        isNull,
      );
    },
  );

  test('large attendance histories retain counts and ordering', () async {
    const sessionCount = 1800;
    final statuses = AttendanceStatus.values;
    await database.batch((batch) {
      batch.insertAll(
        database.attendanceSessions,
        List.generate(sessionCount, (index) {
          return AttendanceSessionsCompanion.insert(
            subjectId: subjectId,
            date: DateTime(2020, 1, 1).add(Duration(days: index ~/ 8)),
            period: (index % 8) + 1,
            status: statuses[index % statuses.length],
          );
        }),
      );
    });

    final history = await repository.watchForSubject(subjectId).first;
    final summary = await repository.watchCountsForSubject(subjectId).first;

    expect(history, hasLength(sessionCount));
    expect(history.first.date.isBefore(history.last.date), isFalse);
    expect(summary.present, 600);
    expect(summary.absent, 600);
    expect(summary.cancelled, 600);
    expect(summary.held, 1200);
  });
}
