import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/attendance_engine_dao.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_engine_repository.dart';
import 'package:drift/drift.dart';

final class DriftAttendanceEngineRepository
    implements AttendanceEngineRepository {
  DriftAttendanceEngineRepository(this._dao);

  final AttendanceEngineDao _dao;

  @override
  Stream<AttendanceEngineSnapshot> watchForSemester(int semesterId) =>
      _dao.watchForSemester(semesterId).map(_mapSnapshot);

  @override
  Future<AttendanceEngineSnapshot> loadForSemester(int semesterId) async =>
      _mapSnapshot(await _dao.loadForSemester(semesterId));

  @override
  Future<AttendanceUndo> markSession(
    ProjectedClassSession session,
    int semesterId,
    ClassAttendanceStatus status, {
    String note = '',
  }) => _dao.upsertWithUndo([
    ScheduledClassAttendanceCompanion.insert(
      id: session.attendanceId == null
          ? const Value.absent()
          : Value(session.attendanceId!),
      semesterId: semesterId,
      timetableEntryId: Value(session.timetableEntryId),
      subjectId: session.subject.id,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
      attendanceStatus: status,
      note: Value(note.trim()),
      manuallyModified: const Value(true),
      updatedAt: Value(DateTime.now().toUtc()),
    ),
  ]);

  @override
  Future<AttendanceUndo> markWholeDay(
    List<ProjectedClassSession> sessions,
    int semesterId,
    ClassAttendanceStatus status,
  ) => _dao.upsertWithUndo([
    for (final session in sessions)
      ScheduledClassAttendanceCompanion.insert(
        id: session.attendanceId == null
            ? const Value.absent()
            : Value(session.attendanceId!),
        semesterId: semesterId,
        timetableEntryId: Value(session.timetableEntryId),
        subjectId: session.subject.id,
        date: session.date,
        startTime: session.startTime,
        endTime: session.endTime,
        attendanceStatus: status,
        note: Value(session.note),
        manuallyModified: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
  ]);

  @override
  Future<void> clearSession(int attendanceId) async {
    await _dao.deleteAttendance(attendanceId);
  }

  @override
  Future<void> setDayOverride({
    required int semesterId,
    required DateTime date,
    required CalendarDayOverrideType type,
    String note = '',
  }) => _dao.setOverride(
    CalendarDayOverridesCompanion.insert(
      semesterId: semesterId,
      date: date,
      type: type,
      note: Value(note.trim()),
      updatedAt: Value(DateTime.now().toUtc()),
    ),
  );

  @override
  Future<void> clearDayOverride(int semesterId, DateTime date) async =>
      _dao.clearOverride(semesterId, date);

  AttendanceEngineSnapshot _mapSnapshot(AttendanceEngineRows rows) =>
      AttendanceEngineSnapshot(
        subjects: [
          for (final row in rows.subjects)
            (
              id: row.id,
              semesterId: row.semesterId,
              name: row.name,
              shortCode: row.shortCode,
              professor: row.professor,
              room: row.room,
              attendanceTarget: row.attendanceTarget,
              displayColor: row.displayColor,
              isArchived: row.isArchived,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
        ],
        timetable: [
          for (final row in rows.timetable)
            (
              id: row.id,
              semesterId: row.semesterId,
              subjectId: row.subjectId,
              weekday: row.weekday,
              startTime: row.startTime,
              endTime: row.endTime,
              effectiveFrom: row.effectiveFrom,
              effectiveUntil: row.effectiveUntil,
            ),
        ],
        attendance: [
          for (final row in rows.attendance)
            (
              id: row.id,
              semesterId: row.semesterId,
              timetableEntryId: row.timetableEntryId,
              subjectId: row.subjectId,
              date: row.date,
              startTime: row.startTime,
              endTime: row.endTime,
              status: row.attendanceStatus,
              note: row.note,
              manuallyModified: row.manuallyModified,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
        ],
        overrides: [
          for (final row in rows.overrides)
            (
              id: row.id,
              semesterId: row.semesterId,
              date: row.date,
              type: row.type,
              note: row.note,
            ),
        ],
        calendarEvents: [
          for (final row in rows.calendarEvents)
            (
              id: row.id,
              semesterId: row.semesterId,
              title: row.title,
              type: row.type,
              startDate: row.startDate,
              endDate: row.endDate,
              note: row.note,
            ),
        ],
      );
}
