// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_notes_dao.dart';

// ignore_for_file: type=lint
mixin _$SubjectNotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $SubjectNotesTable get subjectNotes => attachedDatabase.subjectNotes;
  SubjectNotesDaoManager get managers => SubjectNotesDaoManager(this);
}

class SubjectNotesDaoManager {
  final _$SubjectNotesDaoMixin _db;
  SubjectNotesDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$SubjectNotesTableTableManager get subjectNotes =>
      $$SubjectNotesTableTableManager(_db.attachedDatabase, _db.subjectNotes);
}
