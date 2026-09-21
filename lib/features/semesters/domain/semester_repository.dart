typedef Semester = ({
  int id,
  String name,
  int semesterNumber,
  String academicYear,
  DateTime startDate,
  DateTime endDate,
  bool isActive,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewSemester = ({
  String name,
  int semesterNumber,
  String academicYear,
  DateTime startDate,
  DateTime endDate,
  bool isActive,
});

abstract interface class SemesterRepository {
  Stream<List<Semester>> watchAll();
  Future<Semester?> findById(int id);
  Future<int> create(NewSemester semester);
  Future<void> update(Semester semester);
  Future<void> setActive(int id);
  Future<void> delete(int id);
}
