import 'dart:io';

import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/backup/data/backup_data_snapshot.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _appVersion = '1.0.0+1';
const _semesterId = 1;
const _classroom = '2009';

final _createdAt = DateTime.utc(2026, 8, 14, 12);
final _academicYearStart = DateTime(2026, 8, 13);
final _academicYearEnd = DateTime(2027, 4, 30);
final _semesterStart = DateTime(2026, 8, 13);
final _semesterEnd = DateTime(2026, 12, 15);

enum _LabBatch { b1, b2 }

final class _SubjectSpec {
  const _SubjectSpec({
    required this.id,
    required this.name,
    required this.code,
    required this.professor,
    required this.room,
    required this.color,
  });

  final int id;
  final String name;
  final String code;
  final String professor;
  final String room;
  final int color;
}

const _subjects = <_SubjectSpec>[
  _SubjectSpec(
    id: 1,
    name: 'Matrices and Calculus',
    code: 'MC',
    professor: 'Mrs. M. Aruna',
    room: _classroom,
    color: 0xFF6750A4,
  ),
  _SubjectSpec(
    id: 2,
    name: 'Engineering Chemistry',
    code: 'EC',
    professor: 'Dr. A. Rambabu',
    room: _classroom,
    color: 0xFF006A6A,
  ),
  _SubjectSpec(
    id: 3,
    name: 'English for Skill Enhancement',
    code: 'ESE',
    professor: 'Mrs. S. Deepika',
    room: _classroom,
    color: 0xFF8C4A60,
  ),
  _SubjectSpec(
    id: 4,
    name: 'Electronic Devices and Circuits',
    code: 'EDC',
    professor: 'Mrs. M. Anitha',
    room: _classroom,
    color: 0xFF3F5F90,
  ),
  _SubjectSpec(
    id: 5,
    name: 'Programming for Problem Solving',
    code: 'PPS',
    professor: 'Mrs. Sri Lakshmi',
    room: _classroom,
    color: 0xFF386A20,
  ),
  _SubjectSpec(
    id: 6,
    name: 'Engineering Chemistry Lab',
    code: 'EC LAB',
    professor: 'Mr. N. Panduranga Rao, Dr. A. Rambabu',
    room: '',
    color: 0xFF006874,
  ),
  _SubjectSpec(
    id: 7,
    name: 'Programming for Problem Solving Lab',
    code: 'PPS LAB',
    professor: 'Mrs. Sri Lakshmi',
    room: '',
    color: 0xFF4E6355,
  ),
  _SubjectSpec(
    id: 8,
    name: 'English Language and Communication Skills Lab',
    code: 'ELCS LAB',
    professor: 'Mrs. S. Deepika',
    room: '',
    color: 0xFF7D5260,
  ),
  _SubjectSpec(
    id: 9,
    name: 'Engineering Workshop',
    code: 'EWS',
    professor: 'Mr. K. Prabhakar, Mrs. K. Chaitra, P. Manjuaha',
    room: '',
    color: 0xFF735C00,
  ),
  _SubjectSpec(
    id: 10,
    name: 'Library',
    code: 'LIB',
    professor: 'Mrs. P. Bharathi',
    room: 'Library',
    color: 0xFF5D5F5F,
  ),
  _SubjectSpec(
    id: 11,
    name: 'Mentor Mentee Meeting',
    code: 'MMM',
    professor: 'Mrs. M. Aruna, Dr. A. Rambabu',
    room: _classroom,
    color: 0xFF6B5778,
  ),
  _SubjectSpec(
    id: 12,
    name: 'Sports',
    code: 'SPTS',
    professor: 'Mrs. M. Aruna, Dr. A. Rambabu',
    room: '',
    color: 0xFF38656A,
  ),
];

void main() {
  test('generates validated CSE-BATCH-IV B1 and B2 imports', _generateImports);
}

Future<void> _generateImports() async {
  final output = Directory('imports');
  await output.create(recursive: true);

  for (final batch in _LabBatch.values) {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    late BackupDataSnapshot snapshot;
    late CollegeOsBackupCodec codec;
    late File file;
    late String fileName;
    try {
      await _seed(database, batch);
      final store = DriftBackupDatabaseStore(database);
      snapshot = await store.capture();
      codec = CollegeOsBackupCodec();
      final backup = codec.encode(
        data: snapshot,
        appVersion: _appVersion,
        createdAt: DateTime(2026, 8, 14, 18, 30),
      );
      final label = batch.name.toUpperCase();
      fileName = 'CollegeOS_CSE_Batch_IV_${label}_Semester_1.collegeos';
      file = File('${output.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(backup.bytes!, flush: true);
    } finally {
      await database.close();
    }

    final prepared = await codec.decode(
      bytes: await file.readAsBytes(),
      sourceName: fileName,
    );
    await _verifyRestore(prepared.data, snapshot.toJson());
    expect(prepared.data.subjects, hasLength(12));
    expect(prepared.data.timetable, hasLength(34));
    stdout.writeln(
      '$fileName: ${snapshot.subjects.length} subjects, '
      '${snapshot.timetable.length} timetable entries, ${file.lengthSync()} bytes',
    );
  }
}

Future<void> _seed(AppDatabase database, _LabBatch batch) async {
  await database
      .update(database.appSettings)
      .write(
        AppSettingsCompanion(
          collegeName: const Value("St. Martin's Engineering College"),
          course: const Value('B.Tech'),
          branch: Value('CSE-BATCH-IV - ${batch.name.toUpperCase()}'),
          academicYearStartDate: Value(_academicYearStart),
          academicYearEndDate: Value(_academicYearEnd),
          defaultAttendanceTarget: const Value(0.75),
          themeMode: const Value(CollegeThemeMode.system),
          onboardingCompleted: const Value(true),
          notificationsEnabled: const Value(false),
          automaticLocalBackup: const Value(true),
        ),
      );

  await database
      .into(database.semesters)
      .insert(
        SemesterRow(
          id: _semesterId,
          name: 'Semester 1',
          semesterNumber: 1,
          academicYear: '2026-2027',
          startDate: _semesterStart,
          endDate: _semesterEnd,
          isActive: true,
          createdAt: _createdAt,
          updatedAt: _createdAt,
        ),
      );

  for (final subject in _subjects) {
    await database
        .into(database.subjects)
        .insert(
          SubjectRow(
            id: subject.id,
            semesterId: _semesterId,
            name: subject.name,
            shortCode: subject.code,
            professor: subject.professor,
            room: subject.room,
            attendanceTarget: 0.75,
            displayColor: subject.color,
            isArchived: false,
            createdAt: _createdAt,
            updatedAt: _createdAt,
          ),
        );
  }

  var id = 1;
  Future<void> add(
    int weekday,
    int subjectId,
    int startTime,
    int endTime, {
    String note = '',
  }) async {
    final subject = _subjects.singleWhere((item) => item.id == subjectId);
    await database
        .into(database.timetableEntries)
        .insert(
          TimetableEntryRow(
            id: id++,
            semesterId: _semesterId,
            subjectId: subjectId,
            weekday: weekday,
            startTime: startTime,
            endTime: endTime,
            room: subject.room,
            note: note,
            effectiveFrom: _semesterStart,
            effectiveUntil: _semesterEnd,
          ),
        );
  }

  // Monday
  await add(DateTime.monday, 5, 560, 610);
  await add(DateTime.monday, 3, 610, 660);
  await add(DateTime.monday, 5, 660, 710);
  await add(DateTime.monday, 1, 750, 800);
  await add(
    DateTime.monday,
    batch == _LabBatch.b1 ? 6 : 9,
    800,
    950,
    note: batch == _LabBatch.b1 ? 'B1 lab session' : 'B2 workshop session',
  );

  // Tuesday
  await add(
    DateTime.tuesday,
    batch == _LabBatch.b1 ? 7 : 8,
    560,
    710,
    note: 'Three-period ${batch.name.toUpperCase()} lab session',
  );
  await add(DateTime.tuesday, 1, 750, 800);
  await add(DateTime.tuesday, 3, 800, 850);
  await add(DateTime.tuesday, 1, 850, 900, note: 'Tutorial');
  await add(DateTime.tuesday, 3, 900, 950);

  // Wednesday
  await add(DateTime.wednesday, 4, 560, 610);
  await add(DateTime.wednesday, 5, 610, 660);
  await add(DateTime.wednesday, 2, 660, 710);
  await add(DateTime.wednesday, 5, 750, 800, note: 'Tutorial');
  await add(DateTime.wednesday, 10, 800, 850);
  await add(DateTime.wednesday, 2, 850, 900);
  await add(DateTime.wednesday, 4, 900, 950);

  // Thursday
  await add(DateTime.thursday, 2, 560, 610);
  await add(DateTime.thursday, 2, 610, 660);
  await add(DateTime.thursday, 4, 660, 710);
  await add(
    DateTime.thursday,
    batch == _LabBatch.b1 ? 9 : 6,
    750,
    900,
    note: batch == _LabBatch.b1 ? 'B1 workshop session' : 'B2 lab session',
  );
  await add(DateTime.thursday, 11, 900, 950);

  // Friday
  await add(
    DateTime.friday,
    batch == _LabBatch.b1 ? 8 : 7,
    560,
    710,
    note: 'Three-period ${batch.name.toUpperCase()} lab session',
  );
  await add(DateTime.friday, 4, 750, 800);
  await add(DateTime.friday, 1, 800, 850);
  await add(DateTime.friday, 2, 850, 900, note: 'Tutorial');
  await add(DateTime.friday, 1, 900, 950);

  // Saturday
  await add(DateTime.saturday, 9, 560, 610);
  await add(DateTime.saturday, 5, 610, 660);
  await add(DateTime.saturday, 4, 660, 710);
  await add(DateTime.saturday, 3, 750, 800, note: 'Tutorial');
  await add(DateTime.saturday, 2, 800, 850);
  await add(DateTime.saturday, 1, 850, 900);
  await add(DateTime.saturday, 12, 900, 950);
}

Future<void> _verifyRestore(
  BackupDataSnapshot snapshot,
  Map<String, Object> expected,
) async {
  final restored = AppDatabase.forTesting(NativeDatabase.memory());
  try {
    final store = DriftBackupDatabaseStore(restored);
    await store.restore(snapshot);
    final actual = (await store.capture()).toJson();
    if (actual.toString() != expected.toString()) {
      throw StateError('Restored snapshot differs from exported data.');
    }
    if (!await restored.passesIntegrityCheck() ||
        !await restored.passesForeignKeyCheck()) {
      throw StateError('Restored database failed SQLite validation.');
    }
  } finally {
    await restored.close();
  }
}
