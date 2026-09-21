import 'package:college_os/core/database/converters/date_time_converters.dart';
// Used by Drift when validating the composite foreign-key SQL below.
// ignore: unused_import
import 'package:college_os/core/database/tables/exams.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('MarkRow')
@TableIndex(name: 'marks_subject_date', columns: {#subjectId, #date})
@TableIndex(name: 'marks_exam', columns: {#examId})
class Marks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get examId => integer().nullable()();
  TextColumn get category => text()();
  RealColumn get obtainedMarks => real()();
  RealColumn get maxMarks => real()();
  IntColumn get date => integer().map(const EpochDayConverter())();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (exam_id, subject_id) '
        'REFERENCES exams (id, subject_id) ON DELETE CASCADE',
    'CHECK (length(trim(category)) > 0)',
    'CHECK (max_marks > 0)',
    'CHECK (obtained_marks >= 0 AND obtained_marks <= max_marks)',
  ];
}
