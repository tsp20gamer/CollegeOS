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
const _lectureHall = 'AP-214';
const _fileName = 'CollegeOS_MREC_CSE_AIML_III_I_Section_C.collegeos';

final _createdAt = DateTime.utc(2026, 8, 15, 12);
final _academicYearStart = DateTime(2026, 6, 17);
final _academicYearEnd = DateTime(2027, 5, 31);
final _semesterStart = DateTime(2026, 6, 17);
final _semesterEnd = DateTime(2026, 12, 31);

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
    name: 'Design and Analysis of Algorithms',
    code: 'DAA',
    professor: 'Mr. E. Babu',
    room: _lectureHall,
    color: 0xFF6750A4,
  ),
  _SubjectSpec(
    id: 2,
    name: 'Machine Learning',
    code: 'ML',
    professor: 'Mrs. SK. Farzana',
    room: _lectureHall,
    color: 0xFF006A6A,
  ),
  _SubjectSpec(
    id: 3,
    name: 'Computer Networks',
    code: 'CN',
    professor: 'Mrs. V. Anusha',
    room: _lectureHall,
    color: 0xFF8C4A60,
  ),
  _SubjectSpec(
    id: 4,
    name: 'Business Economics & Financial Analysis',
    code: 'BEFA',
    professor: 'Mr. A. Sanjay',
    room: _lectureHall,
    color: 0xFF3F5F90,
  ),
  _SubjectSpec(
    id: 5,
    name: 'Web Programming',
    code: 'WP',
    professor: 'Mr. N. Vinod Kumar',
    room: _lectureHall,
    color: 0xFF386A20,
  ),
  _SubjectSpec(
    id: 6,
    name: 'Machine Learning Lab',
    code: 'ML LAB',
    professor: 'Mrs. SK. Farzana',
    room: '',
    color: 0xFF006874,
  ),
  _SubjectSpec(
    id: 7,
    name: 'Computer Networks Lab',
    code: 'CN LAB',
    professor: 'Mrs. V. Anusha',
    room: '',
    color: 0xFF4E6355,
  ),
  _SubjectSpec(
    id: 8,
    name: 'Advanced English Communication Skills Lab',
    code: 'AECS LAB',
    professor: 'Dr. Sumathi S',
    room: '',
    color: 0xFF7D5260,
  ),
  _SubjectSpec(
    id: 9,
    name: 'UI Design - Flutter',
    code: 'UI-FLUTTER LAB',
    professor: 'Mrs. SK. Farzana',
    room: '',
    color: 0xFF735C00,
  ),
  _SubjectSpec(
    id: 10,
    name: 'Intellectual Property Rights',
    code: 'IPR',
    professor: 'Mr. K. Aravind',
    room: _lectureHall,
    color: 0xFF5D5F5F,
  ),
  _SubjectSpec(
    id: 11,
    name: 'Sports',
    code: 'SPORTS',
    professor: '',
    room: '',
    color: 0xFF38656A,
  ),
];

void main() {
  test('generates a validated CSE (AI&ML) Section C import', _generateImport);
}

Future<void> _generateImport() async {
  final output = Directory('imports');
  await output.create(recursive: true);

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  late BackupDataSnapshot snapshot;
  late CollegeOsBackupCodec codec;
  late File file;
  try {
    await _seed(database);
    final store = DriftBackupDatabaseStore(database);
    snapshot = await store.capture();
    codec = CollegeOsBackupCodec();
    final backup = codec.encode(
      data: snapshot,
      appVersion: _appVersion,
      createdAt: _createdAt,
    );
    file = File('${output.path}${Platform.pathSeparator}$_fileName');
    await file.writeAsBytes(backup.bytes!, flush: true);
  } finally {
    await database.close();
  }

  final prepared = await codec.decode(
    bytes: await file.readAsBytes(),
    sourceName: _fileName,
  );
  await _verifyRestore(prepared.data, snapshot.toJson());
  expect(prepared.data.subjects, hasLength(11));
  expect(prepared.data.timetable, hasLength(34));
  stdout.writeln(
    '$_fileName: ${snapshot.subjects.length} subjects, '
    '${snapshot.timetable.length} timetable entries, ${file.lengthSync()} bytes',
  );
}

Future<void> _seed(AppDatabase database) async {
  await database
      .update(database.appSettings)
      .write(
        AppSettingsCompanion(
          collegeName: const Value(
            'Malla Reddy Engineering College and Management Sciences',
          ),
          course: const Value('B.Tech'),
          branch: const Value('CSE (AI&ML) - Section C'),
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
          name: 'B.Tech III Year - I Semester',
          semesterNumber: 5,
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
  await add(DateTime.monday, 4, 570, 620);
  await add(DateTime.monday, 5, 620, 670);
  await add(DateTime.monday, 2, 680, 730);
  await add(DateTime.monday, 3, 730, 780);
  await add(DateTime.monday, 8, 820, 970, note: 'Three-period lab');

  // Tuesday
  await add(DateTime.tuesday, 4, 570, 620);
  await add(DateTime.tuesday, 10, 620, 670);
  await add(DateTime.tuesday, 5, 680, 730);
  await add(DateTime.tuesday, 4, 730, 780);
  await add(DateTime.tuesday, 2, 820, 870);
  await add(DateTime.tuesday, 1, 870, 920);
  await add(DateTime.tuesday, 3, 920, 970);

  // Wednesday
  await add(DateTime.wednesday, 4, 570, 620);
  await add(DateTime.wednesday, 7, 620, 780, note: 'Three-period lab');
  await add(DateTime.wednesday, 10, 820, 870);
  await add(DateTime.wednesday, 2, 870, 920);
  await add(DateTime.wednesday, 1, 920, 970);

  // Thursday
  await add(DateTime.thursday, 2, 570, 620);
  await add(DateTime.thursday, 5, 620, 670);
  await add(DateTime.thursday, 1, 680, 730);
  await add(DateTime.thursday, 4, 730, 780);
  await add(DateTime.thursday, 6, 820, 970, note: 'Three-period lab');

  // Friday
  await add(DateTime.friday, 3, 570, 620);
  await add(DateTime.friday, 5, 620, 670);
  await add(DateTime.friday, 5, 680, 730);
  await add(DateTime.friday, 2, 730, 780);
  await add(DateTime.friday, 10, 820, 870);
  await add(DateTime.friday, 1, 870, 920);
  await add(DateTime.friday, 10, 920, 970);

  // Saturday
  await add(DateTime.saturday, 3, 570, 620);
  await add(DateTime.saturday, 9, 620, 780, note: 'Three-period lab');
  await add(DateTime.saturday, 1, 820, 870);
  await add(DateTime.saturday, 3, 870, 920);
  await add(DateTime.saturday, 11, 920, 970);
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
