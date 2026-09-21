// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_files_dao.dart';

// ignore_for_file: type=lint
mixin _$SubjectFilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $SubjectFilesTable get subjectFiles => attachedDatabase.subjectFiles;
  SubjectFilesDaoManager get managers => SubjectFilesDaoManager(this);
}

class SubjectFilesDaoManager {
  final _$SubjectFilesDaoMixin _db;
  SubjectFilesDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$SubjectFilesTableTableManager get subjectFiles =>
      $$SubjectFilesTableTableManager(_db.attachedDatabase, _db.subjectFiles);
}
