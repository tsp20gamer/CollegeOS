typedef Exam = ({
  int id,
  int semesterId,
  int subjectId,
  String name,
  String examType,
  DateTime examDate,
  int? startTime,
  int? endTime,
  String room,
  String syllabus,
  double? maxMarks,
  double? obtainedMarks,
  DateTime? reminderAt,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewExam = ({
  int semesterId,
  int subjectId,
  String name,
  String examType,
  DateTime examDate,
  int? startTime,
  int? endTime,
  String room,
  String syllabus,
  double? maxMarks,
  double? obtainedMarks,
  DateTime? reminderAt,
});

abstract interface class ExamRepository {
  Stream<List<Exam>> watchForSemester(int semesterId);
  Future<List<Exam>> getAllWithReminders();
  Future<int> create(NewExam exam);
  Future<void> update(Exam exam);
  Future<void> delete(int id);
}
