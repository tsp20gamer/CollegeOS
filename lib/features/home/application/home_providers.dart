import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeTasksProvider = StreamProvider<List<CollegeTask>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  return ref
      .watch(taskRepositoryProvider)
      .watchForSemester(semester.id, completed: false);
});

final homeExamsProvider = StreamProvider<List<Exam>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  return ref.watch(examRepositoryProvider).watchForSemester(semester.id);
});
