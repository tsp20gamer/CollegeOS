import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/academic_calendar_events.dart';
import 'package:drift/drift.dart';

part 'academic_calendar_dao.g.dart';

@DriftAccessor(tables: [AcademicCalendarEvents])
class AcademicCalendarDao extends DatabaseAccessor<AppDatabase>
    with _$AcademicCalendarDaoMixin {
  AcademicCalendarDao(super.attachedDatabase);

  Stream<List<AcademicCalendarEventRow>> watchForSemester(int semesterId) {
    final query = select(academicCalendarEvents)
      ..where((row) => row.semesterId.equals(semesterId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.startDate),
        (row) => OrderingTerm.asc(row.title),
      ]);
    return query.watch();
  }

  Future<List<AcademicCalendarEventRow>> loadForSemester(int semesterId) =>
      (select(academicCalendarEvents)
            ..where((row) => row.semesterId.equals(semesterId))
            ..orderBy([(row) => OrderingTerm.asc(row.startDate)]))
          .get();

  Future<int> insertEvent(AcademicCalendarEventsCompanion event) =>
      into(academicCalendarEvents).insert(event);

  Future<bool> updateEvent(AcademicCalendarEventRow event) =>
      update(academicCalendarEvents).replace(event);

  Future<int> deleteEvent(int id) =>
      (delete(academicCalendarEvents)..where((row) => row.id.equals(id))).go();
}
