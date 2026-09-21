// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exams_dao.dart';

// ignore_for_file: type=lint
mixin _$ExamsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $ExamsTable get exams => attachedDatabase.exams;
  ExamsDaoManager get managers => ExamsDaoManager(this);
}

class ExamsDaoManager {
  final _$ExamsDaoMixin _db;
  ExamsDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
}
