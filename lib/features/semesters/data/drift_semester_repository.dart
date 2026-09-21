import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/semesters_dao.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:drift/drift.dart';

final class DriftSemesterRepository implements SemesterRepository {
  DriftSemesterRepository(this._dao);

  final SemestersDao _dao;

  @override
  Stream<List<Semester>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<Semester?> findById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _map(row);
  }

  @override
  Future<int> create(NewSemester semester) => _dao.insertSemester(
    SemestersCompanion.insert(
      name: semester.name.trim(),
      semesterNumber: semester.semesterNumber,
      academicYear: semester.academicYear.trim(),
      startDate: semester.startDate,
      endDate: semester.endDate,
      isActive: Value(semester.isActive),
    ),
  );

  @override
  Future<void> update(Semester semester) async {
    final updated = await _dao.updateSemester(
      SemestersCompanion.insert(
        id: Value(semester.id),
        name: semester.name.trim(),
        semesterNumber: semester.semesterNumber,
        academicYear: semester.academicYear.trim(),
        startDate: semester.startDate,
        endDate: semester.endDate,
        isActive: Value(semester.isActive),
        createdAt: Value(semester.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (!updated) throw StateError('Semester ${semester.id} does not exist.');
  }

  @override
  Future<void> setActive(int id) => _dao.setActive(id);

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  Semester _map(SemesterRow row) => (
    id: row.id,
    name: row.name,
    semesterNumber: row.semesterNumber,
    academicYear: row.academicYear,
    startDate: row.startDate,
    endDate: row.endDate,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
