import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:drift/drift.dart';

final class DriftTimetableImportCommitter implements TimetableImportCommitter {
  const DriftTimetableImportCommitter(this._database);

  final AppDatabase _database;

  @override
  Future<TimetableImportResult> commit({
    required int semesterId,
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required double defaultAttendanceTarget,
    required TimetableImportPreview preview,
  }) => _database.transaction(() async {
    if (defaultAttendanceTarget <= 0 || defaultAttendanceTarget > 1) {
      throw ArgumentError.value(
        defaultAttendanceTarget,
        'defaultAttendanceTarget',
      );
    }
    final semester = await (_database.select(
      _database.semesters,
    )..where((row) => row.id.equals(semesterId))).getSingleOrNull();
    if (semester == null || !semester.isActive) {
      throw StateError(
        'The active semester changed before the import finished.',
      );
    }
    final existingSubjects = await (_database.select(
      _database.subjects,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final byId = {for (final subject in existingSubjects) subject.id: subject};
    final existingEntries = await (_database.select(
      _database.timetableEntries,
    )..where((row) => row.semesterId.equals(semesterId))).get();
    final occupiedSlots = <String>{
      for (final entry in existingEntries)
        '${entry.subjectId}:${entry.weekday}:${entry.startTime}:${entry.endTime}',
    };
    final createdSubjectIds = <String, int>{};
    var subjectsCreated = 0;
    var entriesCreated = 0;
    var additionalDuplicates = 0;

    for (final candidate in preview.candidates.where((row) => row.willImport)) {
      final row = candidate.row;
      var subjectId = candidate.matchedSubjectId;
      if (subjectId != null && !byId.containsKey(subjectId)) {
        throw StateError(
          'A matched subject no longer exists. Import was cancelled.',
        );
      }
      if (subjectId == null) {
        final key = _subjectKey(row);
        subjectId = createdSubjectIds[key];
        if (subjectId == null) {
          final now = DateTime.now().toUtc();
          subjectId = await _database
              .into(_database.subjects)
              .insert(
                SubjectsCompanion.insert(
                  semesterId: semesterId,
                  name: row.subjectName.trim(),
                  shortCode: Value(row.shortCode.trim()),
                  professor: Value(row.professor.trim()),
                  room: Value(row.room.trim()),
                  attendanceTarget: Value(defaultAttendanceTarget),
                  displayColor: _subjectColor(key),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
          createdSubjectIds[key] = subjectId;
          subjectsCreated++;
        }
      }
      final slot = '$subjectId:${row.weekday}:${row.startTime}:${row.endTime}';
      if (!occupiedSlots.add(slot)) {
        additionalDuplicates++;
        continue;
      }
      await _database
          .into(_database.timetableEntries)
          .insert(
            TimetableEntriesCompanion.insert(
              semesterId: semesterId,
              subjectId: subjectId,
              weekday: row.weekday,
              startTime: row.startTime,
              endTime: row.endTime,
              room: Value(row.room.trim()),
              note: Value(row.note.trim()),
              effectiveFrom: Value(semesterStart),
              effectiveUntil: Value(semesterEnd),
            ),
          );
      entriesCreated++;
    }
    return TimetableImportResult(
      entriesCreated: entriesCreated,
      subjectsCreated: subjectsCreated,
      duplicatesSkipped: preview.duplicateCount + additionalDuplicates,
    );
  });
}

String _subjectKey(TimetableImportRow row) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return row.shortCode.trim().isNotEmpty
      ? 'code:${normalize(row.shortCode)}'
      : 'name:${normalize(row.subjectName)}';
}

int _subjectColor(String key) {
  const colors = <int>[
    0xFF7367F0,
    0xFF4F8CFF,
    0xFF00A6A6,
    0xFF2E9B63,
    0xFFB7791F,
    0xFFBE4B78,
    0xFF7950C7,
  ];
  return colors[key.hashCode.abs() % colors.length];
}
