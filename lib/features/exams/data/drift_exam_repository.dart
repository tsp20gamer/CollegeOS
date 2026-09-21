import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/exams_dao.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:drift/drift.dart';

final class DriftExamRepository implements ExamRepository {
  DriftExamRepository(this._dao);

  final ExamsDao _dao;

  @override
  Stream<List<Exam>> watchForSemester(int semesterId) => _dao
      .watchForSemester(semesterId)
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<int> create(NewExam exam) => _dao.insertExam(
    ExamsCompanion.insert(
      semesterId: exam.semesterId,
      subjectId: exam.subjectId,
      name: exam.name.trim(),
      examType: exam.examType.trim(),
      examDate: exam.examDate,
      startTime: Value(exam.startTime),
      endTime: Value(exam.endTime),
      room: Value(exam.room.trim()),
      syllabus: Value(exam.syllabus.trim()),
      maxMarks: Value(exam.maxMarks),
      obtainedMarks: Value(exam.obtainedMarks),
      reminderAt: Value(exam.reminderAt),
    ),
  );

  @override
  Future<void> update(Exam exam) async {
    final updated = await _dao.updateExam(
      ExamsCompanion.insert(
        id: Value(exam.id),
        semesterId: exam.semesterId,
        subjectId: exam.subjectId,
        name: exam.name.trim(),
        examType: exam.examType.trim(),
        examDate: exam.examDate,
        startTime: Value(exam.startTime),
        endTime: Value(exam.endTime),
        room: Value(exam.room.trim()),
        syllabus: Value(exam.syllabus.trim()),
        maxMarks: Value(exam.maxMarks),
        obtainedMarks: Value(exam.obtainedMarks),
        reminderAt: Value(exam.reminderAt),
        createdAt: Value(exam.createdAt),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (!updated) throw StateError('Exam ${exam.id} does not exist.');
  }

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);

  Exam _map(ExamRow row) => (
    id: row.id,
    semesterId: row.semesterId,
    subjectId: row.subjectId,
    name: row.name,
    examType: row.examType,
    examDate: row.examDate,
    startTime: row.startTime,
    endTime: row.endTime,
    room: row.room,
    syllabus: row.syllabus,
    maxMarks: row.maxMarks,
    obtainedMarks: row.obtainedMarks,
    reminderAt: row.reminderAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  @override
  Future<List<Exam>> getAllWithReminders() async =>
      (await _dao.getAllWithReminders()).map(_map).toList(growable: false);
}
