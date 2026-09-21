import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/data/backup_service.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftBackupDatabaseStore store;
  late CollegeOsBackupCodec codec;
  late _MemoryEmergencyStore emergency;
  late CollegeOsBackupService service;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftBackupDatabaseStore(database);
    codec = CollegeOsBackupCodec();
    emergency = _MemoryEmergencyStore();
    service = CollegeOsBackupService(
      store,
      codec,
      emergency,
      now: () => DateTime(2026, 8, 12, 15),
    );
    await _seedCompleteDatabase(database);
  });

  tearDown(() => database.close());

  test(
    'full .collegeos backup round-trips every table and relationship',
    () async {
      final expected = (await store.capture()).toJson();
      final backup = await service.create('1.0.0+1');

      expect(backup.fileName, 'CollegeOS_Backup_2026-08-12_1500.collegeos');
      final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
      expect(archive.find('manifest.json'), isA<ArchiveFile>());
      expect(archive.find('data.json'), isA<ArchiveFile>());
      expect(archive.find('attachments/'), isA<ArchiveFile>());

      await _wipe(database);
      expect(await database.select(database.subjects).get(), isEmpty);
      final prepared = service.inspect(
        bytes: backup.bytes,
        sourceName: backup.fileName,
      );
      await service.restore(prepared, '1.0.0+1');

      expect((await store.capture()).toJson(), expected);
      expect(await database.passesIntegrityCheck(), isTrue);
      expect(await database.passesForeignKeyCheck(), isTrue);
      expect(emergency.saved, isA<ExportedBackup>());
    },
  );

  test('rejects a corrupt archive without changing data', () async {
    final before = (await store.capture()).toJson();
    expect(
      () => service.inspect(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        sourceName: 'broken.collegeos',
      ),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_archive',
        ),
      ),
    );
    expect((await store.capture()).toJson(), before);
  });

  test('rejects a valid archive with the wrong file extension', () async {
    final backup = await service.create('1.0.0+1');
    final before = (await store.capture()).toJson();

    expect(
      () => service.inspect(bytes: backup.bytes, sourceName: 'backup.zip'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_extension',
        ),
      ),
    );
    expect((await store.capture()).toJson(), before);
  });

  test('rejects an invalid manifest', () async {
    final backup = await service.create('1.0.0+1');
    final changed = _replaceJson(
      backup.bytes,
      'manifest.json',
      <String, Object?>{},
    );
    expect(
      () => service.inspect(bytes: changed, sourceName: 'invalid.collegeos'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_manifest',
        ),
      ),
    );
  });

  test('rejects an unsupported future backup version', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
    final manifest =
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
            as Map<String, dynamic>;
    manifest['backupFormatVersion'] = 999;
    final changed = _replaceJson(backup.bytes, 'manifest.json', manifest);
    expect(
      () => service.inspect(bytes: changed, sourceName: 'future.collegeos'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'unsupported_future_backup',
        ),
      ),
    );
  });

  test('rejects an unsupported future database schema', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
    final manifest =
        jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
            as Map<String, dynamic>;
    manifest['databaseSchemaVersion'] = 999;
    final changed = _replaceJson(backup.bytes, 'manifest.json', manifest);
    expect(
      () => service.inspect(bytes: changed, sourceName: 'future.collegeos'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'unsupported_future_schema',
        ),
      ),
    );
  });

  test('rejects zip-slip paths even when required files exist', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true)
      ..add(ArchiveFile.string('../outside.txt', 'unsafe'));
    final changed = ZipEncoder().encodeBytes(archive);
    expect(
      () => service.inspect(bytes: changed, sourceName: 'unsafe.collegeos'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'unsafe_archive',
        ),
      ),
    );
  });

  test('schema-v2 backups default automatic local backup to enabled', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
    final data =
        jsonDecode(utf8.decode(archive.find('data.json')!.content))
            as Map<String, dynamic>;
    data['settings'] as Map<String, dynamic>
      ..remove('automaticLocalBackup')
      ..remove('studentName');
    final legacy = _replaceDataAndHash(
      backup.bytes,
      data,
      databaseSchemaVersion: 2,
    );

    final prepared = service.inspect(
      bytes: legacy,
      sourceName: 'schema_v2.collegeos',
    );

    expect(prepared.data.settings.automaticLocalBackup, isTrue);
    expect(prepared.data.settings.studentName, isEmpty);
  });

  test('schema-v3 backups default exam reminder intent to off', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
    final data =
        jsonDecode(utf8.decode(archive.find('data.json')!.content))
            as Map<String, dynamic>;
    for (final exam in data['exams'] as List<dynamic>) {
      (exam as Map<String, dynamic>).remove('reminderAt');
    }
    final legacy = _replaceDataAndHash(
      backup.bytes,
      data,
      databaseSchemaVersion: 3,
    );

    final prepared = service.inspect(
      bytes: legacy,
      sourceName: 'schema_v3.collegeos',
    );

    expect(prepared.data.exams.single.reminderAt, null);
  });

  test('schema-v6 backups default academic calendar events to empty', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
    final data =
        jsonDecode(utf8.decode(archive.find('data.json')!.content))
            as Map<String, dynamic>;
    data.remove('calendarEvents');
    final legacy = _replaceDataAndHash(
      backup.bytes,
      data,
      databaseSchemaVersion: 6,
    );

    final prepared = service.inspect(
      bytes: legacy,
      sourceName: 'schema_v6.collegeos',
    );

    expect(prepared.data.calendarEvents, isEmpty);
  });

  test('rejects broken relationships before restore', () async {
    final backup = await service.create('1.0.0+1');
    final archive = ZipDecoder().decodeBytes(backup.bytes, verify: true);
    final data =
        jsonDecode(utf8.decode(archive.find('data.json')!.content))
            as Map<String, dynamic>;
    (data['subjects'] as List<dynamic>).first['semesterId'] = 99999;
    final changed = _replaceDataAndHash(backup.bytes, data);
    expect(
      () => service.inspect(bytes: changed, sourceName: 'relations.collegeos'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.code,
          'code',
          'invalid_relationships',
        ),
      ),
    );
  });

  test(
    'forced restore failure rolls back every deletion and insertion',
    () async {
      final incoming = await service.create('1.0.0+1');
      final prepared = service.inspect(
        bytes: incoming.bytes,
        sourceName: incoming.fileName,
      );
      await database
          .update(database.appSettings)
          .write(
            const AppSettingsCompanion(
              collegeName: Value('Current Device College'),
            ),
          );
      final before = (await store.capture()).toJson();
      final failingStore = DriftBackupDatabaseStore(
        database,
        beforeRestoreCommit: () => throw StateError('injected failure'),
      );
      final failingService = CollegeOsBackupService(
        failingStore,
        codec,
        emergency,
        now: () => DateTime(2026, 8, 12, 16),
      );

      await expectLater(
        failingService.restore(prepared, '1.0.0+1'),
        throwsA(
          isA<BackupException>().having(
            (error) => error.code,
            'code',
            'restore_failed',
          ),
        ),
      );
      expect((await store.capture()).toJson(), before);
      expect(await database.passesForeignKeyCheck(), isTrue);
      expect(emergency.saved, isA<ExportedBackup>());
    },
  );
}

final class _MemoryEmergencyStore implements EmergencyBackupStore {
  ExportedBackup? saved;

  @override
  Future<void> clear() async => saved = null;

  @override
  Future<void> save(ExportedBackup backup) async => saved = backup;
}

Future<void> _seedCompleteDatabase(AppDatabase database) async {
  final created = DateTime.utc(2026, 8, 1, 10);
  await database
      .update(database.appSettings)
      .write(
        AppSettingsCompanion(
          studentName: Value('Test Student'),
          collegeName: Value('City College'),
          course: Value('B.Tech'),
          branch: Value('Computer Science'),
          academicYearStartDate: Value(DateTime(2026, 8, 1)),
          academicYearEndDate: Value(DateTime(2027, 4, 30)),
          defaultAttendanceTarget: Value(0.8),
          themeMode: Value(CollegeThemeMode.dark),
          onboardingCompleted: Value(true),
          notificationsEnabled: Value(true),
          automaticLocalBackup: Value(true),
        ),
      );
  await database
      .into(database.semesters)
      .insert(
        SemesterRow(
          id: 11,
          name: 'Semester 3',
          semesterNumber: 3,
          academicYear: '2026-2027',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 12, 20),
          isActive: true,
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.subjects)
      .insert(
        SubjectRow(
          id: 21,
          semesterId: 11,
          name: 'Operating Systems',
          shortCode: 'OS',
          professor: 'Dr Rao',
          room: 'A-101',
          attendanceTarget: 0.8,
          displayColor: 0xFF2563EB,
          isArchived: false,
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.timetableEntries)
      .insert(
        TimetableEntryRow(
          id: 31,
          semesterId: 11,
          subjectId: 21,
          weekday: DateTime.monday,
          startTime: 540,
          endTime: 600,
          room: 'Lab 2',
          note: 'Bring laptop',
          effectiveFrom: DateTime(2026, 8, 1),
          effectiveUntil: DateTime(2026, 9, 30),
        ),
      );
  await database
      .into(database.scheduledClassAttendance)
      .insert(
        ScheduledClassAttendanceRow(
          id: 43,
          semesterId: 11,
          timetableEntryId: 31,
          subjectId: 21,
          date: DateTime(2026, 8, 10),
          startTime: 540,
          endTime: 600,
          attendanceStatus: ClassAttendanceStatus.absent,
          note: 'Missed bus',
          manuallyModified: true,
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.calendarDayOverrides)
      .insert(
        CalendarDayOverrideRow(
          id: 44,
          semesterId: 11,
          date: DateTime(2026, 8, 17),
          type: CalendarDayOverrideType.holiday,
          note: 'College holiday',
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.academicCalendarEvents)
      .insert(
        AcademicCalendarEventRow(
          id: 45,
          semesterId: 11,
          title: 'Festival break',
          type: AcademicCalendarEventType.holiday,
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 3),
          note: 'College holiday range',
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.attendanceSessions)
      .insert(
        AttendanceSessionRow(
          id: 41,
          subjectId: 21,
          date: DateTime(2026, 8, 12),
          period: 1,
          status: AttendanceStatus.present,
          note: 'On time',
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.dailyAttendanceRecords)
      .insert(
        DailyAttendanceRecordRow(
          id: 42,
          date: DateTime(2026, 8, 12),
          status: DailyAttendanceStatus.present,
          note: 'College day',
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.collegeTasks)
      .insert(
        TaskRow(
          id: 51,
          semesterId: 11,
          subjectId: 21,
          title: 'Kernel assignment',
          description: 'Finish scheduler',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 8, 20),
          dueTime: 1020,
          reminderAt: DateTime.utc(2026, 8, 20, 10),
          isCompleted: false,
          completedAt: null,
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.exams)
      .insert(
        ExamRow(
          id: 61,
          semesterId: 11,
          subjectId: 21,
          name: 'Midterm',
          examType: 'Written',
          examDate: DateTime(2026, 9, 10),
          startTime: 600,
          endTime: 720,
          room: 'Hall A',
          syllabus: 'Units 1-3',
          maxMarks: 100,
          obtainedMarks: 84,
          reminderAt: DateTime.utc(2026, 9, 9, 10),
          createdAt: created,
          updatedAt: created,
        ),
      );
  await database
      .into(database.marks)
      .insert(
        MarkRow(
          id: 71,
          subjectId: 21,
          examId: 61,
          category: 'semester_exam',
          obtainedMarks: 84,
          maxMarks: 100,
          date: DateTime(2026, 9, 15),
          note: 'Published',
        ),
      );
}

Future<void> _wipe(AppDatabase database) => database.transaction(() async {
  await database.delete(database.marks).go();
  await database.delete(database.exams).go();
  await database.delete(database.attendanceSessions).go();
  await database.delete(database.dailyAttendanceRecords).go();
  await database.delete(database.scheduledClassAttendance).go();
  await database.delete(database.calendarDayOverrides).go();
  await database.delete(database.academicCalendarEvents).go();
  await database.delete(database.timetableEntries).go();
  await database.delete(database.collegeTasks).go();
  await database.delete(database.subjects).go();
  await database.delete(database.semesters).go();
  await database.delete(database.appSettings).go();
  await database
      .into(database.appSettings)
      .insert(const AppSettingsCompanion());
});

Uint8List _replaceJson(Uint8List source, String name, Object json) {
  final archive = ZipDecoder().decodeBytes(source, verify: true);
  archive.add(ArchiveFile.string(name, jsonEncode(json)));
  return ZipEncoder().encodeBytes(archive);
}

Uint8List _replaceDataAndHash(
  Uint8List source,
  Map<String, dynamic> data, {
  int? databaseSchemaVersion,
}) {
  final archive = ZipDecoder().decodeBytes(source, verify: true);
  final dataBytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  final manifest =
      jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
          as Map<String, dynamic>;
  manifest['dataBytes'] = dataBytes.length;
  manifest['dataSha256'] = sha256.convert(dataBytes).toString();
  if (databaseSchemaVersion != null) {
    manifest['databaseSchemaVersion'] = databaseSchemaVersion;
  }
  archive.add(ArchiveFile.bytes('data.json', dataBytes));
  archive.add(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
  return ZipEncoder().encodeBytes(archive);
}
