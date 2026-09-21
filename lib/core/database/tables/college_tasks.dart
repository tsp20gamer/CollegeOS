import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/tables/semesters.dart';
// Used by Drift when validating the composite foreign-key SQL below.
// ignore: unused_import
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('TaskRow')
@TableIndex(
  name: 'tasks_semester_completed_due',
  columns: {#semesterId, #isCompleted, #dueDate},
)
@TableIndex(
  name: 'tasks_subject_completed',
  columns: {#subjectId, #isCompleted},
)
class CollegeTasks extends Table {
  @override
  String get tableName => 'tasks';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get subjectId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get type => textEnum<CollegeTaskType>()();
  TextColumn get priority => textEnum<TaskPriority>()();
  IntColumn get dueDate =>
      integer().map(const EpochDayConverter()).nullable()();
  IntColumn get dueTime => integer().nullable()();
  IntColumn get reminderAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get completedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (subject_id, semester_id) '
        'REFERENCES subjects (id, semester_id) ON DELETE CASCADE',
    'CHECK (length(trim(title)) > 0)',
    "CHECK (type IN ('general', 'assignment', 'study'))",
    "CHECK (priority IN ('low', 'medium', 'high'))",
    'CHECK (due_time IS NULL OR due_time BETWEEN 0 AND 1439)',
    'CHECK (due_time IS NULL OR due_date IS NOT NULL)',
    'CHECK ((is_completed = 0 AND completed_at IS NULL) OR '
        '(is_completed = 1 AND completed_at IS NOT NULL))',
  ];
}
