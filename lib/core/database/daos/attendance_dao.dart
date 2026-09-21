import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/attendance_sessions.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

part 'attendance_dao.g.dart';

final class AttendanceCountsRow {
  const AttendanceCountsRow({
    required this.present,
    required this.absent,
    required this.cancelled,
  });

  final int present;
  final int absent;
  final int cancelled;

  int get held => present + absent;
}

final class SubjectAttendanceSummaryRow {
  const SubjectAttendanceSummaryRow({
    required this.subjectId,
    required this.name,
    required this.shortCode,
    required this.attendanceTarget,
    required this.displayColor,
    required this.present,
    required this.absent,
    required this.cancelled,
  });

  final int subjectId;
  final String name;
  final String shortCode;
  final double attendanceTarget;
  final int displayColor;
  final int present;
  final int absent;
  final int cancelled;
}

@DriftAccessor(tables: [AttendanceSessions, Subjects])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.attachedDatabase);

  Stream<List<AttendanceSessionRow>> watchForSubject(int subjectId) {
    final query = select(attendanceSessions)
      ..where((row) => row.subjectId.equals(subjectId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.date),
        (row) => OrderingTerm.desc(row.period),
      ]);
    return query.watch();
  }

  Stream<List<AttendanceSessionRow>> watchForDate(DateTime date) {
    final epochDay = const EpochDayConverter().toSql(date);
    final query = select(attendanceSessions)
      ..where((row) => row.date.equals(epochDay))
      ..orderBy([(row) => OrderingTerm.asc(row.period)]);
    return query.watch();
  }

  Future<AttendanceSessionRow?> findLikelyDuplicate({
    required int subjectId,
    required DateTime date,
    required int period,
  }) {
    final epochDay = const EpochDayConverter().toSql(date);
    final query = select(attendanceSessions)
      ..where(
        (row) =>
            row.subjectId.equals(subjectId) &
            row.date.equals(epochDay) &
            row.period.equals(period),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<AttendanceCountsRow> watchCountsForSubject(int subjectId) {
    return customSelect(
      '''
SELECT
  COALESCE(SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END), 0) AS present_count,
  COALESCE(SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END), 0) AS absent_count,
  COALESCE(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END), 0) AS cancelled_count
FROM attendance_sessions
WHERE subject_id = ?
''',
      variables: [Variable.withInt(subjectId)],
      readsFrom: {attendanceSessions},
    ).watchSingle().map(
      (row) => AttendanceCountsRow(
        present: row.read<int>('present_count'),
        absent: row.read<int>('absent_count'),
        cancelled: row.read<int>('cancelled_count'),
      ),
    );
  }

  Stream<List<SubjectAttendanceSummaryRow>> watchSummariesForSemester(
    int semesterId,
  ) {
    return customSelect(
      '''
SELECT
  s.id AS subject_id,
  s.name,
  s.short_code,
  s.attendance_target,
  s.display_color,
  COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END), 0) AS present_count,
  COALESCE(SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END), 0) AS absent_count,
  COALESCE(SUM(CASE WHEN a.status = 'cancelled' THEN 1 ELSE 0 END), 0) AS cancelled_count
FROM subjects s
LEFT JOIN attendance_sessions a ON a.subject_id = s.id
WHERE s.semester_id = ? AND s.is_archived = 0
GROUP BY s.id
ORDER BY s.name COLLATE NOCASE, s.short_code COLLATE NOCASE
''',
      variables: [Variable.withInt(semesterId)],
      readsFrom: {subjects, attendanceSessions},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => SubjectAttendanceSummaryRow(
              subjectId: row.read<int>('subject_id'),
              name: row.read<String>('name'),
              shortCode: row.read<String>('short_code'),
              attendanceTarget: row.read<double>('attendance_target'),
              displayColor: row.read<int>('display_color'),
              present: row.read<int>('present_count'),
              absent: row.read<int>('absent_count'),
              cancelled: row.read<int>('cancelled_count'),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<int> insertSession(AttendanceSessionsCompanion session) =>
      into(attendanceSessions).insert(session);

  Future<bool> updateSession(AttendanceSessionsCompanion session) =>
      update(attendanceSessions).replace(session);

  Future<int> deleteById(int id) =>
      (delete(attendanceSessions)..where((row) => row.id.equals(id))).go();
}
