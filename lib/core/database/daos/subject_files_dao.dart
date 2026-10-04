import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/subject_files.dart';
import 'package:drift/drift.dart';

part 'subject_files_dao.g.dart';

@DriftAccessor(tables: [SubjectFiles])
class SubjectFilesDao extends DatabaseAccessor<AppDatabase>
    with _$SubjectFilesDaoMixin {
  SubjectFilesDao(super.attachedDatabase);

  /// Reactive stream of files for [subjectId], newest first.
  Stream<List<SubjectFileRow>> watchBySubject(int subjectId) {
    return (select(subjectFiles)
          ..where((row) => row.subjectId.equals(subjectId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  /// Reactive stream of every stored file, newest first.
  ///
  /// Used by screens that work across subjects, such as an unscoped note search
  /// that has to resolve a citation to a file without a subject in hand.
  Stream<List<SubjectFileRow>> watchAll() {
    return (select(
      subjectFiles,
    )..orderBy([(row) => OrderingTerm.desc(row.createdAt)])).watch();
  }

  Future<SubjectFileRow?> getById(int id) => (select(
    subjectFiles,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<int> insertFile(SubjectFilesCompanion file) =>
      into(subjectFiles).insert(file);

  Future<int> deleteById(int id) =>
      (delete(subjectFiles)..where((row) => row.id.equals(id))).go();

  Future<List<SubjectFileRow>> getAllForBackup() => (select(
    subjectFiles,
  )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
}
