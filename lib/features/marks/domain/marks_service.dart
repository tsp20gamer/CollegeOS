import 'package:college_os/features/marks/domain/marks_repository.dart';

enum MarkCategory { internal, assignment, lab, semesterExam, other }

extension MarkCategoryDetails on MarkCategory {
  String get databaseValue => switch (this) {
    MarkCategory.internal => 'internal',
    MarkCategory.assignment => 'assignment',
    MarkCategory.lab => 'lab',
    MarkCategory.semesterExam => 'semester_exam',
    MarkCategory.other => 'other',
  };

  String get label => switch (this) {
    MarkCategory.internal => 'Internal',
    MarkCategory.assignment => 'Assignment',
    MarkCategory.lab => 'Lab',
    MarkCategory.semesterExam => 'Semester Exam',
    MarkCategory.other => 'Other',
  };

  static MarkCategory fromDatabase(String value) => switch (value) {
    'internal' || 'Internal' => MarkCategory.internal,
    'assignment' || 'Assignment' => MarkCategory.assignment,
    'lab' || 'Lab' => MarkCategory.lab,
    'semester_exam' || 'Semester Exam' => MarkCategory.semesterExam,
    _ => MarkCategory.other,
  };
}

final class MarksSummary {
  const MarksSummary({
    required this.assessmentCount,
    required this.obtained,
    required this.maximum,
  });

  final int assessmentCount;
  final double obtained;
  final double maximum;

  double? get percentage => maximum <= 0 ? null : obtained / maximum * 100;
}

abstract final class MarksService {
  static double? percentage(double obtained, double maximum) =>
      maximum <= 0 ? null : obtained / maximum * 100;

  static MarksSummary summarize(Iterable<Mark> marks) {
    var count = 0;
    var obtained = 0.0;
    var maximum = 0.0;
    for (final mark in marks) {
      count++;
      obtained += mark.obtainedMarks;
      maximum += mark.maxMarks;
    }
    return MarksSummary(
      assessmentCount: count,
      obtained: obtained,
      maximum: maximum,
    );
  }
}
