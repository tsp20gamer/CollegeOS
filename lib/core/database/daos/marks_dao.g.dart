// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marks_dao.dart';

// ignore_for_file: type=lint
mixin _$MarksDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $ExamsTable get exams => attachedDatabase.exams;
  $MarksTable get marks => attachedDatabase.marks;
  MarksDaoManager get managers => MarksDaoManager(this);
}

class MarksDaoManager {
  final _$MarksDaoMixin _db;
  MarksDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
  $$MarksTableTableManager get marks =>
      $$MarksTableTableManager(_db.attachedDatabase, _db.marks);
}
