import 'package:college_os/features/subject_files/domain/subject_file.dart';

abstract interface class SubjectFileRepository {
  Stream<List<SubjectFile>> watchBySubject(int subjectId);

  /// Every stored file, newest first, for screens that span subjects.
  Stream<List<SubjectFile>> watchAll();
  Future<int> create(NewSubjectFile file);
  Future<void> delete(int id);
  Future<SubjectFile?> getById(int id);
}
