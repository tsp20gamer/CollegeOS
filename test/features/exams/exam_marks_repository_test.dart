import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/exams/data/drift_exam_repository.dart';
import 'package:college_os/features/marks/data/drift_marks_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftExamRepository exams;
  late DriftMarksRepository marks;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    exams = DriftExamRepository(database.examsDao);
    marks = DriftMarksRepository(database.marksDao);
    semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
      ),
    );
    subjectId = await database.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semesterId,
        name: 'Algorithms',
        displayColor: 0xFF2563EB,
      ),
    );
  });

  tearDown(() => database.close());

  test('persists complete exam CRUD and validates marks', () async {
    final id = await exams.create((
      semesterId: semesterId,
      subjectId: subjectId,
      name: ' Midterm ',
      examType: ' Written ',
      examDate: DateTime(2026, 9, 1, 22),
      startTime: 9 * 60,
      endTime: 11 * 60,
      room: ' Hall A ',
      syllabus: ' Units 1–3 ',
      maxMarks: 100,
      obtainedMarks: 82,
      reminderAt: DateTime.utc(2026, 9, 1, 3, 30),
    ));
    var exam = (await exams.watchForSemester(semesterId).first).single;
    expect(exam.id, id);
    expect(exam.name, 'Midterm');
    expect(exam.examDate, DateTime(2026, 9, 1));
    expect(exam.room, 'Hall A');
    expect(exam.obtainedMarks, 82);
    expect(exam.reminderAt, DateTime.utc(2026, 9, 1, 3, 30));
    expect(await exams.getAllWithReminders(), hasLength(1));

    await exams.update((
      id: exam.id,
      semesterId: exam.semesterId,
      subjectId: exam.subjectId,
      name: 'Final Midterm',
      examType: exam.examType,
      examDate: exam.examDate,
      startTime: exam.startTime,
      endTime: exam.endTime,
      room: exam.room,
      syllabus: exam.syllabus,
      maxMarks: exam.maxMarks,
      obtainedMarks: 88,
      reminderAt: exam.reminderAt,
      createdAt: exam.createdAt,
      updatedAt: exam.updatedAt,
    ));
    exam = (await exams.watchForSemester(semesterId).first).single;
    expect(exam.name, 'Final Midterm');
    expect(exam.obtainedMarks, 88);

    expect(
      () => exams.create((
        semesterId: semesterId,
        subjectId: subjectId,
        name: 'Invalid',
        examType: 'Written',
        examDate: DateTime(2026, 9, 2),
        startTime: 600,
        endTime: 500,
        room: '',
        syllabus: '',
        maxMarks: 50,
        obtainedMarks: 60,
        reminderAt: null,
      )),
      throwsA(anything),
    );

    await exams.delete(id);
    expect(await exams.watchForSemester(semesterId).first, isEmpty);
  });

  test('persists mark CRUD and semester-wide reactive query', () async {
    final id = await marks.create((
      subjectId: subjectId,
      examId: null,
      category: 'internal',
      obtainedMarks: 18,
      maxMarks: 20,
      date: DateTime(2026, 8, 12),
      note: ' Good ',
    ));
    var mark = (await marks.watchForSemester(semesterId).first).single;
    expect(mark.id, id);
    expect(mark.note, 'Good');

    await marks.update((
      id: mark.id,
      subjectId: mark.subjectId,
      examId: mark.examId,
      category: 'lab',
      obtainedMarks: 19,
      maxMarks: 20,
      date: mark.date,
      note: 'Improved',
    ));
    mark = (await marks.watchForSubject(subjectId).first).single;
    expect(mark.category, 'lab');
    expect(mark.obtainedMarks, 19);

    expect(
      () => marks.create((
        subjectId: subjectId,
        examId: null,
        category: 'assignment',
        obtainedMarks: 21,
        maxMarks: 20,
        date: DateTime(2026, 8, 13),
        note: '',
      )),
      throwsA(anything),
    );

    await marks.delete(id);
    expect(await marks.watchForSubject(subjectId).first, isEmpty);
  });

  test('deleting an exam cascades only marks linked to that exam', () async {
    final examId = await exams.create((
      semesterId: semesterId,
      subjectId: subjectId,
      name: 'Final',
      examType: 'Written',
      examDate: DateTime(2026, 10, 1),
      startTime: null,
      endTime: null,
      room: '',
      syllabus: '',
      maxMarks: 100,
      obtainedMarks: null,
      reminderAt: null,
    ));
    await marks.create((
      subjectId: subjectId,
      examId: examId,
      category: 'semester_exam',
      obtainedMarks: 80,
      maxMarks: 100,
      date: DateTime(2026, 10, 2),
      note: '',
    ));
    await exams.delete(examId);
    expect(await marks.watchForSubject(subjectId).first, isEmpty);
  });
}
