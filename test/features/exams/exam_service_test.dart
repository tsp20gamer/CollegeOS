import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/exams/domain/exam_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('countdown uses normalized calendar days regardless of time', () {
    final today = DateTime(2026, 3, 28, 23, 55);
    expect(ExamService.countdown(DateTime(2026, 3, 28, 0, 1), today), 'Today');
    expect(
      ExamService.countdown(DateTime(2026, 3, 29, 0, 1), today),
      'Tomorrow',
    );
    expect(ExamService.countdown(DateTime(2026, 4, 1), today), 'In 4 days');
    expect(ExamService.countdown(DateTime(2026, 3, 27), today), 'Yesterday');
  });

  test('splits and chronologically sorts upcoming and past exams', () {
    final today = DateTime(2026, 8, 12, 18);
    final exams = [
      _exam(id: 1, date: DateTime(2026, 8, 13), start: 600),
      _exam(id: 2, date: DateTime(2026, 8, 11)),
      _exam(id: 3, date: DateTime(2026, 8, 12), start: 720),
      _exam(id: 4, date: DateTime(2026, 8, 12), start: 540),
      _exam(id: 5, date: DateTime(2026, 8, 10)),
    ];
    expect(ExamService.upcoming(exams, today).map((exam) => exam.id), [
      4,
      3,
      1,
    ]);
    expect(ExamService.past(exams, today).map((exam) => exam.id), [2, 5]);
  });
}

Exam _exam({required int id, required DateTime date, int? start}) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  name: 'Exam $id',
  examType: 'Written',
  examDate: date,
  startTime: start,
  endTime: null,
  room: '',
  syllabus: '',
  maxMarks: null,
  obtainedMarks: null,
  reminderAt: null,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);
