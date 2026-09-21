final class CollegeSetup {
  const CollegeSetup({
    required this.studentName,
    required this.collegeName,
    required this.course,
    required this.branch,
    required this.semesterNumber,
    required this.academicYear,
    DateTime? academicYearStartDate,
    DateTime? academicYearEndDate,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.defaultAttendanceTarget,
  }) : academicYearStartDate = academicYearStartDate ?? semesterStartDate,
       academicYearEndDate = academicYearEndDate ?? semesterEndDate;

  final String studentName;
  final String collegeName;
  final String course;
  final String branch;
  final int semesterNumber;
  final String academicYear;
  final DateTime academicYearStartDate;
  final DateTime academicYearEndDate;
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final double defaultAttendanceTarget;
}

abstract interface class OnboardingRepository {
  Future<void> completeSetup(CollegeSetup setup);
}
