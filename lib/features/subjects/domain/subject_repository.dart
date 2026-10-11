typedef Subject = ({
  int id,
  int semesterId,
  String name,
  String shortCode,
  String professor,
  String room,
  double attendanceTarget,
  int displayColor,
  bool isArchived,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewSubject = ({
  int semesterId,
  String name,
  String shortCode,
  String professor,
  String room,
  double attendanceTarget,
  int displayColor,
});

abstract interface class SubjectRepository {
  Stream<List<Subject>> watchForSemester(
    int semesterId, {
    bool includeArchived = false,
  });
  Future<Subject?> findById(int id);
  Future<int> create(NewSubject subject);
  Future<void> update(Subject subject);
  Future<void> setArchived(int id, {required bool archived});

  /// Re-targets every subject, in every semester, to [target].
  ///
  /// Changing the default attendance target has to reach the subjects that
  /// already exist: attendance and analytics read each subject's own target.
  Future<void> setAllAttendanceTargets(double target);
}
