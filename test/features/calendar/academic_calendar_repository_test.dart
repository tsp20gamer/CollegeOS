import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/calendar/data/drift_academic_calendar_repository.dart';
import 'package:college_os/features/calendar/domain/academic_calendar_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates updates watches and deletes calendar ranges', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
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
            createdAt: DateTime.utc(2026, 8, 13),
            updatedAt: DateTime.utc(2026, 8, 13),
          ),
        );
    final repository = DriftAcademicCalendarRepository(
      database.academicCalendarDao,
    );
    final values = <List<AcademicCalendarEvent>>[];
    final subscription = repository.watchForSemester(1).listen(values.add);
    addTearDown(subscription.cancel);

    final id = await repository.create((
      semesterId: 1,
      title: 'Dussehra vacation',
      type: AcademicCalendarEventType.holiday,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 5),
      note: 'College holiday',
    ));
    final created = (await repository.loadForSemester(1)).single;
    expect(created.id, id);
    expect(created.endDate, DateTime(2026, 10, 5));

    await repository.update((
      id: created.id,
      semesterId: created.semesterId,
      title: 'Dussehra break',
      type: created.type,
      startDate: created.startDate,
      endDate: DateTime(2026, 10, 6),
      note: created.note,
      createdAt: created.createdAt,
      updatedAt: created.updatedAt,
    ));
    expect(
      (await repository.loadForSemester(1)).single.title,
      'Dussehra break',
    );

    await repository.delete(id);
    expect(await repository.loadForSemester(1), isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(values, isNotEmpty);
  });

  test('rejects an event ending before it starts', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
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
            createdAt: DateTime.utc(2026, 8, 13),
            updatedAt: DateTime.utc(2026, 8, 13),
          ),
        );
    final repository = DriftAcademicCalendarRepository(
      database.academicCalendarDao,
    );
    await expectLater(
      repository.create((
        semesterId: 1,
        title: 'Invalid',
        type: AcademicCalendarEventType.event,
        startDate: DateTime(2026, 9, 2),
        endDate: DateTime(2026, 9, 1),
        note: '',
      )),
      throwsA(anything),
    );
  });
}
