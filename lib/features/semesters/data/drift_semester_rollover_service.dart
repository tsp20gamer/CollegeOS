import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/semesters/domain/semester_rollover.dart';
import 'package:drift/drift.dart';

final class DriftSemesterRolloverService implements SemesterRolloverService {
  const DriftSemesterRolloverService(this._database);

  final AppDatabase _database;

  @override
  Future<SemesterRolloverResult> rollover(SemesterRolloverRequest request) =>
      _database.transaction(() async {
        _validate(request);
        final source =
            await (_database.select(_database.semesters)
                  ..where((row) => row.id.equals(request.sourceSemesterId)))
                .getSingleOrNull();
        if (source == null || !source.isActive) {
          throw StateError('The source semester is no longer active.');
        }

        final now = DateTime.now().toUtc();
        await (_database.update(
          _database.semesters,
        )..where((row) => row.isActive.equals(true))).write(
          SemestersCompanion(
            isActive: const Value(false),
            updatedAt: Value(now),
          ),
        );
        final semesterId = await _database
            .into(_database.semesters)
            .insert(
              SemestersCompanion.insert(
                name: 'Semester ${request.semesterNumber}',
                semesterNumber: request.semesterNumber,
                academicYear: request.academicYear.trim(),
                startDate: request.semesterStartDate,
                endDate: request.semesterEndDate,
                isActive: const Value(true),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        await _database
            .update(_database.appSettings)
            .write(
              AppSettingsCompanion(
                academicYearStartDate: Value(request.academicYearStartDate),
                academicYearEndDate: Value(request.academicYearEndDate),
              ),
            );

        var subjectsCopied = 0;
        var timetableCopied = 0;
        if (request.copySubjects) {
          final oldSubjects =
              await (_database.select(_database.subjects)
                    ..where(
                      (row) =>
                          row.semesterId.equals(source.id) &
                          row.isArchived.equals(false),
                    )
                    ..orderBy([(row) => OrderingTerm.asc(row.id)]))
                  .get();
          final subjectIds = <int, int>{};
          for (final subject in oldSubjects) {
            final newId = await _database
                .into(_database.subjects)
                .insert(
                  SubjectsCompanion.insert(
                    semesterId: semesterId,
                    name: subject.name,
                    shortCode: Value(subject.shortCode),
                    professor: Value(subject.professor),
                    room: Value(subject.room),
                    attendanceTarget: Value(subject.attendanceTarget),
                    displayColor: subject.displayColor,
                    isArchived: const Value(false),
                    createdAt: Value(now),
                    updatedAt: Value(now),
                  ),
                );
            subjectIds[subject.id] = newId;
            subjectsCopied++;
          }

          if (request.copyTimetable) {
            final oldEntries =
                await (_database.select(_database.timetableEntries)
                      ..where((row) => row.semesterId.equals(source.id))
                      ..orderBy([(row) => OrderingTerm.asc(row.id)]))
                    .get();
            for (final entry in oldEntries) {
              final newSubjectId = subjectIds[entry.subjectId];
              if (newSubjectId == null) continue;
              await _database
                  .into(_database.timetableEntries)
                  .insert(
                    TimetableEntriesCompanion.insert(
                      semesterId: semesterId,
                      subjectId: newSubjectId,
                      weekday: entry.weekday,
                      startTime: entry.startTime,
                      endTime: entry.endTime,
                      room: Value(entry.room),
                      note: Value(entry.note),
                      effectiveFrom: Value(request.semesterStartDate),
                      effectiveUntil: Value(request.semesterEndDate),
                    ),
                  );
              timetableCopied++;
            }
          }
        }

        return SemesterRolloverResult(
          semesterId: semesterId,
          subjectsCopied: subjectsCopied,
          timetableEntriesCopied: timetableCopied,
        );
      });

  void _validate(SemesterRolloverRequest request) {
    if (request.semesterNumber <= 0 || request.academicYear.trim().isEmpty) {
      throw ArgumentError('Semester number and academic year are required.');
    }
    if (!request.academicYearStartDate.isBefore(request.academicYearEndDate)) {
      throw ArgumentError('Academic year end must be after its start.');
    }
    if (request.semesterStartDate.isBefore(request.academicYearStartDate) ||
        request.semesterEndDate.isAfter(request.academicYearEndDate) ||
        !request.semesterStartDate.isBefore(request.semesterEndDate)) {
      throw ArgumentError('Semester dates must fit inside the academic year.');
    }
    if (request.copyTimetable && !request.copySubjects) {
      throw ArgumentError('A timetable cannot be copied without subjects.');
    }
  }
}
