// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_engine_dao.dart';

// ignore_for_file: type=lint
mixin _$AttendanceEngineDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $TimetableEntriesTable get timetableEntries =>
      attachedDatabase.timetableEntries;
  $ScheduledClassAttendanceTable get scheduledClassAttendance =>
      attachedDatabase.scheduledClassAttendance;
  $CalendarDayOverridesTable get calendarDayOverrides =>
      attachedDatabase.calendarDayOverrides;
  $AcademicCalendarEventsTable get academicCalendarEvents =>
      attachedDatabase.academicCalendarEvents;
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  AttendanceEngineDaoManager get managers => AttendanceEngineDaoManager(this);
}

class AttendanceEngineDaoManager {
  final _$AttendanceEngineDaoMixin _db;
  AttendanceEngineDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$TimetableEntriesTableTableManager get timetableEntries =>
      $$TimetableEntriesTableTableManager(
        _db.attachedDatabase,
        _db.timetableEntries,
      );
  $$ScheduledClassAttendanceTableTableManager get scheduledClassAttendance =>
      $$ScheduledClassAttendanceTableTableManager(
        _db.attachedDatabase,
        _db.scheduledClassAttendance,
      );
  $$CalendarDayOverridesTableTableManager get calendarDayOverrides =>
      $$CalendarDayOverridesTableTableManager(
        _db.attachedDatabase,
        _db.calendarDayOverrides,
      );
  $$AcademicCalendarEventsTableTableManager get academicCalendarEvents =>
      $$AcademicCalendarEventsTableTableManager(
        _db.attachedDatabase,
        _db.academicCalendarEvents,
      );
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
}
