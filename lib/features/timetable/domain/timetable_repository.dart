typedef TimetableEntry = ({
  int id,
  int semesterId,
  int subjectId,
  int weekday,
  int startTime,
  int endTime,
  String room,
  String note,
});

typedef NewTimetableEntry = ({
  int semesterId,
  int subjectId,
  int weekday,
  int startTime,
  int endTime,
  String room,
  String note,
});

abstract interface class TimetableRepository {
  Stream<List<TimetableEntry>> watchForSemester(
    int semesterId, {
    DateTime? effectiveOn,
  });
  Future<int> create(NewTimetableEntry entry);
  Future<int> createOneDay(NewTimetableEntry entry, DateTime date);
  Future<void> update(TimetableEntry entry, {DateTime? effectiveFrom});
  Future<void> delete(int id, {DateTime? effectiveFrom});
}
