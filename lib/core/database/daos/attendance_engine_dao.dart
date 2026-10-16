import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/app_settings.dart';
import 'package:college_os/core/database/tables/calendar_day_overrides.dart';
import 'package:college_os/core/database/tables/academic_calendar_events.dart';
import 'package:college_os/core/database/tables/scheduled_class_attendance.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:college_os/core/database/tables/timetable_entries.dart';
import 'package:drift/drift.dart';

part 'attendance_engine_dao.g.dart';

final class AttendanceEngineRows {
  const AttendanceEngineRows({
    required this.subjects,
    required this.timetable,
    required this.attendance,
    required this.overrides,
    required this.calendarEvents,
    this.settings,
  });

  final List<SubjectRow> subjects;
  final List<TimetableEntryRow> timetable;
  final List<ScheduledClassAttendanceRow> attendance;
  final List<CalendarDayOverrideRow> overrides;
  final List<AcademicCalendarEventRow> calendarEvents;

  /// The singleton settings row, carrying the derived-holiday rules.
  ///
  /// Nullable because a database that has never completed setup could be
  /// missing it; the engine then falls back to no derived holidays.
  final AppSettingsRow? settings;
}

@DriftAccessor(
  tables: [
    Subjects,
    TimetableEntries,
    ScheduledClassAttendance,
    CalendarDayOverrides,
    AcademicCalendarEvents,
    AppSettings,
  ],
)
class AttendanceEngineDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceEngineDaoMixin {
  AttendanceEngineDao(super.attachedDatabase);

  Stream<AttendanceEngineRows> watchForSemester(int semesterId) => customSelect(
    'SELECT 1 AS attendance_change',
    readsFrom: {
      subjects,
      timetableEntries,
      scheduledClassAttendance,
      calendarDayOverrides,
      academicCalendarEvents,
      // The derived-holiday switches live in settings, so flipping one has to
      // re-emit this snapshot: the day projection, next class and every
      // percentage derive from it.
      appSettings,
    },
  ).watch().asyncMap((_) => loadForSemester(semesterId));

  Future<AttendanceEngineRows> loadForSemester(int semesterId) async {
    final subjectRows = await (select(
      subjects,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final timetableRows = await (select(
      timetableEntries,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final attendanceRows = await (select(
      scheduledClassAttendance,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final overrideRows = await (select(
      calendarDayOverrides,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final calendarEventRows = await (select(
      academicCalendarEvents,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final settingsRow = await select(appSettings).getSingleOrNull();
    return AttendanceEngineRows(
      subjects: subjectRows,
      timetable: timetableRows,
      attendance: attendanceRows,
      overrides: overrideRows,
      calendarEvents: calendarEventRows,
      settings: settingsRow,
    );
  }

  Future<int> upsertAttendance(ScheduledClassAttendanceCompanion record) async {
    final timetableId = record.timetableEntryId.value;
    final date = const EpochDayConverter().toSql(record.date.value);
    ScheduledClassAttendanceRow? existing;
    if (timetableId != null) {
      existing =
          await (select(scheduledClassAttendance)..where(
                (row) =>
                    row.timetableEntryId.equals(timetableId) &
                    row.date.equals(date),
              ))
              .getSingleOrNull();
    } else if (record.id.present) {
      existing = await (select(
        scheduledClassAttendance,
      )..where((row) => row.id.equals(record.id.value))).getSingleOrNull();
    }
    final insertedId = await into(scheduledClassAttendance)
        .insertOnConflictUpdate(
          record.copyWith(
            id: existing == null ? const Value.absent() : Value(existing.id),
            createdAt: existing == null
                ? const Value.absent()
                : Value(existing.createdAt),
          ),
        );
    return existing?.id ?? insertedId;
  }

  Future<void> upsertMany(List<ScheduledClassAttendanceCompanion> records) =>
      transaction(() async {
        for (final record in records) {
          await upsertAttendance(record);
        }
      });

  /// Capture and restore only the affected rows, in atomic transactions.
  Future<Future<bool> Function()> upsertWithUndo(
    List<ScheduledClassAttendanceCompanion> records,
  ) => transaction(() async {
    final before = <ScheduledClassAttendanceRow?>[];
    final after = <ScheduledClassAttendanceRow>[];
    for (final record in records) {
      final query = select(scheduledClassAttendance);
      final slot = record.timetableEntryId.value;
      if (slot != null) {
        query.where(
          (row) =>
              row.timetableEntryId.equals(slot) &
              row.date.equals(
                const EpochDayConverter().toSql(record.date.value),
              ),
        );
      } else if (record.id.present) {
        query.where((row) => row.id.equals(record.id.value));
      } else {
        query.where((row) => row.id.equals(-1));
      }
      before.add(await query.getSingleOrNull());
      final id = await upsertAttendance(record);
      after.add(
        await (select(
          scheduledClassAttendance,
        )..where((row) => row.id.equals(id))).getSingle(),
      );
    }
    var consumed = false;
    return () => transaction(() async {
      if (consumed) return false;
      for (final expected in after) {
        final current = await (select(
          scheduledClassAttendance,
        )..where((row) => row.id.equals(expected.id))).getSingleOrNull();
        if (current != expected) return false;
      }
      for (var index = 0; index < after.length; index++) {
        final original = before[index];
        if (original == null) {
          await deleteAttendance(after[index].id);
        } else {
          await update(scheduledClassAttendance).replace(original);
        }
      }
      consumed = true;
      return true;
    });
  });

  Future<void> setOverride(CalendarDayOverridesCompanion value) async {
    final date = const EpochDayConverter().toSql(value.date.value);
    final existing =
        await (select(calendarDayOverrides)..where(
              (row) =>
                  row.semesterId.equals(value.semesterId.value) &
                  row.date.equals(date),
            ))
            .getSingleOrNull();
    await into(calendarDayOverrides).insertOnConflictUpdate(
      value.copyWith(
        id: existing == null ? const Value.absent() : Value(existing.id),
        createdAt: existing == null
            ? const Value.absent()
            : Value(existing.createdAt),
      ),
    );
  }

  Future<int> clearOverride(int semesterId, DateTime date) =>
      (delete(calendarDayOverrides)..where(
            (row) =>
                row.semesterId.equals(semesterId) &
                row.date.equals(const EpochDayConverter().toSql(date)),
          ))
          .go();

  Future<int> deleteAttendance(int id) => (delete(
    scheduledClassAttendance,
  )..where((row) => row.id.equals(id))).go();
}
