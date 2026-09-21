import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:drift/drift.dart';

@DataClassName('SemesterRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX semesters_one_active '
  'ON semesters (is_active) WHERE is_active = 1',
)
@TableIndex(
  name: 'semesters_academic_year_number',
  columns: {#academicYear, #semesterNumber},
)
class Semesters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get semesterNumber => integer()();
  TextColumn get academicYear => text()();
  IntColumn get startDate => integer().map(const EpochDayConverter())();
  IntColumn get endDate => integer().map(const EpochDayConverter())();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(name)) > 0)',
    'CHECK (semester_number > 0)',
    'CHECK (length(trim(academic_year)) > 0)',
    'CHECK (end_date >= start_date)',
  ];
}
