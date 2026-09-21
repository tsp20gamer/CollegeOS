import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/subject_notes_dao.dart';
import 'package:college_os/features/notes/domain/subject_note_repository.dart';
import 'package:drift/drift.dart';

final class DriftSubjectNoteRepository implements SubjectNoteRepository {
  DriftSubjectNoteRepository(this._dao);

  final SubjectNotesDao _dao;

  @override
  Stream<List<SubjectNote>> watchBySubject(int subjectId) => _dao
      .watchBySubject(subjectId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<int> create(NewSubjectNote note) => _dao.insertNote(
    SubjectNotesCompanion.insert(
      subjectId: note.subjectId,
      semesterId: note.semesterId,
      title: Value(note.title.trim()),
      body: note.body.trim(),
    ),
  );

  @override
  Future<void> update(SubjectNote note) async {
    final updated = await _dao.updateNote(
      SubjectNotesCompanion.insert(
        id: Value(note.id),
        subjectId: note.subjectId,
        semesterId: note.semesterId,
        title: Value(note.title.trim()),
        body: note.body.trim(),
        createdAt: Value(note.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (!updated) throw StateError('SubjectNote ${note.id} does not exist.');
  }

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  SubjectNote _map(SubjectNoteRow row) => (
    id: row.id,
    subjectId: row.subjectId,
    semesterId: row.semesterId,
    title: row.title,
    body: row.body,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
