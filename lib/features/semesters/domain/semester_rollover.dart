typedef SemesterRolloverRequest = ({
  int sourceSemesterId,
  int semesterNumber,
  String academicYear,
  DateTime academicYearStartDate,
  DateTime academicYearEndDate,
  DateTime semesterStartDate,
  DateTime semesterEndDate,
  bool copySubjects,
  bool copyTimetable,
});

final class SemesterRolloverResult {
  const SemesterRolloverResult({
    required this.semesterId,
    required this.subjectsCopied,
    required this.timetableEntriesCopied,
  });

  final int semesterId;
  final int subjectsCopied;
  final int timetableEntriesCopied;
}

abstract interface class SemesterRolloverService {
  Future<SemesterRolloverResult> rollover(SemesterRolloverRequest request);
}
