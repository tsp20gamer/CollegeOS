import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/timetable/data/drift_timetable_importer.dart';
import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smart parser matches subjects, skips duplicates and warns overlaps', () {
    final now = DateTime.utc(2026, 8, 1);
    final subject = (
      id: 7,
      semesterId: 1,
      name: 'Mathematics',
      shortCode: 'MC',
      professor: 'Mrs. Aruna',
      room: '2009',
      attendanceTarget: .75,
      displayColor: 0xFF7367F0,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    final existing = (
      id: 9,
      semesterId: 1,
      subjectId: 7,
      weekday: DateTime.monday,
      startTime: 560,
      endTime: 610,
      room: '2009',
      note: '',
    );
    const csv =
        'Weekday,Start Time,End Time,Subject Name,Subject Code,Lecturer,Location,Notes\n'
        'Mon,9:20 AM,10:10 AM,Mathematics,MC,Mrs. Aruna,2009,duplicate\n'
        'Monday,09:40,10:30,"English, Communication",EC,Ms. Deepika,2009,overlap\n'
        'Tuesday,10.10 AM,11.00 AM,Programming,PPS,Ms. Lakshmi,Lab 2,\n'
        'Funday,11:00,12:00,Invalid,INV,,,bad day';

    final preview = const TimetableCsvParser().parse(
      fileName: 'semester.csv',
      contents: csv,
      subjects: [subject],
      existingEntries: [existing],
    );

    expect(preview.importCount, 2);
    expect(preview.duplicateCount, 1);
    expect(preview.overlapCount, 1);
    expect(preview.newSubjectCount, 2);
    expect(preview.issues.single.line, 5);
    expect(preview.candidates.first.matchedSubjectId, 7);
    expect(preview.candidates[1].row.subjectName, 'English, Communication');
  });

  test('import commits new subjects and timetable atomically', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 8, 1);
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
            createdAt: now,
            updatedAt: now,
          ),
        );
    final preview = const TimetableCsvParser().parse(
      fileName: 'semester.csv',
      contents:
          'Day,Start,End,Subject,Code,Professor,Room,Note\n'
          'Monday,9:20 AM,10:10 AM,Mathematics,MC,Mrs. Aruna,2009,\n'
          'Wednesday,11:00,11:50,Mathematics,MC,Mrs. Aruna,2009,Tutorial',
      subjects: const [],
      existingEntries: const [],
    );

    final result = await DriftTimetableImportCommitter(database).commit(
      semesterId: 1,
      semesterStart: DateTime(2026, 8, 13),
      semesterEnd: DateTime(2026, 12, 15),
      defaultAttendanceTarget: .8,
      preview: preview,
    );

    expect(result.subjectsCreated, 1);
    expect(result.entriesCreated, 2);
    final subjects = await database.select(database.subjects).get();
    final entries = await database.select(database.timetableEntries).get();
    expect(subjects.single.attendanceTarget, .8);
    expect(entries, hasLength(2));
    expect(entries.map((entry) => entry.subjectId).toSet(), {
      subjects.single.id,
    });
    expect(
      entries.every((entry) => entry.effectiveFrom == DateTime(2026, 8, 13)),
      isTrue,
    );
    expect(
      entries.every((entry) => entry.effectiveUntil == DateTime(2026, 12, 15)),
      isTrue,
    );
    expect(await database.passesForeignKeyCheck(), isTrue);
  });

  test('inactive semester rejects import without partial writes', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 8, 1);
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
            isActive: false,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final preview = const TimetableCsvParser().parse(
      fileName: 'semester.csv',
      contents: 'Day,Start,End,Subject\nMonday,09:00,10:00,Mathematics',
      subjects: const [],
      existingEntries: const [],
    );

    await expectLater(
      DriftTimetableImportCommitter(database).commit(
        semesterId: 1,
        semesterStart: DateTime(2026, 8, 13),
        semesterEnd: DateTime(2026, 12, 15),
        defaultAttendanceTarget: .75,
        preview: preview,
      ),
      throwsStateError,
    );
    expect(await database.select(database.subjects).get(), isEmpty);
    expect(await database.select(database.timetableEntries).get(), isEmpty);
  });
}
