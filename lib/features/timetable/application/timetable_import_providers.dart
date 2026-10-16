import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/data/drift_timetable_importer.dart';
import 'package:college_os/features/timetable/data/timetable_document_readers.dart';
import 'package:college_os/features/timetable/data/timetable_import_file_picker.dart';
import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timetableImportFilePickerProvider = Provider<TimetableImportFilePicker>(
  (_) => const DeviceTimetableImportFilePicker(),
);

final timetableImportDocumentReaderProvider = Provider<TimetableDocumentReader>(
  (_) => const TimetableDocumentReader(),
);

final timetableImportCommitterProvider = Provider<TimetableImportCommitter>(
  (ref) => DriftTimetableImportCommitter(ref.watch(appDatabaseProvider)),
);

final timetableImportControllerProvider =
    AsyncNotifierProvider<TimetableImportController, void>(
      TimetableImportController.new,
    );

final class TimetableImportController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TimetableImportPreview?> chooseFile({
    required List<Subject> subjects,
    required List<TimetableEntry> existingEntries,
  }) async {
    state = const AsyncLoading();
    TimetableImportPreview? preview;
    state = await AsyncValue.guard(() async {
      final file = await ref.read(timetableImportFilePickerProvider).pickFile();
      if (file == null) return;
      // Every format is decoded into rows first, so the preview, the duplicate
      // rules and the commit path are shared rather than per-format copies.
      final rows = ref
          .read(timetableImportDocumentReaderProvider)
          .readRows(fileName: file.name, bytes: file.bytes);
      preview = const TimetableTableParser().parseRows(
        fileName: file.name,
        rows: rows,
        subjects: subjects,
        existingEntries: existingEntries,
      );
    });
    return state.hasError ? null : preview;
  }

  Future<TimetableImportResult?> commit({
    required int semesterId,
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required double defaultAttendanceTarget,
    required TimetableImportPreview preview,
  }) async {
    state = const AsyncLoading();
    TimetableImportResult? result;
    state = await AsyncValue.guard(() async {
      result = await ref
          .read(timetableImportCommitterProvider)
          .commit(
            semesterId: semesterId,
            semesterStart: semesterStart,
            semesterEnd: semesterEnd,
            defaultAttendanceTarget: defaultAttendanceTarget,
            preview: preview,
          );
    });
    return state.hasError ? null : result;
  }
}
