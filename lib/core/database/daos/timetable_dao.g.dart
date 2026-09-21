// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_dao.dart';

// ignore_for_file: type=lint
mixin _$TimetableDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $TimetableEntriesTable get timetableEntries =>
      attachedDatabase.timetableEntries;
  TimetableDaoManager get managers => TimetableDaoManager(this);
}

class TimetableDaoManager {
  final _$TimetableDaoMixin _db;
  TimetableDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(
        _db.attachedDatabase,
        _db.timetableEntries,
      );
}
