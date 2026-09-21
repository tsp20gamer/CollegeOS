typedef SubjectNote = ({
  int id,
  int subjectId,
  int semesterId,
  String title,
  String body,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewSubjectNote = ({
  int subjectId,
  int semesterId,
  String title,
  String body,
});

abstract interface class SubjectNoteRepository {
  Stream<List<SubjectNote>> watchBySubject(int subjectId);
  Future<int> create(NewSubjectNote note);
  Future<void> update(SubjectNote note);
  Future<void> delete(int id);
}
