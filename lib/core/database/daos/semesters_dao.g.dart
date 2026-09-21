// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'semesters_dao.dart';

// ignore_for_file: type=lint
mixin _$SemestersDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  SemestersDaoManager get managers => SemestersDaoManager(this);
}

class SemestersDaoManager {
  final _$SemestersDaoMixin _db;
  SemestersDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
}
