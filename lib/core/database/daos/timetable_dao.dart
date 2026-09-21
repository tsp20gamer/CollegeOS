import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:college_os/core/database/tables/timetable_entries.dart';
import 'package:drift/drift.dart';

part 'timetable_dao.g.dart';

@DriftAccessor(tables: [TimetableEntries, Semesters])
class TimetableDao extends DatabaseAccessor<AppDatabase>
    with _$TimetableDaoMixin {
  TimetableDao(super.attachedDatabase);

  Stream<List<TimetableEntryRow>> watchForSemester(int semesterId) {
    final query = select(timetableEntries)
      ..where((row) => row.semesterId.equals(semesterId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.weekday),
        (row) => OrderingTerm.asc(row.startTime),
      ]);
    return query.watch();
  }

  Future<int> insertEntry(TimetableEntriesCompanion entry) =>
      into(timetableEntries).insert(entry);

  Future<bool> updateEntry(TimetableEntriesCompanion entry) =>
      update(timetableEntries).replace(entry);

  Future<int> deleteById(int id) =>
      (delete(timetableEntries)..where((row) => row.id.equals(id))).go();

  Future<DateTime> semesterStart(int semesterId) async => (await (select(
    semesters,
  )..where((row) => row.id.equals(semesterId))).getSingle()).startDate;

  Future<void> versionEntry(
    TimetableEntriesCompanion replacement,
    DateTime effectiveFrom,
  ) => transaction(() async {
    final existing = await (select(
      timetableEntries,
    )..where((row) => row.id.equals(replacement.id.value))).getSingle();
    final start = DateTime(
      effectiveFrom.year,
      effectiveFrom.month,
      effectiveFrom.day,
    );
    if (existing.effectiveFrom == null ||
        !start.isAfter(existing.effectiveFrom!)) {
      final updated = replacement.copyWith(
        effectiveFrom: Value(existing.effectiveFrom ?? start),
        effectiveUntil: Value(existing.effectiveUntil),
      );
      await update(timetableEntries).replace(updated);
      return;
    }
    await (update(
      timetableEntries,
    )..where((row) => row.id.equals(existing.id))).write(
      TimetableEntriesCompanion(
        effectiveUntil: Value(start.subtract(const Duration(days: 1))),
      ),
    );
    await into(timetableEntries).insert(
      replacement.copyWith(
        id: const Value.absent(),
        effectiveFrom: Value(start),
        effectiveUntil: Value(existing.effectiveUntil),
      ),
    );
  });

  Future<void> endEntry(int id, DateTime effectiveFrom) => transaction(
    () async {
      final existing = await (select(
        timetableEntries,
      )..where((row) => row.id.equals(id))).getSingle();
      final start = DateTime(
        effectiveFrom.year,
        effectiveFrom.month,
        effectiveFrom.day,
      );
      if (existing.effectiveFrom == null ||
          !start.isAfter(existing.effectiveFrom!)) {
        await deleteById(id);
        return;
      }
      await (update(timetableEntries)..where((row) => row.id.equals(id))).write(
        TimetableEntriesCompanion(
          effectiveUntil: Value(start.subtract(const Duration(days: 1))),
        ),
      );
    },
  );
}
