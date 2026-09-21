import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/features/backup/data/backup_database_store.dart';
import 'package:college_os/features/notes/data/drift_subject_note_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftSubjectNoteRepository repository;
  late int semesterId;
  late int subjectId;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSubjectNoteRepository(database.subjectNotesDao);
    semesterId = await database.semestersDao.insertSemester(
      SemestersCompanion.insert(
        name: 'Semester 1',
        semesterNumber: 1,
        academicYear: '2026-2027',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 12, 20),
      ),
    );
    subjectId = await database.subjectsDao.insertSubject(
      SubjectsCompanion.insert(
        semesterId: semesterId,
        name: 'Data Structures',
        displayColor: 0xFF7367F0,
      ),
    );
  });

  tearDown(() => database.close());

  test('creates, reads, updates, and deletes subject notes', () async {
    final noteId1 = await repository.create((
      subjectId: subjectId,
      semesterId: semesterId,
      title: ' Trees & Graphs ',
      body: ' Study binary search tree properties. ',
    ));

    final noteId2 = await repository.create((
      subjectId: subjectId,
      semesterId: semesterId,
      title: 'Complexity',
      body: 'Big-O notation overview.',
    ));

    var notes = await repository.watchBySubject(subjectId).first;
    expect(notes.length, 2);
    // Newest first
    expect(notes[0].id, noteId2);
    expect(notes[0].title, 'Complexity');
    expect(notes[1].id, noteId1);
    expect(notes[1].title, 'Trees & Graphs');
    expect(notes[1].body, 'Study binary search tree properties.');

    // Update note 1
    await repository.update((
      id: noteId1,
      subjectId: subjectId,
      semesterId: semesterId,
      title: 'BST Notes',
      body: 'Updated BST traversal algorithms.',
      createdAt: notes[1].createdAt,
      updatedAt: notes[1].updatedAt,
    ));

    notes = await repository.watchBySubject(subjectId).first;
    final updated = notes.firstWhere((n) => n.id == noteId1);
    expect(updated.title, 'BST Notes');
    expect(updated.body, 'Updated BST traversal algorithms.');

    // Delete note 2
    await repository.delete(noteId2);
    notes = await repository.watchBySubject(subjectId).first;
    expect(notes.length, 1);
    expect(notes.single.id, noteId1);
  });

  test('backup store captures and restores subject notes cleanly', () async {
    final store = DriftBackupDatabaseStore(database);

    await repository.create((
      subjectId: subjectId,
      semesterId: semesterId,
      title: 'Exam Tips',
      body: 'Focus on dynamic programming.',
    ));

    final snapshot = await store.capture();
    expect(snapshot.notes.length, 1);
    expect(snapshot.counts.notes, 1);
    expect(snapshot.notes.single.title, 'Exam Tips');

    // Create a new in-memory database and restore
    final newDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(newDb.close);
    final newStore = DriftBackupDatabaseStore(newDb);

    await newStore.restore(snapshot);

    final restoredNotes = await DriftSubjectNoteRepository(
      newDb.subjectNotesDao,
    ).watchBySubject(subjectId).first;

    expect(restoredNotes.length, 1);
    expect(restoredNotes.single.title, 'Exam Tips');
    expect(restoredNotes.single.body, 'Focus on dynamic programming.');
    expect(await newDb.passesForeignKeyCheck(), isTrue);
    expect(await newDb.passesIntegrityCheck(), isTrue);
  });
}
