import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
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

  /// Writes one reminder lead time onto every class in a semester that is still
  /// current or starts later, returning how many rows changed.
  ///
  /// Only `reminder_minutes_before` is written, and no timetable history is
  /// versioned: a lead time changes what Android announces, never what a class
  /// record meant on a date that has already passed, so attendance and past
  /// schedules stay exactly as they were. Classes whose effectiveness already
  /// ended are left alone because their reminder can no longer fire.
  Future<int> setReminderForSemester(
    int semesterId,
    int? minutesBefore, {
    required DateTime effectiveOn,
  }) {
    final epochDay = const EpochDayConverter().toSql(
      DateTime(effectiveOn.year, effectiveOn.month, effectiveOn.day),
    );
    return (update(timetableEntries)..where(
          (row) =>
              row.semesterId.equals(semesterId) &
              (row.effectiveUntil.isNull() |
                  row.effectiveUntil.isBiggerOrEqualValue(epochDay)),
        ))
        .write(
          TimetableEntriesCompanion(
            reminderMinutesBefore: Value(minutesBefore),
          ),
        );
  }

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
