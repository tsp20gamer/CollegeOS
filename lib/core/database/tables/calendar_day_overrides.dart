import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/tables/semesters.dart';
import 'package:drift/drift.dart';

@DataClassName('CalendarDayOverrideRow')
@TableIndex(
  name: 'calendar_override_semester_date',
  columns: {#semesterId, #date},
  unique: true,
)
class CalendarDayOverrides extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId =>
      integer().references(Semesters, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer().map(const EpochDayConverter())();
  TextColumn get type => textEnum<CalendarDayOverrideType>()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('normal', 'holiday', 'collegeClosed'))",
  ];
}
