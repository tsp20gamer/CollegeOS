import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:drift/drift.dart';

part 'semesters_dao.g.dart';

@DriftAccessor(tables: [Semesters])
class SemestersDao extends DatabaseAccessor<AppDatabase>
    with _$SemestersDaoMixin {
  SemestersDao(super.attachedDatabase);

  Stream<List<SemesterRow>> watchAll() {
    final query = select(semesters)
      ..orderBy([
        (row) => OrderingTerm.desc(row.isActive),
        (row) => OrderingTerm.desc(row.startDate),
      ]);
    return query.watch();
  }

  Future<SemesterRow?> findById(int id) =>
      (select(semesters)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<SemesterRow?> findActive() => (select(
    semesters,
  )..where((row) => row.isActive.equals(true))).getSingleOrNull();

  Future<int> insertSemester(SemestersCompanion semester) =>
      into(semesters).insert(semester);

  Future<bool> updateSemester(SemestersCompanion semester) =>
      update(semesters).replace(semester);

  Future<void> setActive(int semesterId) => transaction(() async {
    final exists = await findById(semesterId);
    if (exists == null) {
      throw StateError('Semester $semesterId does not exist.');
    }
    await (update(semesters)..where((row) => row.isActive.equals(true))).write(
      const SemestersCompanion(isActive: Value(false)),
    );
    await (update(semesters)..where((row) => row.id.equals(semesterId))).write(
      SemestersCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });

  Future<int> deleteById(int id) =>
      (delete(semesters)..where((row) => row.id.equals(id))).go();
}
