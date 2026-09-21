import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('SubjectFileRow')
@TableIndex(
  name: 'subject_files_subject_created',
  columns: {#subjectId, #createdAt},
)
class SubjectFiles extends Table {
  @override
  String get tableName => 'subject_files';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get fileName => text()();
  TextColumn get fileExtension => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text().withDefault(const Constant(''))();
  TextColumn get relativeFilePath => text()();
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
    'CHECK (length(trim(file_name)) > 0)',
    'CHECK (length(trim(relative_file_path)) > 0)',
    'CHECK (file_size_bytes >= 0)',
  ];
}
