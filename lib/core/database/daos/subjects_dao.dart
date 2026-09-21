import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

part 'subjects_dao.g.dart';

@DriftAccessor(tables: [Subjects])
class SubjectsDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(super.attachedDatabase);

  Stream<List<SubjectRow>> watchForSemester(
    int semesterId, {
    bool includeArchived = false,
  }) {
    final query = select(subjects)
      ..where((row) {
        final inSemester = row.semesterId.equals(semesterId);
        return includeArchived
            ? inSemester
            : inSemester & row.isArchived.equals(false);
      })
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.watch();
  }

  Future<SubjectRow?> findById(int id) =>
      (select(subjects)..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<int> insertSubject(SubjectsCompanion subject) =>
      into(subjects).insert(subject);

  Future<bool> updateSubject(SubjectsCompanion subject) =>
      update(subjects).replace(subject);

  Future<int> setArchived(int id, {required bool archived}) =>
      (update(subjects)..where((row) => row.id.equals(id))).write(
        SubjectsCompanion(
          isArchived: Value(archived),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  Future<int> deleteById(int id) =>
      (delete(subjects)..where((row) => row.id.equals(id))).go();
}
