import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/timetable_dao.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:drift/drift.dart';

final class DriftTimetableRepository implements TimetableRepository {
  DriftTimetableRepository(this._dao);

  final TimetableDao _dao;

  @override
  Stream<List<TimetableEntry>> watchForSemester(
    int semesterId, {
    DateTime? effectiveOn,
  }) => _dao.watchForSemester(semesterId).map((rows) {
    final date = effectiveOn ?? DateTime.now();
    return rows
        .where(
          (row) =>
              (row.effectiveFrom == null ||
                  !date.isBefore(row.effectiveFrom!)) &&
              (row.effectiveUntil == null ||
                  !date.isAfter(row.effectiveUntil!)),
        )
        .map(_map)
        .toList(growable: false);
  });

  @override
  Future<int> create(NewTimetableEntry entry) async {
    final semesterStart = await _dao.semesterStart(entry.semesterId);
    return _dao.insertEntry(
      TimetableEntriesCompanion.insert(
        semesterId: entry.semesterId,
        subjectId: entry.subjectId,
        weekday: entry.weekday,
        startTime: entry.startTime,
        endTime: entry.endTime,
        room: Value(entry.room.trim()),
        note: Value(entry.note.trim()),
        reminderMinutesBefore: Value(entry.reminderMinutesBefore),
        effectiveFrom: Value(semesterStart),
      ),
    );
  }

  @override
  Future<int> createOneDay(NewTimetableEntry entry, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _dao.insertEntry(
      TimetableEntriesCompanion.insert(
        semesterId: entry.semesterId,
        subjectId: entry.subjectId,
        weekday: day.weekday,
        startTime: entry.startTime,
        endTime: entry.endTime,
        room: Value(entry.room.trim()),
        note: Value(entry.note.trim()),
        reminderMinutesBefore: Value(entry.reminderMinutesBefore),
        effectiveFrom: Value(day),
        effectiveUntil: Value(day),
      ),
    );
  }

  @override
  Future<void> update(TimetableEntry entry, {DateTime? effectiveFrom}) async {
    await _dao.versionEntry(
      TimetableEntriesCompanion.insert(
        id: Value(entry.id),
        semesterId: entry.semesterId,
        subjectId: entry.subjectId,
        weekday: entry.weekday,
        startTime: entry.startTime,
        endTime: entry.endTime,
        room: Value(entry.room.trim()),
        note: Value(entry.note.trim()),
        reminderMinutesBefore: Value(entry.reminderMinutesBefore),
      ),
      effectiveFrom ?? DateTime.now(),
    );
  }

  @override
  Future<void> delete(int id, {DateTime? effectiveFrom}) async =>
      _dao.endEntry(id, effectiveFrom ?? DateTime.now());

  TimetableEntry _map(TimetableEntryRow row) => (
    id: row.id,
    semesterId: row.semesterId,
    subjectId: row.subjectId,
    weekday: row.weekday,
    startTime: row.startTime,
    endTime: row.endTime,
    room: row.room,
    note: row.note,
    reminderMinutesBefore: row.reminderMinutesBefore,
  );
}
