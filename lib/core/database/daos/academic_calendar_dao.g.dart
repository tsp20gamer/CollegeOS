// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academic_calendar_dao.dart';

// ignore_for_file: type=lint
mixin _$AcademicCalendarDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $AcademicCalendarEventsTable get academicCalendarEvents =>
      attachedDatabase.academicCalendarEvents;
  AcademicCalendarDaoManager get managers => AcademicCalendarDaoManager(this);
}

class AcademicCalendarDaoManager {
  final _$AcademicCalendarDaoMixin _db;
  AcademicCalendarDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$AcademicCalendarEventsTableTableManager get academicCalendarEvents =>
      $$AcademicCalendarEventsTableTableManager(
        _db.attachedDatabase,
        _db.academicCalendarEvents,
      );
}
