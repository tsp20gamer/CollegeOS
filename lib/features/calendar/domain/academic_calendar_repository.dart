import 'package:college_os/core/database/database_enums.dart';

typedef AcademicCalendarEvent = ({
  int id,
  int semesterId,
  String title,
  AcademicCalendarEventType type,
  DateTime startDate,
  DateTime endDate,
  String note,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewAcademicCalendarEvent = ({
  int semesterId,
  String title,
  AcademicCalendarEventType type,
  DateTime startDate,
  DateTime endDate,
  String note,
});

abstract interface class AcademicCalendarRepository {
  Stream<List<AcademicCalendarEvent>> watchForSemester(int semesterId);
  Future<List<AcademicCalendarEvent>> loadForSemester(int semesterId);
  Future<int> create(NewAcademicCalendarEvent event);
  Future<void> update(AcademicCalendarEvent event);
  Future<void> delete(int id);
}
