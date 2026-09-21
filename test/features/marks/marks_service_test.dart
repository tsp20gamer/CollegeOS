import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:college_os/features/marks/domain/marks_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates percentages safely', () {
    expect(MarksService.percentage(18, 20), 90);
    expect(MarksService.percentage(0, 20), 0);
    expect(MarksService.percentage(10, 0), isNull);
  });

  test('summarizes only recorded raw marks', () {
    final summary = MarksService.summarize([
      _mark(id: 1, obtained: 18, maximum: 20),
      _mark(id: 2, obtained: 42, maximum: 50),
    ]);
    expect(summary.assessmentCount, 2);
    expect(summary.obtained, 60);
    expect(summary.maximum, 70);
    expect(summary.percentage, closeTo(85.714, 0.001));
    expect(MarksService.summarize(const []).percentage, isNull);
  });

  test('maps stable categories and treats unknown legacy values as other', () {
    for (final category in MarkCategory.values) {
      expect(
        MarkCategoryDetails.fromDatabase(category.databaseValue),
        category,
      );
    }
    expect(MarkCategoryDetails.fromDatabase('Quiz'), MarkCategory.other);
  });
}

Mark _mark({
  required int id,
  required double obtained,
  required double maximum,
}) => (
  id: id,
  subjectId: 1,
  examId: null,
  category: 'internal',
  obtainedMarks: obtained,
  maxMarks: maximum,
  date: DateTime(2026, 8, id),
  note: '',
);
