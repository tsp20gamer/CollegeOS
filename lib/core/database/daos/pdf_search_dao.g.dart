// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_search_dao.dart';

// ignore_for_file: type=lint
mixin _$PdfSearchDaoMixin on DatabaseAccessor<AppDatabase> {
  $SemestersTable get semesters => attachedDatabase.semesters;
  $SubjectsTable get subjects => attachedDatabase.subjects;
  $SubjectFilesTable get subjectFiles => attachedDatabase.subjectFiles;
  PdfSearchMetadata get pdfSearchMetadata => attachedDatabase.pdfSearchMetadata;
  PdfPageFts get pdfPageFts => attachedDatabase.pdfPageFts;
  PdfSearchDaoManager get managers => PdfSearchDaoManager(this);
}

class PdfSearchDaoManager {
  final _$PdfSearchDaoMixin _db;
  PdfSearchDaoManager(this._db);
  $$SemestersTableTableManager get semesters =>
      $$SemestersTableTableManager(_db.attachedDatabase, _db.semesters);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db.attachedDatabase, _db.subjects);
  $$SubjectFilesTableTableManager get subjectFiles =>
      $$SubjectFilesTableTableManager(_db.attachedDatabase, _db.subjectFiles);
  $PdfSearchMetadataTableManager get pdfSearchMetadata =>
      $PdfSearchMetadataTableManager(
        _db.attachedDatabase,
        _db.pdfSearchMetadata,
      );
  $PdfPageFtsTableManager get pdfPageFts =>
      $PdfPageFtsTableManager(_db.attachedDatabase, _db.pdfPageFts);
}
