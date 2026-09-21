typedef SubjectFile = ({
  int id,
  int subjectId,
  int semesterId,
  String title,
  String fileName,
  String fileExtension,
  int fileSizeBytes,
  String mimeType,
  String relativeFilePath,
  DateTime createdAt,
  DateTime updatedAt,
});

typedef NewSubjectFile = ({
  int subjectId,
  int semesterId,
  String title,
  String fileName,
  String fileExtension,
  int fileSizeBytes,
  String mimeType,
  String relativeFilePath,
});
