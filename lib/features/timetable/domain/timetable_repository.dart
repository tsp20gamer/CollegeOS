typedef TimetableEntry = ({
  int id,
  int semesterId,
  int subjectId,
  int weekday,
  int startTime,
  int endTime,
  String room,
  String note,

  /// How long before [startTime] this class's reminder fires.
  ///
  /// `null` means the class has no reminder. The lead time applies to every
  /// occurrence of the class, and `0` reminds at the class start.
  int? reminderMinutesBefore,
});

typedef NewTimetableEntry = ({
  int semesterId,
  int subjectId,
  int weekday,
  int startTime,
  int endTime,
  String room,
  String note,
  int? reminderMinutesBefore,
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

  /// Applies one reminder lead time to every class in [semesterId] that is still
  /// current or starts later, returning how many classes were updated.
  ///
  /// This replaces each class's own reminder; it never rewrites the class itself,
  /// so durations, rooms, subjects and effective dates are preserved.
  Future<int> applyReminderToAll(
    int semesterId,
    int minutesBefore, {
    DateTime? effectiveOn,
  });
}
