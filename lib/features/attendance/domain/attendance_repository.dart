import 'package:college_os/core/database/database_enums.dart';

typedef AttendanceSession = ({
  int id,
  int subjectId,
  DateTime date,
  int period,
  AttendanceStatus status,
  String note,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewAttendanceSession = ({
  int subjectId,
  DateTime date,
  int period,
  AttendanceStatus status,
  String note,
});

typedef AttendanceCounts = ({int present, int absent, int cancelled, int held});

typedef SubjectAttendanceSummary = ({
  int subjectId,
  String name,
  String shortCode,
  double attendanceTarget,
  int displayColor,
  AttendanceCounts counts,
});

abstract interface class AttendanceRepository {
  Stream<List<AttendanceSession>> watchForSubject(int subjectId);
  Stream<List<AttendanceSession>> watchForDate(DateTime date);
  Stream<AttendanceCounts> watchCountsForSubject(int subjectId);
  Stream<List<SubjectAttendanceSummary>> watchSummariesForSemester(
    int semesterId,
  );
  Future<int> create(NewAttendanceSession session);
  Future<AttendanceSession?> findLikelyDuplicate({
    required int subjectId,
    required DateTime date,
    required int period,
  });
  Future<void> update(AttendanceSession session);
  Future<void> delete(int id);
}
