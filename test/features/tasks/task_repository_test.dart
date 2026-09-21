import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/features/tasks/data/drift_task_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftTaskRepository repository;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTaskRepository(database.tasksDao);
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

  test(
    'persists all fields and supports edit complete uncomplete delete',
    () async {
      final reminder = DateTime.utc(2026, 8, 19, 8);
      final id = await repository.create((
        semesterId: semesterId,
        subjectId: subjectId,
        title: ' Assignment 1 ',
        description: ' Graph problems ',
        type: CollegeTaskType.assignment,
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 8, 20),
        dueTime: 17 * 60 + 30,
        reminderAt: reminder,
      ));
      var task = (await repository.watchForSemester(semesterId).first).single;
      expect(task.id, id);
      expect(task.title, 'Assignment 1');
      expect(task.description, 'Graph problems');
      expect(task.subjectId, subjectId);
      expect(task.dueTime, 17 * 60 + 30);
      expect(task.reminderAt, reminder);

      await repository.update((
        id: task.id,
        semesterId: task.semesterId,
        subjectId: null,
        title: 'Study graphs',
        description: task.description,
        type: CollegeTaskType.study,
        priority: TaskPriority.medium,
        dueDate: null,
        dueTime: null,
        reminderAt: null,
        isCompleted: task.isCompleted,
        completedAt: task.completedAt,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
      ));
      task = (await repository.watchForSemester(semesterId).first).single;
      expect(task.type, CollegeTaskType.study);
      expect(task.subjectId, isNull);
      expect(task.dueDate, isNull);

      await repository.setCompleted(id, completed: true);
      task = (await repository.watchForSemester(semesterId).first).single;
      expect(task.isCompleted, isTrue);
      expect(task.completedAt, isNotNull);

      await repository.setCompleted(id, completed: false);
      task = (await repository.watchForSemester(semesterId).first).single;
      expect(task.isCompleted, isFalse);
      expect(task.completedAt, isNull);

      await repository.delete(id);
      expect(await repository.watchForSemester(semesterId).first, isEmpty);
    },
  );

  test(
    'rejects due time without due date and cross-semester subject',
    () async {
      expect(
        () => repository.create((
          semesterId: semesterId,
          subjectId: null,
          title: 'Invalid',
          description: '',
          type: CollegeTaskType.general,
          priority: TaskPriority.low,
          dueDate: null,
          dueTime: 600,
          reminderAt: null,
        )),
        throwsA(anything),
      );
      final otherSemester = await database.semestersDao.insertSemester(
        SemestersCompanion.insert(
          name: 'Semester 2',
          semesterNumber: 2,
          academicYear: '2026-2027',
          startDate: DateTime(2027, 1, 1),
          endDate: DateTime(2027, 5, 1),
        ),
      );
      expect(
        () => repository.create((
          semesterId: otherSemester,
          subjectId: subjectId,
          title: 'Wrong semester',
          description: '',
          type: CollegeTaskType.assignment,
          priority: TaskPriority.high,
          dueDate: DateTime(2027, 2, 1),
          dueTime: null,
          reminderAt: null,
        )),
        throwsA(anything),
      );
    },
  );
}
