import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';

final class BackupDataSnapshot {
  const BackupDataSnapshot({
    required this.settings,
    required this.semesters,
    required this.subjects,
    required this.timetable,
    required this.attendance,
    this.dailyAttendance = const [],
    this.scheduledAttendance = const [],
    this.dayOverrides = const [],
    this.calendarEvents = const [],
    required this.tasks,
    required this.exams,
    required this.marks,
    this.notes = const [],
    this.subjectFiles = const [],
  });

  final AppSettingsRow settings;
  final List<SemesterRow> semesters;
  final List<SubjectRow> subjects;
  final List<TimetableEntryRow> timetable;
  final List<AttendanceSessionRow> attendance;
  final List<DailyAttendanceRecordRow> dailyAttendance;
  final List<ScheduledClassAttendanceRow> scheduledAttendance;
  final List<CalendarDayOverrideRow> dayOverrides;
  final List<AcademicCalendarEventRow> calendarEvents;
  final List<TaskRow> tasks;
  final List<ExamRow> exams;
  final List<MarkRow> marks;
  final List<SubjectNoteRow> notes;
  final List<SubjectFileRow> subjectFiles;

  BackupRecordCounts get counts => BackupRecordCounts(
    settings: 1,
    semesters: semesters.length,
    subjects: subjects.length,
    timetable: timetable.length,
    attendance: attendance.length,
    dailyAttendance: dailyAttendance.length,
    scheduledAttendance: scheduledAttendance.length,
    dayOverrides: dayOverrides.length,
    calendarEvents: calendarEvents.length,
    tasks: tasks.length,
    exams: exams.length,
    marks: marks.length,
    notes: notes.length,
    files: subjectFiles.length,
  );

  String? get activeSemesterName {
    for (final semester in semesters) {
      if (semester.isActive) return semester.name;
    }
    return null;
  }

  Map<String, Object> toJson() => {
    'settings': {
      'id': settings.id,
      'studentName': settings.studentName,
      'collegeName': settings.collegeName,
      'course': settings.course,
      'branch': settings.branch,
      'academicYearStartDate': settings.academicYearStartDate == null
          ? null
          : _date(settings.academicYearStartDate!),
      'academicYearEndDate': settings.academicYearEndDate == null
          ? null
          : _date(settings.academicYearEndDate!),
      'defaultAttendanceTarget': settings.defaultAttendanceTarget,
      'themeMode': settings.themeMode.name,
      'onboardingCompleted': settings.onboardingCompleted,
      'notificationsEnabled': settings.notificationsEnabled,
      'automaticLocalBackup': settings.automaticLocalBackup,
    },
    'semesters': [
      for (final row in semesters)
        {
          'id': row.id,
          'name': row.name,
          'semesterNumber': row.semesterNumber,
          'academicYear': row.academicYear,
          'startDate': _date(row.startDate),
          'endDate': _date(row.endDate),
          'isActive': row.isActive,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'subjects': [
      for (final row in subjects)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'name': row.name,
          'shortCode': row.shortCode,
          'professor': row.professor,
          'room': row.room,
          'attendanceTarget': row.attendanceTarget,
          'displayColor': row.displayColor,
          'isArchived': row.isArchived,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'timetable': [
      for (final row in timetable)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'subjectId': row.subjectId,
          'weekday': row.weekday,
          'startTime': row.startTime,
          'endTime': row.endTime,
          'room': row.room,
          'note': row.note,
          'effectiveFrom': row.effectiveFrom == null
              ? null
              : _date(row.effectiveFrom!),
          'effectiveUntil': row.effectiveUntil == null
              ? null
              : _date(row.effectiveUntil!),
        },
    ],
    'attendance': [
      for (final row in attendance)
        {
          'id': row.id,
          'subjectId': row.subjectId,
          'date': _date(row.date),
          'period': row.period,
          'status': row.status.name,
          'note': row.note,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'dailyAttendance': [
      for (final row in dailyAttendance)
        {
          'id': row.id,
          'date': _date(row.date),
          'status': row.status.name,
          'note': row.note,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'scheduledAttendance': [
      for (final row in scheduledAttendance)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'timetableEntryId': row.timetableEntryId,
          'subjectId': row.subjectId,
          'date': _date(row.date),
          'startTime': row.startTime,
          'endTime': row.endTime,
          'status': row.attendanceStatus.name,
          'note': row.note,
          'manuallyModified': row.manuallyModified,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'dayOverrides': [
      for (final row in dayOverrides)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'date': _date(row.date),
          'type': row.type.name,
          'note': row.note,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'calendarEvents': [
      for (final row in calendarEvents)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'title': row.title,
          'type': row.type.name,
          'startDate': _date(row.startDate),
          'endDate': _date(row.endDate),
          'note': row.note,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'tasks': [
      for (final row in tasks)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'subjectId': row.subjectId,
          'title': row.title,
          'description': row.description,
          'type': row.type.name,
          'priority': row.priority.name,
          'dueDate': row.dueDate == null ? null : _date(row.dueDate!),
          'dueTime': row.dueTime,
          'reminderAt': row.reminderAt == null
              ? null
              : _instant(row.reminderAt!),
          'isCompleted': row.isCompleted,
          'completedAt': row.completedAt == null
              ? null
              : _instant(row.completedAt!),
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'exams': [
      for (final row in exams)
        {
          'id': row.id,
          'semesterId': row.semesterId,
          'subjectId': row.subjectId,
          'name': row.name,
          'examType': row.examType,
          'examDate': _date(row.examDate),
          'startTime': row.startTime,
          'endTime': row.endTime,
          'room': row.room,
          'syllabus': row.syllabus,
          'maxMarks': row.maxMarks,
          'obtainedMarks': row.obtainedMarks,
          'reminderAt': row.reminderAt == null
              ? null
              : _instant(row.reminderAt!),
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'marks': [
      for (final row in marks)
        {
          'id': row.id,
          'subjectId': row.subjectId,
          'examId': row.examId,
          'category': row.category,
          'obtainedMarks': row.obtainedMarks,
          'maxMarks': row.maxMarks,
          'date': _date(row.date),
          'note': row.note,
        },
    ],
    'notes': [
      for (final row in notes)
        {
          'id': row.id,
          'subjectId': row.subjectId,
          'semesterId': row.semesterId,
          'title': row.title,
          'body': row.body,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
    'subjectFiles': [
      for (final row in subjectFiles)
        {
          'id': row.id,
          'subjectId': row.subjectId,
          'semesterId': row.semesterId,
          'title': row.title,
          'fileName': row.fileName,
          'fileExtension': row.fileExtension,
          'fileSizeBytes': row.fileSizeBytes,
          'mimeType': row.mimeType,
          'relativeFilePath': row.relativeFilePath,
          'createdAt': _instant(row.createdAt),
          'updatedAt': _instant(row.updatedAt),
        },
    ],
  };

  factory BackupDataSnapshot.fromJson(Object? value) {
    final root = _map(value, 'data.json');
    final settingsMap = _map(root['settings'], 'settings');
    final settings = AppSettingsRow(
      id: _integer(settingsMap, 'id'),
      studentName: _optionalString(settingsMap, 'studentName'),
      collegeName: _string(settingsMap, 'collegeName'),
      course: _string(settingsMap, 'course'),
      branch: _string(settingsMap, 'branch'),
      academicYearStartDate: _nullableLocalDate(
        settingsMap,
        'academicYearStartDate',
      ),
      academicYearEndDate: _nullableLocalDate(
        settingsMap,
        'academicYearEndDate',
      ),
      defaultAttendanceTarget: _number(settingsMap, 'defaultAttendanceTarget'),
      themeMode: _enumValue(
        CollegeThemeMode.values,
        _string(settingsMap, 'themeMode'),
        'settings.themeMode',
      ),
      onboardingCompleted: _boolean(settingsMap, 'onboardingCompleted'),
      notificationsEnabled: _boolean(settingsMap, 'notificationsEnabled'),
      automaticLocalBackup: _boolean(settingsMap, 'automaticLocalBackup'),
    );
    final semesters = _list(root, 'semesters')
        .map((value) {
          final row = _map(value, 'semester');
          return SemesterRow(
            id: _integer(row, 'id'),
            name: _string(row, 'name'),
            semesterNumber: _integer(row, 'semesterNumber'),
            academicYear: _string(row, 'academicYear'),
            startDate: _localDate(row, 'startDate'),
            endDate: _localDate(row, 'endDate'),
            isActive: _boolean(row, 'isActive'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final subjects = _list(root, 'subjects')
        .map((value) {
          final row = _map(value, 'subject');
          return SubjectRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            name: _string(row, 'name'),
            shortCode: _string(row, 'shortCode'),
            professor: _string(row, 'professor'),
            room: _string(row, 'room'),
            attendanceTarget: _number(row, 'attendanceTarget'),
            displayColor: _integer(row, 'displayColor'),
            isArchived: _boolean(row, 'isArchived'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final timetable = _list(root, 'timetable')
        .map((value) {
          final row = _map(value, 'timetable entry');
          return TimetableEntryRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            subjectId: _integer(row, 'subjectId'),
            weekday: _integer(row, 'weekday'),
            startTime: _integer(row, 'startTime'),
            endTime: _integer(row, 'endTime'),
            room: _string(row, 'room'),
            note: _string(row, 'note'),
            effectiveFrom: _nullableLocalDate(row, 'effectiveFrom'),
            effectiveUntil: _nullableLocalDate(row, 'effectiveUntil'),
          );
        })
        .toList(growable: false);
    final attendance = _list(root, 'attendance')
        .map((value) {
          final row = _map(value, 'attendance session');
          return AttendanceSessionRow(
            id: _integer(row, 'id'),
            subjectId: _integer(row, 'subjectId'),
            date: _localDate(row, 'date'),
            period: _integer(row, 'period'),
            status: _enumValue(
              AttendanceStatus.values,
              _string(row, 'status'),
              'attendance.status',
            ),
            note: _string(row, 'note'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final dailyAttendance = _list(root, 'dailyAttendance')
        .map((value) {
          final row = _map(value, 'daily attendance record');
          return DailyAttendanceRecordRow(
            id: _integer(row, 'id'),
            date: _localDate(row, 'date'),
            status: _enumValue(
              DailyAttendanceStatus.values,
              _string(row, 'status'),
              'dailyAttendance.status',
            ),
            note: _string(row, 'note'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    var scheduledAttendance = _list(root, 'scheduledAttendance')
        .map((value) {
          final row = _map(value, 'scheduled class attendance');
          return ScheduledClassAttendanceRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            timetableEntryId: _nullableInteger(row, 'timetableEntryId'),
            subjectId: _integer(row, 'subjectId'),
            date: _localDate(row, 'date'),
            startTime: _integer(row, 'startTime'),
            endTime: _integer(row, 'endTime'),
            attendanceStatus: _enumValue(
              ClassAttendanceStatus.values,
              _string(row, 'status'),
              'scheduledAttendance.status',
            ),
            note: _string(row, 'note'),
            manuallyModified: _boolean(row, 'manuallyModified'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final dayOverrides = _list(root, 'dayOverrides')
        .map((value) {
          final row = _map(value, 'calendar day override');
          return CalendarDayOverrideRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            date: _localDate(row, 'date'),
            type: _enumValue(
              CalendarDayOverrideType.values,
              _string(row, 'type'),
              'dayOverrides.type',
            ),
            note: _string(row, 'note'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final calendarEvents = _list(root, 'calendarEvents')
        .map((value) {
          final row = _map(value, 'academic calendar event');
          return AcademicCalendarEventRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            title: _string(row, 'title'),
            type: _enumValue(
              AcademicCalendarEventType.values,
              _string(row, 'type'),
              'calendarEvents.type',
            ),
            startDate: _localDate(row, 'startDate'),
            endDate: _localDate(row, 'endDate'),
            note: _string(row, 'note'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    if (scheduledAttendance.isEmpty &&
        root['_migrateLegacyAttendance'] == true &&
        (attendance.isNotEmpty || dailyAttendance.isNotEmpty)) {
      scheduledAttendance = _migrateLegacyAttendance(
        semesters: semesters,
        subjects: subjects,
        timetable: timetable,
        attendance: attendance,
        dailyAttendance: dailyAttendance,
      );
    }
    final tasks = _list(root, 'tasks')
        .map((value) {
          final row = _map(value, 'task');
          return TaskRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            subjectId: _nullableInteger(row, 'subjectId'),
            title: _string(row, 'title'),
            description: _string(row, 'description'),
            type: _enumValue(
              CollegeTaskType.values,
              _string(row, 'type'),
              'task.type',
            ),
            priority: _enumValue(
              TaskPriority.values,
              _string(row, 'priority'),
              'task.priority',
            ),
            dueDate: _nullableLocalDate(row, 'dueDate'),
            dueTime: _nullableInteger(row, 'dueTime'),
            reminderAt: _nullableUtcInstant(row, 'reminderAt'),
            isCompleted: _boolean(row, 'isCompleted'),
            completedAt: _nullableUtcInstant(row, 'completedAt'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final exams = _list(root, 'exams')
        .map((value) {
          final row = _map(value, 'exam');
          return ExamRow(
            id: _integer(row, 'id'),
            semesterId: _integer(row, 'semesterId'),
            subjectId: _integer(row, 'subjectId'),
            name: _string(row, 'name'),
            examType: _string(row, 'examType'),
            examDate: _localDate(row, 'examDate'),
            startTime: _nullableInteger(row, 'startTime'),
            endTime: _nullableInteger(row, 'endTime'),
            room: _string(row, 'room'),
            syllabus: _string(row, 'syllabus'),
            maxMarks: _nullableNumber(row, 'maxMarks'),
            obtainedMarks: _nullableNumber(row, 'obtainedMarks'),
            reminderAt: _nullableUtcInstant(row, 'reminderAt'),
            createdAt: _utcInstant(row, 'createdAt'),
            updatedAt: _utcInstant(row, 'updatedAt'),
          );
        })
        .toList(growable: false);
    final marks = _list(root, 'marks')
        .map((value) {
          final row = _map(value, 'mark');
          return MarkRow(
            id: _integer(row, 'id'),
            subjectId: _integer(row, 'subjectId'),
            examId: _nullableInteger(row, 'examId'),
            category: _string(row, 'category'),
            obtainedMarks: _number(row, 'obtainedMarks'),
            maxMarks: _number(row, 'maxMarks'),
            date: _localDate(row, 'date'),
            note: _string(row, 'note'),
          );
        })
        .toList(growable: false);
    final notes = root.containsKey('notes')
        ? _list(root, 'notes')
            .map((value) {
              final row = _map(value, 'note');
              return SubjectNoteRow(
                id: _integer(row, 'id'),
                subjectId: _integer(row, 'subjectId'),
                semesterId: _integer(row, 'semesterId'),
                title: _string(row, 'title'),
                body: _string(row, 'body'),
                createdAt: _utcInstant(row, 'createdAt'),
                updatedAt: _utcInstant(row, 'updatedAt'),
              );
            })
            .toList(growable: false)
        : const <SubjectNoteRow>[];
    final subjectFiles = root.containsKey('subjectFiles')
        ? _list(root, 'subjectFiles')
            .map((value) {
              final row = _map(value, 'subjectFile');
              return SubjectFileRow(
                id: _integer(row, 'id'),
                subjectId: _integer(row, 'subjectId'),
                semesterId: _integer(row, 'semesterId'),
                title: _string(row, 'title'),
                fileName: _string(row, 'fileName'),
                fileExtension: _string(row, 'fileExtension'),
                fileSizeBytes: _integer(row, 'fileSizeBytes'),
                mimeType: _string(row, 'mimeType'),
                relativeFilePath: _string(row, 'relativeFilePath'),
                createdAt: _utcInstant(row, 'createdAt'),
                updatedAt: _utcInstant(row, 'updatedAt'),
              );
            })
            .toList(growable: false)
        : const <SubjectFileRow>[];
    final result = BackupDataSnapshot(
      settings: settings,
      semesters: semesters,
      subjects: subjects,
      timetable: timetable,
      attendance: attendance,
      dailyAttendance: dailyAttendance,
      scheduledAttendance: scheduledAttendance,
      dayOverrides: dayOverrides,
      calendarEvents: calendarEvents,
      tasks: tasks,
      exams: exams,
      marks: marks,
      notes: notes,
      subjectFiles: subjectFiles,
    );
    result._validate();
    return result;
  }

  void _validate() {
    _require(settings.id == 1, 'Settings must use the singleton ID.');
    _require(
      settings.defaultAttendanceTarget > 0 &&
          settings.defaultAttendanceTarget <= 1,
      'Default attendance target is invalid.',
    );
    _uniquePositive(semesters.map((row) => row.id), 'semester');
    _uniquePositive(subjects.map((row) => row.id), 'subject');
    _uniquePositive(timetable.map((row) => row.id), 'timetable entry');
    _uniquePositive(attendance.map((row) => row.id), 'attendance session');
    _uniquePositive(
      dailyAttendance.map((row) => row.id),
      'daily attendance record',
    );
    _uniquePositive(
      scheduledAttendance.map((row) => row.id),
      'scheduled class attendance',
    );
    _uniquePositive(dayOverrides.map((row) => row.id), 'day override');
    _uniquePositive(calendarEvents.map((row) => row.id), 'calendar event');
    _require(
      dailyAttendance.map((row) => _date(row.date)).toSet().length ==
          dailyAttendance.length,
      'A daily attendance date is duplicated.',
    );
    _uniquePositive(tasks.map((row) => row.id), 'task');
    _uniquePositive(exams.map((row) => row.id), 'exam');
    _uniquePositive(marks.map((row) => row.id), 'mark');
    _uniquePositive(notes.map((row) => row.id), 'note');
    _uniquePositive(subjectFiles.map((row) => row.id), 'subject file');
    _require(
      semesters.where((row) => row.isActive).length <= 1,
      'More than one semester is active.',
    );
    final semesterIds = semesters.map((row) => row.id).toSet();
    final subjectById = {for (final row in subjects) row.id: row};
    final examById = {for (final row in exams) row.id: row};
    for (final row in semesters) {
      _require(
        row.name.trim().isNotEmpty && row.academicYear.trim().isNotEmpty,
        'A semester is missing required text.',
      );
      _require(
        row.semesterNumber > 0 && !row.endDate.isBefore(row.startDate),
        'A semester has invalid dates or number.',
      );
    }
    for (final row in calendarEvents) {
      _require(
        semesterIds.contains(row.semesterId),
        'A calendar event references a missing semester.',
      );
      _require(
        row.title.trim().isNotEmpty && !row.endDate.isBefore(row.startDate),
        'A calendar event has invalid text or dates.',
      );
    }
    for (final row in subjects) {
      _require(
        semesterIds.contains(row.semesterId),
        'A subject references a missing semester.',
      );
      _require(row.name.trim().isNotEmpty, 'A subject name is missing.');
      _require(
        row.attendanceTarget > 0 && row.attendanceTarget <= 1,
        'A subject attendance target is invalid.',
      );
      _require(
        row.displayColor >= 0 && row.displayColor <= 0xFFFFFFFF,
        'A subject color is invalid.',
      );
    }
    void validSubjectSemester(int subjectId, int semesterId, String label) {
      final subject = subjectById[subjectId];
      _require(
        subject != null && subject.semesterId == semesterId,
        '$label references an invalid subject or semester.',
      );
    }

    for (final row in timetable) {
      validSubjectSemester(row.subjectId, row.semesterId, 'A timetable entry');
      _require(
        row.weekday >= 1 &&
            row.weekday <= 7 &&
            row.startTime >= 0 &&
            row.startTime < 1440 &&
            row.endTime > row.startTime &&
            row.endTime <= 1440,
        'A timetable entry has an invalid schedule.',
      );
      _require(
        row.effectiveFrom == null ||
            row.effectiveUntil == null ||
            !row.effectiveUntil!.isBefore(row.effectiveFrom!),
        'A timetable entry has an invalid effective date range.',
      );
    }
    for (final row in attendance) {
      _require(
        subjectById.containsKey(row.subjectId) && row.period > 0,
        'An attendance session is invalid.',
      );
    }
    final timetableById = {for (final row in timetable) row.id: row};
    final scheduledKeys = <String>{};
    for (final row in scheduledAttendance) {
      validSubjectSemester(
        row.subjectId,
        row.semesterId,
        'Scheduled attendance',
      );
      _require(
        row.startTime >= 0 &&
            row.startTime < 1440 &&
            row.endTime > row.startTime &&
            row.endTime <= 1440,
        'Scheduled attendance has an invalid time range.',
      );
      if (row.timetableEntryId != null) {
        final entry = timetableById[row.timetableEntryId];
        _require(
          entry != null && entry.semesterId == row.semesterId,
          'Scheduled attendance references an invalid timetable entry.',
        );
        _require(
          scheduledKeys.add('${_date(row.date)}:${row.timetableEntryId}'),
          'Scheduled attendance contains a duplicate class for one date.',
        );
      }
    }
    final overrideKeys = <String>{};
    for (final row in dayOverrides) {
      _require(
        semesterIds.contains(row.semesterId) &&
            overrideKeys.add('${row.semesterId}:${_date(row.date)}'),
        'A calendar day override is invalid or duplicated.',
      );
    }
    for (final row in tasks) {
      _require(
        semesterIds.contains(row.semesterId) && row.title.trim().isNotEmpty,
        'A task is invalid.',
      );
      if (row.subjectId != null) {
        validSubjectSemester(row.subjectId!, row.semesterId, 'A task');
      }
      _require(
        row.dueTime == null ||
            (row.dueDate != null && row.dueTime! >= 0 && row.dueTime! < 1440),
        'A task due time is invalid.',
      );
      _require(
        row.isCompleted == (row.completedAt != null),
        'A task completion state is invalid.',
      );
    }
    for (final row in exams) {
      validSubjectSemester(row.subjectId, row.semesterId, 'An exam');
      _require(
        row.name.trim().isNotEmpty && row.examType.trim().isNotEmpty,
        'An exam is missing required text.',
      );
      _require(
        row.startTime == null || (row.startTime! >= 0 && row.startTime! < 1440),
        'An exam start time is invalid.',
      );
      _require(
        row.endTime == null || (row.endTime! > 0 && row.endTime! <= 1440),
        'An exam end time is invalid.',
      );
      _require(
        row.startTime == null ||
            row.endTime == null ||
            row.endTime! > row.startTime!,
        'An exam time range is invalid.',
      );
      _require(
        row.maxMarks == null || row.maxMarks! > 0,
        'An exam maximum mark is invalid.',
      );
      _require(
        row.obtainedMarks == null ||
            (row.obtainedMarks! >= 0 &&
                (row.maxMarks == null || row.obtainedMarks! <= row.maxMarks!)),
        'An exam obtained mark is invalid.',
      );
    }
    for (final row in marks) {
      _require(
        subjectById.containsKey(row.subjectId),
        'A mark references a missing subject.',
      );
      _require(
        row.category.trim().isNotEmpty &&
            row.maxMarks > 0 &&
            row.obtainedMarks >= 0 &&
            row.obtainedMarks <= row.maxMarks,
        'A mark is invalid.',
      );
      if (row.examId != null) {
        final exam = examById[row.examId];
        _require(
          exam != null && exam.subjectId == row.subjectId,
          'A mark references an invalid exam.',
        );
      }
    }
    for (final row in notes) {
      validSubjectSemester(row.subjectId, row.semesterId, 'A note');
      _require(row.body.trim().isNotEmpty, 'A note body is empty.');
    }
    for (final row in subjectFiles) {
      validSubjectSemester(row.subjectId, row.semesterId, 'A subject file');
      _require(row.fileName.trim().isNotEmpty, 'A subject file name is empty.');
      _require(
        row.relativeFilePath.trim().isNotEmpty,
        'A subject file path is empty.',
      );
    }
  }
}

List<ScheduledClassAttendanceRow> _migrateLegacyAttendance({
  required List<SemesterRow> semesters,
  required List<SubjectRow> subjects,
  required List<TimetableEntryRow> timetable,
  required List<AttendanceSessionRow> attendance,
  required List<DailyAttendanceRecordRow> dailyAttendance,
}) {
  final result = <ScheduledClassAttendanceRow>[];
  final subjectById = {for (final row in subjects) row.id: row};
  var nextId = 1;
  for (final legacy in attendance) {
    final subject = subjectById[legacy.subjectId];
    if (subject == null) continue;
    final dayEntries =
        timetable
            .where(
              (entry) =>
                  entry.semesterId == subject.semesterId &&
                  entry.weekday == legacy.date.weekday,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    TimetableEntryRow? match;
    if (legacy.period > 0 && legacy.period <= dayEntries.length) {
      final candidate = dayEntries[legacy.period - 1];
      if (candidate.subjectId == legacy.subjectId) match = candidate;
    }
    final sameSubject = dayEntries
        .where((entry) => entry.subjectId == legacy.subjectId)
        .toList();
    if (match == null && sameSubject.length == 1) match = sameSubject.single;
    final fallbackStart = (legacy.period - 1).clamp(0, 23) * 60;
    result.add(
      ScheduledClassAttendanceRow(
        id: nextId++,
        semesterId: subject.semesterId,
        timetableEntryId: match?.id,
        subjectId: legacy.subjectId,
        date: legacy.date,
        startTime: match?.startTime ?? fallbackStart,
        endTime: match?.endTime ?? (fallbackStart + 60).clamp(1, 1440),
        attendanceStatus: ClassAttendanceStatus.values.byName(
          legacy.status.name,
        ),
        note: legacy.note,
        manuallyModified: true,
        createdAt: legacy.createdAt,
        updatedAt: legacy.updatedAt,
      ),
    );
  }
  final legacyDates = attendance.map((row) => _date(row.date)).toSet();
  for (final daily in dailyAttendance) {
    if (legacyDates.contains(_date(daily.date))) continue;
    final candidates = semesters
        .where(
          (semester) =>
              !daily.date.isBefore(semester.startDate) &&
              !daily.date.isAfter(semester.endDate),
        )
        .toList();
    if (candidates.length != 1) continue;
    final semester = candidates.single;
    for (final entry in timetable.where(
      (entry) =>
          entry.semesterId == semester.id &&
          entry.weekday == daily.date.weekday,
    )) {
      result.add(
        ScheduledClassAttendanceRow(
          id: nextId++,
          semesterId: semester.id,
          timetableEntryId: entry.id,
          subjectId: entry.subjectId,
          date: daily.date,
          startTime: entry.startTime,
          endTime: entry.endTime,
          attendanceStatus: ClassAttendanceStatus.values.byName(
            daily.status.name,
          ),
          note: daily.note,
          manuallyModified: false,
          createdAt: daily.createdAt,
          updatedAt: daily.updatedAt,
        ),
      );
    }
  }
  return List.unmodifiable(result);
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String _instant(DateTime value) => value.toUtc().toIso8601String();

Map<String, dynamic> _map(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    throw BackupException('invalid_data', '$label must be an object.');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! List<dynamic>) {
    throw BackupException('invalid_data', '$key must be a list.');
  }
  return value;
}

String _string(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String) {
    throw BackupException('invalid_data', '$key must be text.');
  }
  return value;
}

String _optionalString(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) return '';
  return _string(map, key);
}

int _integer(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! int) {
    throw BackupException('invalid_data', '$key must be an integer.');
  }
  return value;
}

int? _nullableInteger(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! int) {
    throw BackupException('invalid_data', '$key must be an integer or null.');
  }
  return value;
}

double _number(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! num || !value.isFinite) {
    throw BackupException('invalid_data', '$key must be a finite number.');
  }
  return value.toDouble();
}

double? _nullableNumber(Map<String, dynamic> map, String key) {
  if (map[key] == null) return null;
  return _number(map, key);
}

bool _boolean(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! bool) {
    throw BackupException('invalid_data', '$key must be true or false.');
  }
  return value;
}

DateTime _localDate(Map<String, dynamic> map, String key) {
  final value = _string(map, key);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw BackupException('invalid_data', '$key is not a valid local date.');
  }
  final date = DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
  if (_date(date) != value) {
    throw BackupException('invalid_data', '$key is not a valid local date.');
  }
  return date;
}

DateTime? _nullableLocalDate(Map<String, dynamic> map, String key) =>
    map[key] == null ? null : _localDate(map, key);

DateTime _utcInstant(Map<String, dynamic> map, String key) {
  final value = _string(map, key);
  final instant = DateTime.tryParse(value);
  if (instant == null || !instant.isUtc) {
    throw BackupException('invalid_data', '$key is not a UTC timestamp.');
  }
  return instant;
}

DateTime? _nullableUtcInstant(Map<String, dynamic> map, String key) =>
    map[key] == null ? null : _utcInstant(map, key);

T _enumValue<T extends Enum>(List<T> values, String name, String label) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw BackupException('invalid_data', '$label has an unsupported value.');
}

void _uniquePositive(Iterable<int> ids, String label) {
  final seen = <int>{};
  for (final id in ids) {
    _require(id > 0 && seen.add(id), 'A $label ID is invalid or duplicated.');
  }
}

void _require(bool condition, String message) {
  if (!condition) throw BackupException('invalid_relationships', message);
}
