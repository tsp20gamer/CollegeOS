import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/subjects_dao.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:drift/drift.dart';

final class DriftSubjectRepository implements SubjectRepository {
  DriftSubjectRepository(this._dao);

  final SubjectsDao _dao;

  @override
  Stream<List<Subject>> watchForSemester(
    int semesterId, {
    bool includeArchived = false,
  }) => _dao
      .watchForSemester(semesterId, includeArchived: includeArchived)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<Subject?> findById(int id) async {
    final row = await _dao.findById(id);
    return row == null ? null : _map(row);
  }

  @override
  Future<int> create(NewSubject subject) => _dao.insertSubject(
    SubjectsCompanion.insert(
      semesterId: subject.semesterId,
      name: subject.name.trim(),
      shortCode: Value(subject.shortCode.trim()),
      professor: Value(subject.professor.trim()),
      room: Value(subject.room.trim()),
      attendanceTarget: Value(subject.attendanceTarget),
      displayColor: subject.displayColor,
    ),
  );

  @override
  Future<void> update(Subject subject) async {
    final updated = await _dao.updateSubject(
      SubjectsCompanion.insert(
        id: Value(subject.id),
        semesterId: subject.semesterId,
        name: subject.name.trim(),
        shortCode: Value(subject.shortCode.trim()),
        professor: Value(subject.professor.trim()),
        room: Value(subject.room.trim()),
        attendanceTarget: Value(subject.attendanceTarget),
        displayColor: subject.displayColor,
        isArchived: Value(subject.isArchived),
        createdAt: Value(subject.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (!updated) throw StateError('Subject ${subject.id} does not exist.');
  }

  @override
  Future<void> setArchived(int id, {required bool archived}) async {
    final changed = await _dao.setArchived(id, archived: archived);
    if (changed == 0) throw StateError('Subject $id does not exist.');
  }

  Subject _map(SubjectRow row) => (
    id: row.id,
    semesterId: row.semesterId,
    name: row.name,
    shortCode: row.shortCode,
    professor: row.professor,
    room: row.room,
    attendanceTarget: row.attendanceTarget,
    displayColor: row.displayColor,
    isArchived: row.isArchived,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
