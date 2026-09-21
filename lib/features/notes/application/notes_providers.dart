import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/notes/domain/subject_note_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subjectNotesProvider =
    StreamProvider.family<List<SubjectNote>, int>((ref, subjectId) {
      return ref.watch(subjectNoteRepositoryProvider).watchBySubject(subjectId);
    });

final noteCommandProvider = AsyncNotifierProvider<NoteCommandController, void>(
  NoteCommandController.new,
);

final class NoteCommandController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int?> create(NewSubjectNote note) async {
    state = const AsyncLoading();
    int? createdId;
    state = await AsyncValue.guard(() async {
      createdId = await ref.read(subjectNoteRepositoryProvider).create(note);
    });
    return state.hasError ? null : createdId;
  }

  Future<bool> updateNote(SubjectNote note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subjectNoteRepositoryProvider).update(note),
    );
    return !state.hasError;
  }

  Future<bool> deleteNote(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(subjectNoteRepositoryProvider).delete(id),
    );
    return !state.hasError;
  }
}
