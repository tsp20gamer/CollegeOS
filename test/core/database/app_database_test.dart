import 'dart:io';

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/attendance/data/drift_attendance_repository.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/settings/data/drift_settings_repository.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('current schema', () {
    test('matches the generated Drift schema', () async {
      await database.validateDatabaseSchema();
    });

    test('inserts every entity and converts dates and enums', () async {
      final semesterId = await _insertSemester(database, active: true);
      final subjectId = await _insertSubject(database, semesterId);

      final timetableId = await database.timetableDao.insertEntry(
        TimetableEntriesCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: DateTime.monday,
          startTime: 9 * 60,
          endTime: 10 * 60,
        ),
      );
      final attendanceId = await database.attendanceDao.insertSession(
        AttendanceSessionsCompanion.insert(
          subjectId: subjectId,
          date: DateTime(2026, 8, 12, 23, 59),
          period: 1,
          status: AttendanceStatus.present,
        ),
      );
      final taskId = await database.tasksDao.insertTask(
        CollegeTasksCompanion.insert(
          semesterId: semesterId,
          subjectId: Value(subjectId),
          title: 'Submit lab',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: Value(DateTime(2026, 8, 20)),
        ),
      );
      final examId = await database.examsDao.insertExam(
        ExamsCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          name: 'Midterm',
          examType: 'written',
          examDate: DateTime(2026, 9, 1),
          maxMarks: const Value(100),
        ),
      );
      final markId = await database.marksDao.insertMark(
        MarksCompanion.insert(
          subjectId: subjectId,
          examId: Value(examId),
          category: 'Midterm',
          obtainedMarks: 82,
          maxMarks: 100,
          date: DateTime(2026, 9, 5),
        ),
      );

      expect([
        timetableId,
        attendanceId,
        taskId,
        examId,
        markId,
      ], everyElement(isPositive));
      final attendance = await (database.select(
        database.attendanceSessions,
      )..where((row) => row.id.equals(attendanceId))).getSingle();
      expect(attendance.date, DateTime(2026, 8, 12));
      expect(attendance.status, AttendanceStatus.present);
      expect(await database.passesIntegrityCheck(), isTrue);
      expect(await database.passesForeignKeyCheck(), isTrue);
    });

    test('keeps exactly one active semester and supports update', () async {
      final firstId = await _insertSemester(database, active: true);
      final secondId = await _insertSemester(
        database,
        name: 'Semester 2',
        number: 2,
      );

      await database.semestersDao.setActive(secondId);
      final rows = await database.semestersDao.watchAll().first;

      expect(rows.singleWhere((row) => row.id == firstId).isActive, isFalse);
      expect(rows.singleWhere((row) => row.id == secondId).isActive, isTrue);
      expect(await database.semestersDao.findActive(), isNotNull);
      expect(
        () => _insertSemester(database, name: 'Duplicate active', active: true),
        throwsA(anything),
      );
    });

    test('archives and updates subjects through the repository', () async {
      final semesterId = await _insertSemester(database);
      final repository = DriftSubjectRepository(database.subjectsDao);
      final subjectId = await repository.create((
        semesterId: semesterId,
        name: ' Data Structures ',
        shortCode: ' DS ',
        professor: ' Dr Rao ',
        room: ' A-12 ',
        attendanceTarget: 0.8,
        displayColor: 0xFF6750A4,
      ));

      await repository.setArchived(subjectId, archived: true);
      expect(await repository.watchForSemester(semesterId).first, isEmpty);
      final archived = await repository
          .watchForSemester(semesterId, includeArchived: true)
          .first;
      expect(archived.single.name, 'Data Structures');
      expect(archived.single.shortCode, 'DS');
      expect(archived.single.isArchived, isTrue);
    });

    test('reactively queries attendance counts and held classes', () async {
      final semesterId = await _insertSemester(database);
      final subjectId = await _insertSubject(database, semesterId);
      final repository = DriftAttendanceRepository(database.attendanceDao);

      expect(await repository.watchCountsForSubject(subjectId).first, (
        present: 0,
        absent: 0,
        cancelled: 0,
        held: 0,
      ));
      for (final status in [
        AttendanceStatus.present,
        AttendanceStatus.present,
        AttendanceStatus.absent,
        AttendanceStatus.cancelled,
      ]) {
        await repository.create((
          subjectId: subjectId,
          date: DateTime(2026, 8, 12),
          period: status.index + 1,
          status: status,
          note: '',
        ));
      }

      expect(await repository.watchCountsForSubject(subjectId).first, (
        present: 2,
        absent: 1,
        cancelled: 1,
        held: 3,
      ));
    });

    test('filters tasks and maintains completion invariants', () async {
      final semesterId = await _insertSemester(database);
      final taskId = await database.tasksDao.insertTask(
        CollegeTasksCompanion.insert(
          semesterId: semesterId,
          title: 'Read chapter',
          type: CollegeTaskType.study,
          priority: TaskPriority.medium,
        ),
      );

      expect(
        await database.tasksDao
            .watchForSemester(semesterId, completed: false)
            .first,
        hasLength(1),
      );
      await database.tasksDao.setCompleted(taskId, completed: true);
      final completed = await database.tasksDao
          .watchForSemester(semesterId, completed: true)
          .first;
      expect(completed.single.completedAt, isNotNull);

      await database.tasksDao.setCompleted(taskId, completed: false);
      final reopened = await database.tasksDao
          .watchForSemester(semesterId, completed: false)
          .first;
      expect(reopened.single.completedAt, isNull);
    });

    test('enforces relationships and cascades subject deletion', () async {
      final firstSemesterId = await _insertSemester(database);
      final secondSemesterId = await _insertSemester(
        database,
        name: 'Semester 2',
        number: 2,
      );
      final subjectId = await _insertSubject(database, firstSemesterId);

      expect(
        () => database.timetableDao.insertEntry(
          TimetableEntriesCompanion.insert(
            semesterId: secondSemesterId,
            subjectId: subjectId,
            weekday: 1,
            startTime: 600,
            endTime: 660,
          ),
        ),
        throwsA(anything),
      );

      await database.attendanceDao.insertSession(
        AttendanceSessionsCompanion.insert(
          subjectId: subjectId,
          date: DateTime(2026, 8, 12),
          period: 1,
          status: AttendanceStatus.absent,
        ),
      );
      await database.tasksDao.insertTask(
        CollegeTasksCompanion.insert(
          semesterId: firstSemesterId,
          subjectId: Value(subjectId),
          title: 'Assignment',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.low,
        ),
      );
      final examId = await database.examsDao.insertExam(
        ExamsCompanion.insert(
          semesterId: firstSemesterId,
          subjectId: subjectId,
          name: 'Quiz',
          examType: 'quiz',
          examDate: DateTime(2026, 8, 30),
        ),
      );
      await database.marksDao.insertMark(
        MarksCompanion.insert(
          subjectId: subjectId,
          examId: Value(examId),
          category: 'Quiz',
          obtainedMarks: 8,
          maxMarks: 10,
          date: DateTime(2026, 8, 31),
        ),
      );

      await database.subjectsDao.deleteById(subjectId);
      expect(await database.select(database.attendanceSessions).get(), isEmpty);
      expect(await database.select(database.collegeTasks).get(), isEmpty);
      expect(await database.select(database.exams).get(), isEmpty);
      expect(await database.select(database.marks).get(), isEmpty);
      expect(await database.passesForeignKeyCheck(), isTrue);
    });

    test('persists and updates singleton app settings', () async {
      final repository = DriftSettingsRepository(database.settingsDao);
      final defaults = await repository.get();
      expect(defaults.defaultAttendanceTarget, 0.75);
      expect(defaults.automaticLocalBackup, isTrue);

      await repository.save((
        studentName: 'Test Student',
        collegeName: 'College of Engineering',
        course: 'B.Tech',
        branch: 'Computer Science',
        academicYearStartDate: DateTime(2026, 8, 1),
        academicYearEndDate: DateTime(2027, 4, 30),
        defaultAttendanceTarget: 0.8,
        themeMode: CollegeThemeMode.dark,
        onboardingCompleted: true,
        notificationsEnabled: true,
        automaticLocalBackup: false,
      ));
      final settings = await repository.get();
      expect(settings.studentName, 'Test Student');
      expect(settings.collegeName, 'College of Engineering');
      expect(settings.themeMode, CollegeThemeMode.dark);
      expect(settings.onboardingCompleted, isTrue);
      expect(settings.automaticLocalBackup, isFalse);
      expect(await database.select(database.appSettings).get(), hasLength(1));
    });
  });

  test(
    'complete file-backed database survives repeated close and reopen',
    () async {
      await database.close();
      final directory = await Directory.systemTemp.createTemp(
        'college_os_persistence_',
      );
      final file = File(p.join(directory.path, 'college_os.sqlite'));
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      database = AppDatabase.forTesting(NativeDatabase(file));
      await database
          .update(database.appSettings)
          .write(
            const AppSettingsCompanion(
              collegeName: Value('Persistent College'),
              course: Value('B.Tech'),
              branch: Value('Computer Science'),
              defaultAttendanceTarget: Value(0.8),
              themeMode: Value(CollegeThemeMode.dark),
              onboardingCompleted: Value(true),
            ),
          );
      final semesterId = await _insertSemester(
        database,
        name: 'Persistent Semester',
        active: true,
      );
      final subjectId = await _insertSubject(
        database,
        semesterId,
        name: 'Operating Systems',
      );
      await database.timetableDao.insertEntry(
        TimetableEntriesCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          weekday: DateTime.monday,
          startTime: 9 * 60,
          endTime: 10 * 60,
          room: const Value('Lab 2'),
        ),
      );
      await database.attendanceDao.insertSession(
        AttendanceSessionsCompanion.insert(
          subjectId: subjectId,
          date: DateTime(2026, 8, 12),
          period: 1,
          status: AttendanceStatus.present,
        ),
      );
      await database.tasksDao.insertTask(
        CollegeTasksCompanion.insert(
          semesterId: semesterId,
          subjectId: Value(subjectId),
          title: 'Persistent assignment',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: Value(DateTime(2026, 8, 20)),
        ),
      );
      final examId = await database.examsDao.insertExam(
        ExamsCompanion.insert(
          semesterId: semesterId,
          subjectId: subjectId,
          name: 'Persistent midterm',
          examType: 'written',
          examDate: DateTime(2026, 9, 1),
          maxMarks: const Value(100),
        ),
      );
      await database.marksDao.insertMark(
        MarksCompanion.insert(
          subjectId: subjectId,
          examId: Value(examId),
          category: 'Internal',
          obtainedMarks: 82,
          maxMarks: 100,
          date: DateTime(2026, 9, 5),
        ),
      );
      final expected = (await DriftBackupDatabaseStore(
        database,
      ).capture()).toJson();

      for (var restart = 0; restart < 3; restart++) {
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));

        expect(
          (await DriftBackupDatabaseStore(database).capture()).toJson(),
          expected,
          reason: 'Data changed after restart ${restart + 1}',
        );
        expect(await database.passesIntegrityCheck(), isTrue);
        expect(await database.passesForeignKeyCheck(), isTrue);
      }

      await database.close();
      database = AppDatabase.forTesting(NativeDatabase.memory());
    },
  );

  test('upgrading the schema keeps an existing PDF search index', () async {
    await database.close();
    final directory = await Directory.systemTemp.createTemp(
      'college_os_pdf_upgrade_',
    );
    final file = File(p.join(directory.path, 'college_os.sqlite'));
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    database = AppDatabase.forTesting(NativeDatabase(file));
    final semesterId = await _insertSemester(database, active: true);
    final subjectId = await _insertSubject(database, semesterId);
    final fileId = await database.subjectFilesDao.insertFile(
      SubjectFilesCompanion.insert(
        subjectId: subjectId,
        semesterId: semesterId,
        fileName: 'notes.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 91 * 1024 * 1024,
        relativeFilePath: 'notes/notes.pdf',
      ),
    );

    // Rewind the database to the shape and version it had before the resume
    // column existed, with an index that was interrupted at page 250 of 412.
    await database.customStatement(
      'ALTER TABLE pdf_search_metadata DROP COLUMN last_indexed_page',
    );
    await database.customStatement('''
INSERT INTO pdf_search_metadata (file_id, status, page_count, indexed_at)
VALUES ($fileId, 'indexing (250/412)', 412, 0)
''');
    await database.customStatement('''
INSERT INTO pdf_page_fts (file_id, page_number, page_text)
VALUES ('$fileId', '1', 'a page that was already extracted')
''');
    await database.customStatement('PRAGMA user_version = 12');
    await database.close();

    // Reopening runs the v12 -> v13 migration.
    database = AppDatabase.forTesting(NativeDatabase(file));

    final meta = await database.pdfSearchDao.getMetadata(fileId);
    expect(meta, isNotNull, reason: 'the upgrade must keep the index metadata');
    expect(meta!.status, 'indexing (250/412)');
    expect(meta.pageCount, 412);
    expect(
      meta.lastIndexedPage,
      0,
      reason: 'a database written before the column existed starts at 0',
    );
    expect(
      await database.pdfSearchDao.search('extracted'),
      hasLength(1),
      reason: 'pages indexed before the upgrade stay searchable',
    );

    // The new column is usable, so the interrupted run resumes after 250.
    await database.pdfSearchDao.saveExtractedBatch(
      fileId,
      [const PdfExtractedPage(pageNumber: 251, text: 'a newly extracted page')],
      lastPageIndexed: 251,
      totalPages: 412,
    );
    final resumed = await database.pdfSearchDao.getMetadata(fileId);
    expect(resumed?.status, 'indexing (251/412)');
    expect(resumed?.lastIndexedPage, 251);
    expect(await database.passesIntegrityCheck(), isTrue);
    expect(await database.passesForeignKeyCheck(), isTrue);

    await database.close();
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });
}

Future<int> _insertSemester(
  AppDatabase database, {
  String name = 'Semester 1',
  int number = 1,
  bool active = false,
}) {
  return database.semestersDao.insertSemester(
    SemestersCompanion.insert(
      name: name,
      semesterNumber: number,
      academicYear: '2026-2027',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 12, 20),
      isActive: Value(active),
    ),
  );
}

Future<int> _insertSubject(
  AppDatabase database,
  int semesterId, {
  String name = 'Algorithms',
}) {
  return database.subjectsDao.insertSubject(
    SubjectsCompanion.insert(
      semesterId: semesterId,
      name: name,
      displayColor: 0xFF6750A4,
    ),
  );
}
