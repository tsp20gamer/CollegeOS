import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/semesters/data/drift_semester_rollover_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rollover preserves history and remaps copied timetable subjects',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final created = DateTime.utc(2026, 8, 1);
      await database
          .into(database.semesters)
          .insert(
            SemesterRow(
              id: 1,
              name: 'Semester 1',
              semesterNumber: 1,
              academicYear: '2026-2027',
              startDate: DateTime(2026, 8, 13),
              endDate: DateTime(2026, 12, 15),
              isActive: true,
              createdAt: created,
              updatedAt: created,
            ),
          );
      await database
          .into(database.subjects)
          .insert(
            SubjectRow(
              id: 10,
              semesterId: 1,
              name: 'Mathematics',
              shortCode: 'MC',
              professor: 'Mrs. Aruna',
              room: '2009',
              attendanceTarget: 0.75,
              displayColor: 0xFF6750A4,
              isArchived: false,
              createdAt: created,
              updatedAt: created,
            ),
          );
      await database
          .into(database.timetableEntries)
          .insert(
            TimetableEntryRow(
              id: 20,
              semesterId: 1,
              subjectId: 10,
              weekday: DateTime.monday,
              startTime: 560,
              endTime: 610,
              room: '2009',
              note: '',
              effectiveFrom: DateTime(2026, 8, 13),
              effectiveUntil: DateTime(2026, 12, 15),
            ),
          );

      final result = await DriftSemesterRolloverService(database).rollover((
        sourceSemesterId: 1,
        semesterNumber: 2,
        academicYear: '2026-2027',
        academicYearStartDate: DateTime(2026, 8, 13),
        academicYearEndDate: DateTime(2027, 4, 30),
        semesterStartDate: DateTime(2027, 1, 2),
        semesterEndDate: DateTime(2027, 4, 30),
        copySubjects: true,
        copyTimetable: true,
      ));

      expect(result.subjectsCopied, 1);
      expect(result.timetableEntriesCopied, 1);
      final semesters = await database.select(database.semesters).get();
      expect(semesters.singleWhere((item) => item.id == 1).isActive, isFalse);
      expect(
        semesters.singleWhere((item) => item.id == result.semesterId).isActive,
        isTrue,
      );
      final oldSubject = await (database.select(
        database.subjects,
      )..where((row) => row.id.equals(10))).getSingle();
      final newSubject = (await database.select(database.subjects).get())
          .singleWhere((item) => item.semesterId == result.semesterId);
      expect(oldSubject.name, newSubject.name);
      expect(newSubject.id, isNot(oldSubject.id));
      final newEntry = (await database.select(database.timetableEntries).get())
          .singleWhere((item) => item.semesterId == result.semesterId);
      expect(newEntry.subjectId, newSubject.id);
      expect(newEntry.effectiveFrom, DateTime(2027, 1, 2));
      expect(newEntry.effectiveUntil, DateTime(2027, 4, 30));
      expect(await database.passesForeignKeyCheck(), isTrue);
    },
  );

  test('invalid rollover rolls back active semester changes', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final created = DateTime.utc(2026, 8, 1);
    await database
        .into(database.semesters)
        .insert(
          SemesterRow(
            id: 1,
            name: 'Semester 1',
            semesterNumber: 1,
            academicYear: '2026-2027',
            startDate: DateTime(2026, 8, 13),
            endDate: DateTime(2026, 12, 15),
            isActive: true,
            createdAt: created,
            updatedAt: created,
          ),
        );
    await expectLater(
      DriftSemesterRolloverService(database).rollover((
        sourceSemesterId: 1,
        semesterNumber: 2,
        academicYear: '2026-2027',
        academicYearStartDate: DateTime(2026, 8, 13),
        academicYearEndDate: DateTime(2027, 4, 30),
        semesterStartDate: DateTime(2027, 5, 1),
        semesterEndDate: DateTime(2027, 6, 1),
        copySubjects: false,
        copyTimetable: false,
      )),
      throwsArgumentError,
    );
    expect(
      (await database.select(database.semesters).getSingle()).isActive,
      isTrue,
    );
  });
}
