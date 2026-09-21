import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/subject_notes.dart';
import 'package:drift/drift.dart';

part 'subject_notes_dao.g.dart';

@DriftAccessor(tables: [SubjectNotes])
class SubjectNotesDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectNotesDaoMixin {
  SubjectNotesDao(super.attachedDatabase);

  /// Reactive stream of notes for [subjectId], newest first.
  Stream<List<SubjectNoteRow>> watchBySubject(int subjectId) {
    return (select(subjectNotes)
          ..where((row) => row.subjectId.equals(subjectId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<int> insertNote(SubjectNotesCompanion note) =>
      into(subjectNotes).insert(note);

  Future<bool> updateNote(SubjectNotesCompanion note) =>
      update(subjectNotes).replace(note);

  Future<int> deleteById(int id) =>
      (delete(subjectNotes)..where((row) => row.id.equals(id))).go();

  Future<List<SubjectNoteRow>> getAllForBackup() =>
      (select(subjectNotes)..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
}
