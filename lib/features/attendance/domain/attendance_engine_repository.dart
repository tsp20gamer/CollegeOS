import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';

/// Restores only this edit, returning false if a newer edit conflicts with it.
typedef AttendanceUndo = Future<bool> Function();

abstract interface class AttendanceEngineRepository {
  Stream<AttendanceEngineSnapshot> watchForSemester(int semesterId);
  Future<AttendanceEngineSnapshot> loadForSemester(int semesterId);
  Future<AttendanceUndo> markSession(
    ProjectedClassSession session,
    int semesterId,
    ClassAttendanceStatus status, {
    String note = '',
  });
  Future<AttendanceUndo> markWholeDay(
    List<ProjectedClassSession> sessions,
    int semesterId,
    ClassAttendanceStatus status,
  );
  Future<void> clearSession(int attendanceId);
  Future<void> setDayOverride({
    required int semesterId,
    required DateTime date,
    required CalendarDayOverrideType type,
    String note = '',
  });
  Future<void> clearDayOverride(int semesterId, DateTime date);
}
