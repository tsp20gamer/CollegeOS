typedef Mark = ({
  int id,
  int subjectId,
  int? examId,
  String category,
  double obtainedMarks,
  double maxMarks,
  DateTime date,
  String note,
});

typedef NewMark = ({
  int subjectId,
  int? examId,
  String category,
  double obtainedMarks,
  double maxMarks,
  DateTime date,
  String note,
});

abstract interface class MarksRepository {
  Stream<List<Mark>> watchForSubject(int subjectId);
  Stream<List<Mark>> watchForSemester(int semesterId);
  Future<int> create(NewMark mark);
  Future<void> update(Mark mark);
  Future<void> delete(int id);
}
