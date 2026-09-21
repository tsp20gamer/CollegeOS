import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/marks.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

part 'marks_dao.g.dart';

@DriftAccessor(tables: [Marks, Subjects])
class MarksDao extends DatabaseAccessor<AppDatabase> with _$MarksDaoMixin {
  MarksDao(super.attachedDatabase);

  Stream<List<MarkRow>> watchForSubject(int subjectId) {
    final query = select(marks)
      ..where((row) => row.subjectId.equals(subjectId))
      ..orderBy([(row) => OrderingTerm.desc(row.date)]);
    return query.watch();
  }

  Stream<List<MarkRow>> watchForSemester(int semesterId) {
    final query = select(marks).join([
      innerJoin(subjects, subjects.id.equalsExp(marks.subjectId)),
    ])..where(subjects.semesterId.equals(semesterId));
    query.orderBy([
      OrderingTerm.asc(subjects.name),
      OrderingTerm.desc(marks.date),
    ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(marks)).toList(growable: false),
    );
  }

  Future<int> insertMark(MarksCompanion mark) => into(marks).insert(mark);

  Future<bool> updateMark(MarksCompanion mark) => update(marks).replace(mark);

  Future<int> deleteById(int id) =>
      (delete(marks)..where((row) => row.id.equals(id))).go();
}
