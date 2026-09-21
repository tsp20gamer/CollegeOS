import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/marks_dao.dart';
import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:drift/drift.dart';

final class DriftMarksRepository implements MarksRepository {
  DriftMarksRepository(this._dao);

  final MarksDao _dao;

  @override
  Stream<List<Mark>> watchForSubject(int subjectId) => _dao
      .watchForSubject(subjectId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Stream<List<Mark>> watchForSemester(int semesterId) => _dao
      .watchForSemester(semesterId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<int> create(NewMark mark) => _dao.insertMark(
    MarksCompanion.insert(
      subjectId: mark.subjectId,
      examId: Value(mark.examId),
      category: mark.category.trim(),
      obtainedMarks: mark.obtainedMarks,
      maxMarks: mark.maxMarks,
      date: mark.date,
      note: Value(mark.note.trim()),
    ),
  );

  @override
  Future<void> update(Mark mark) async {
    final updated = await _dao.updateMark(
      MarksCompanion.insert(
        id: Value(mark.id),
        subjectId: mark.subjectId,
        examId: Value(mark.examId),
        category: mark.category.trim(),
        obtainedMarks: mark.obtainedMarks,
        maxMarks: mark.maxMarks,
        date: mark.date,
        note: Value(mark.note.trim()),
      ),
    );
    if (!updated) throw StateError('Mark ${mark.id} does not exist.');
  }

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  Mark _map(MarkRow row) => (
    id: row.id,
    subjectId: row.subjectId,
    examId: row.examId,
    category: row.category,
    obtainedMarks: row.obtainedMarks,
    maxMarks: row.maxMarks,
    date: row.date,
    note: row.note,
  );
}
