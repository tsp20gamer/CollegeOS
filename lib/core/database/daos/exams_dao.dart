import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/exams.dart';
import 'package:drift/drift.dart';

part 'exams_dao.g.dart';

@DriftAccessor(tables: [Exams])
class ExamsDao extends DatabaseAccessor<AppDatabase> with _$ExamsDaoMixin {
  ExamsDao(super.attachedDatabase);

  Stream<List<ExamRow>> watchForSemester(int semesterId) {
    final query = select(exams)
      ..where((row) => row.semesterId.equals(semesterId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.examDate),
        (row) => OrderingTerm.asc(row.startTime),
      ]);
    return query.watch();
  }

  Future<int> insertExam(ExamsCompanion exam) => into(exams).insert(exam);

  Future<bool> updateExam(ExamsCompanion exam) => update(exams).replace(exam);

  Future<List<ExamRow>> getAllWithReminders() =>
      (select(exams)..where((row) => row.reminderAt.isNotNull())).get();

  Future<int> deleteById(int id) =>
      (delete(exams)..where((row) => row.id.equals(id))).go();
}
