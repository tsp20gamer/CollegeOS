import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:drift/drift.dart';

@DataClassName('SubjectRow')
@TableIndex(
  name: 'subjects_semester_archived_name',
  columns: {#semesterId, #isArchived, #name},
)
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get shortCode => text().withDefault(const Constant(''))();
  TextColumn get professor => text().withDefault(const Constant(''))();
  TextColumn get room => text().withDefault(const Constant(''))();
  RealColumn get attendanceTarget => real().withDefault(const Constant(0.75))();
  IntColumn get displayColor => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'UNIQUE (id, semester_id)',
    'CHECK (length(trim(name)) > 0)',
    'CHECK (attendance_target > 0 AND attendance_target <= 1)',
    'CHECK (display_color >= 0 AND display_color <= 4294967295)',
  ];
}
