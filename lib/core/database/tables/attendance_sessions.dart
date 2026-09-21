import 'package:college_os/core/database/converters/date_time_converters.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/database/tables/subjects.dart';
import 'package:drift/drift.dart';

@DataClassName('AttendanceSessionRow')
@TableIndex(
  name: 'attendance_subject_date_period',
  columns: {#subjectId, #date, #period},
)
@TableIndex(name: 'attendance_subject_status', columns: {#subjectId, #status})
class AttendanceSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId =>
      integer().references(Subjects, #id, onDelete: KeyAction.cascade)();
  IntColumn get date => integer().map(const EpochDayConverter())();
  IntColumn get period => integer()();
  TextColumn get status => textEnum<AttendanceStatus>()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();
  IntColumn get updatedAt => integer()
      .map(const UtcDateTimeConverter())
      .clientDefault(currentUtcMilliseconds)();

  @override
  List<String> get customConstraints => [
    'CHECK (period > 0)',
    "CHECK (status IN ('present', 'absent', 'cancelled'))",
  ];
}
