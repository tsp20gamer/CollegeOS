import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/attendance/data/drift_attendance_engine_repository.dart';
import 'package:college_os/features/attendance/domain/attendance_engine_repository.dart';
import 'package:college_os/features/exams/data/drift_exam_repository.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/marks/data/drift_marks_repository.dart';
import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:college_os/features/notes/data/drift_subject_note_repository.dart';
import 'package:college_os/features/notes/domain/subject_note_repository.dart';
import 'package:college_os/features/subject_files/data/drift_subject_file_repository.dart';
import 'package:college_os/features/subject_files/domain/subject_file_repository.dart';
import 'package:college_os/features/subject_files/domain/subject_file_storage_service.dart';
import 'package:college_os/features/semesters/data/drift_semester_repository.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/data/drift_settings_repository.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/tasks/data/drift_task_repository.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:college_os/features/timetable/data/drift_timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final semesterRepositoryProvider = Provider<SemesterRepository>(
  (ref) => DriftSemesterRepository(ref.watch(appDatabaseProvider).semestersDao),
);

final subjectRepositoryProvider = Provider<SubjectRepository>(
  (ref) => DriftSubjectRepository(ref.watch(appDatabaseProvider).subjectsDao),
);

final timetableRepositoryProvider = Provider<TimetableRepository>(
  (ref) =>
      DriftTimetableRepository(ref.watch(appDatabaseProvider).timetableDao),
);

final attendanceEngineRepositoryProvider = Provider<AttendanceEngineRepository>(
  (ref) => DriftAttendanceEngineRepository(
    ref.watch(appDatabaseProvider).attendanceEngineDao,
  ),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => DriftTaskRepository(ref.watch(appDatabaseProvider).tasksDao),
);

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => DriftExamRepository(ref.watch(appDatabaseProvider).examsDao),
);

final marksRepositoryProvider = Provider<MarksRepository>(
  (ref) => DriftMarksRepository(ref.watch(appDatabaseProvider).marksDao),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider).settingsDao),
);

final subjectNoteRepositoryProvider = Provider<SubjectNoteRepository>(
  (ref) =>
      DriftSubjectNoteRepository(ref.watch(appDatabaseProvider).subjectNotesDao),
);

final subjectFileStorageServiceProvider = Provider<SubjectFileStorageService>(
  (ref) => const LocalSubjectFileStorageService(),
);

final subjectFileRepositoryProvider = Provider<SubjectFileRepository>(
  (ref) => DriftSubjectFileRepository(
    ref.watch(appDatabaseProvider).subjectFilesDao,
    ref.watch(subjectFileStorageServiceProvider),
  ),
);


