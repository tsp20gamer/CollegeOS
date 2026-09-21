import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('SubjectNoteRow')
@TableIndex(
  name: 'subject_notes_subject_created',
  columns: {#subjectId, #createdAt},
)
class SubjectNotes extends Table {
  @override
  String get tableName => 'subject_notes';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text()();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    // Ensure the subject belongs to the referenced semester.
    'FOREIGN KEY (subject_id, semester_id) '
        'REFERENCES subjects (id, semester_id) ON DELETE CASCADE',
    'CHECK (length(trim(body)) > 0)',
  ];
}
