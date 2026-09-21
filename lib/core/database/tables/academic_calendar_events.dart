import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:drift/drift.dart';

@DataClassName('AcademicCalendarEventRow')
@TableIndex(
  name: 'academic_calendar_semester_dates',
  columns: {#semesterId, #startDate, #endDate},
)
class AcademicCalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get type => textEnum<AcademicCalendarEventType>()();
  IntColumn get startDate => integer().map(const EpochDayConverter())();
  IntColumn get endDate => integer().map(const EpochDayConverter())();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'CHECK (length(trim(title)) > 0)',
    "CHECK (type IN ('event', 'examPeriod', 'holiday', 'collegeClosed'))",
    'CHECK (end_date >= start_date)',
  ];
}
