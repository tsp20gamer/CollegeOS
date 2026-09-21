import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/daily_attendance_dao.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/daily_attendance_repository.dart';
import 'package:drift/drift.dart';

final class DriftDailyAttendanceRepository
    implements DailyAttendanceRepository {
  DriftDailyAttendanceRepository(this._dao);

  final DailyAttendanceDao _dao;

  @override
  Stream<List<DailyAttendanceRecord>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_map).toList(growable: false));

  @override
  Stream<List<DailyAttendanceRecord>> watchRange(
    DateTime firstDay,
    DateTime lastDay,
  ) => _dao
      .watchRange(firstDay, lastDay)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Stream<DailyAttendanceRecord?> watchForDate(DateTime date) =>
      _dao.watchForDate(date).map((row) => row == null ? null : _map(row));

  @override
  Future<void> setStatus({
    required DateTime date,
    required DailyAttendanceStatus status,
    String note = '',
  }) async {
    final existing = await _dao.getForDate(date);
    final now = DateTime.now().toUtc();
    await _dao.upsert(
      DailyAttendanceRecordsCompanion.insert(
        id: existing == null ? const Value.absent() : Value(existing.id),
        date: DateTime(date.year, date.month, date.day),
        status: status,
        note: Value(note.trim()),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> remove(DateTime date) async => _dao.deleteForDate(date);

  DailyAttendanceRecord _map(DailyAttendanceRecordRow row) => (
    id: row.id,
    date: row.date,
    status: row.status,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
