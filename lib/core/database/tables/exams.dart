import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/semesters.dart';
// Used by Drift when validating the composite foreign-key SQL below.
// ignore: unused_import
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('ExamRow')
@TableIndex(
  name: 'exams_semester_date_start',
  columns: {#semesterId, #examDate, #startTime},
)
@TableIndex(name: 'exams_subject_date', columns: {#subjectId, #examDate})
class Exams extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get subjectId => integer()();
  TextColumn get name => text()();
  TextColumn get examType => text()();
  IntColumn get examDate => integer().map(const EpochDayConverter())();
  IntColumn get startTime => integer().nullable()();
  IntColumn get endTime => integer().nullable()();
  TextColumn get room => text().withDefault(const Constant(''))();
  TextColumn get syllabus => text().withDefault(const Constant(''))();
  RealColumn get maxMarks => real().nullable()();
  RealColumn get obtainedMarks => real().nullable()();
  IntColumn get reminderAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'UNIQUE (id, subject_id)',
    'FOREIGN KEY (subject_id, semester_id) '
        'REFERENCES subjects (id, semester_id) ON DELETE CASCADE',
    'CHECK (length(trim(name)) > 0)',
    'CHECK (length(trim(exam_type)) > 0)',
    'CHECK (start_time IS NULL OR start_time BETWEEN 0 AND 1439)',
    'CHECK (end_time IS NULL OR end_time BETWEEN 1 AND 1440)',
    'CHECK (start_time IS NULL OR end_time IS NULL OR end_time > start_time)',
    'CHECK (max_marks IS NULL OR max_marks > 0)',
    'CHECK (obtained_marks IS NULL OR obtained_marks >= 0)',
    'CHECK (obtained_marks IS NULL OR max_marks IS NULL OR '
        'obtained_marks <= max_marks)',
  ];
}
