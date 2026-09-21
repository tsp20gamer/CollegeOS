import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/academic_calendar_dao.dart';
import 'package:college_os/features/calendar/domain/academic_calendar_repository.dart';
import 'package:drift/drift.dart';

final class DriftAcademicCalendarRepository
    implements AcademicCalendarRepository {
  const DriftAcademicCalendarRepository(this._dao);

  final AcademicCalendarDao _dao;

  @override
  Stream<List<AcademicCalendarEvent>> watchForSemester(int semesterId) => _dao
      .watchForSemester(semesterId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<List<AcademicCalendarEvent>> loadForSemester(int semesterId) async =>
      (await _dao.loadForSemester(
        semesterId,
      )).map(_map).toList(growable: false);

  @override
  Future<int> create(NewAcademicCalendarEvent event) => _dao.insertEvent(
    AcademicCalendarEventsCompanion.insert(
      semesterId: event.semesterId,
      title: event.title.trim(),
      type: event.type,
      startDate: event.startDate,
      endDate: event.endDate,
      note: Value(event.note.trim()),
    ),
  );

  @override
  Future<void> update(AcademicCalendarEvent event) async {
    final changed = await _dao.updateEvent(
      AcademicCalendarEventRow(
        id: event.id,
        semesterId: event.semesterId,
        title: event.title.trim(),
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
        note: event.note.trim(),
        createdAt: event.createdAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    if (!changed) throw StateError('Calendar event ${event.id} was not found.');
  }

  @override
  Future<void> delete(int id) async {
    final changed = await _dao.deleteEvent(id);
    if (changed == 0) throw StateError('Calendar event $id was not found.');
  }

  AcademicCalendarEvent _map(AcademicCalendarEventRow row) => (
    id: row.id,
    semesterId: row.semesterId,
    title: row.title,
    type: row.type,
    startDate: row.startDate,
    endDate: row.endDate,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
