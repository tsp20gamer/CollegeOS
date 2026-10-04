import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/subject_files_dao.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/domain/subject_file_repository.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:drift/drift.dart';

final class DriftSubjectFileRepository implements SubjectFileRepository {
  DriftSubjectFileRepository(this._dao, this._storageService);

  final SubjectFilesDao _dao;
  final SubjectFileStorageService _storageService;

  @override
  Stream<List<SubjectFile>> watchBySubject(int subjectId) => _dao
      .watchBySubject(subjectId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Stream<List<SubjectFile>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<int> create(NewSubjectFile file) => _dao.insertFile(
    SubjectFilesCompanion.insert(
      subjectId: file.subjectId,
      semesterId: file.semesterId,
      title: Value(file.title.trim()),
      fileName: file.fileName.trim(),
      fileExtension: file.fileExtension.toLowerCase().trim(),
      fileSizeBytes: file.fileSizeBytes,
      mimeType: Value(file.mimeType.trim()),
      relativeFilePath: file.relativeFilePath.trim(),
    ),
  );

  @override
  Future<void> delete(int id) async {
    final existing = await _dao.getById(id);
    if (existing != null) {
      await _storageService.deleteFile(existing.relativeFilePath);
    }
    await _dao.deleteById(id);
  }

  @override
  Future<SubjectFile?> getById(int id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _map(row);
  }

  SubjectFile _map(SubjectFileRow row) => (
    id: row.id,
    subjectId: row.subjectId,
    semesterId: row.semesterId,
    title: row.title.isEmpty ? row.fileName : row.title,
    fileName: row.fileName,
    fileExtension: row.fileExtension,
    fileSizeBytes: row.fileSizeBytes,
    mimeType: row.mimeType,
    relativeFilePath: row.relativeFilePath,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
