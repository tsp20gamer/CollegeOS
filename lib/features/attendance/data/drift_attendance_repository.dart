import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/attendance_dao.dart';
import 'package:college_os/features/attendance/domain/attendance_repository.dart';
import 'package:drift/drift.dart';

final class DriftAttendanceRepository implements AttendanceRepository {
  DriftAttendanceRepository(this._dao);

  final AttendanceDao _dao;

  @override
  Stream<List<AttendanceSession>> watchForSubject(int subjectId) => _dao
      .watchForSubject(subjectId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Stream<List<AttendanceSession>> watchForDate(DateTime date) => _dao
      .watchForDate(date)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Stream<AttendanceCounts> watchCountsForSubject(int subjectId) => _dao
      .watchCountsForSubject(subjectId)
      .map(
        (counts) => (
          present: counts.present,
          absent: counts.absent,
          cancelled: counts.cancelled,
          held: counts.held,
        ),
      );

  @override
  Stream<List<SubjectAttendanceSummary>> watchSummariesForSemester(
    int semesterId,
  ) => _dao
      .watchSummariesForSemester(semesterId)
      .map(
        (rows) => rows
            .map(
              (row) => (
                subjectId: row.subjectId,
                name: row.name,
                shortCode: row.shortCode,
                attendanceTarget: row.attendanceTarget,
                displayColor: row.displayColor,
                counts: (
                  present: row.present,
                  absent: row.absent,
                  cancelled: row.cancelled,
                  held: row.present + row.absent,
                ),
              ),
            )
            .toList(growable: false),
      );

  @override
  Future<int> create(NewAttendanceSession session) => _dao.insertSession(
    AttendanceSessionsCompanion.insert(
      subjectId: session.subjectId,
      date: session.date,
      period: session.period,
      status: session.status,
      note: Value(session.note.trim()),
    ),
  );

  @override
  Future<AttendanceSession?> findLikelyDuplicate({
    required int subjectId,
    required DateTime date,
    required int period,
  }) async {
    final row = await _dao.findLikelyDuplicate(
      subjectId: subjectId,
      date: date,
      period: period,
    );
    return row == null ? null : _map(row);
  }

  @override
  Future<void> update(AttendanceSession session) async {
    final updated = await _dao.updateSession(
      AttendanceSessionsCompanion.insert(
        id: Value(session.id),
        subjectId: session.subjectId,
        date: session.date,
        period: session.period,
        status: session.status,
        note: Value(session.note.trim()),
        createdAt: Value(session.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (!updated) {
      throw StateError('Attendance session ${session.id} does not exist.');
    }
  }

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  AttendanceSession _map(AttendanceSessionRow row) => (
    id: row.id,
    subjectId: row.subjectId,
    date: row.date,
    period: row.period,
    status: row.status,
    note: row.note,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
