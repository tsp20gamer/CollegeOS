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

  /// Every subject in every semester, archived ones included.
  ///
  /// The default attendance target applies to the whole local set, so the
  /// screens that report it have to see the subjects other semesters hold too.
  Stream<List<SubjectRow>> watchAll() =>
      (select(subjects)..orderBy([(row) => OrderingTerm.asc(row.id)])).watch();

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

  /// Applies [target] to every subject in every semester.
  ///
  /// The default attendance target is the goal each attendance readout
  /// compares against, so changing it re-targets the subjects that already
  /// exist rather than only the ones created afterwards. A subject created or
  /// imported before a change keeps its older value until this runs; Settings
  /// names those subjects and offers the student this repair.
  Future<int> setAllAttendanceTargets(double target) => update(subjects).write(
    SubjectsCompanion(
      attendanceTarget: Value(target),
      updatedAt: Value(DateTime.now().toUtc()),
    ),
  );

  Future<int> deleteById(int id) =>
      (delete(subjects)..where((row) => row.id.equals(id))).go();
}
