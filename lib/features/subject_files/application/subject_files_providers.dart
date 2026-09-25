import 'dart:typed_data';

import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/notes/application/pdf_search_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subjectFilesProvider =
    StreamProvider.family<List<SubjectFile>, int>((ref, subjectId) {
      return ref.watch(subjectFileRepositoryProvider).watchBySubject(subjectId);
    });

final subjectFileCommandProvider =
    AsyncNotifierProvider<SubjectFileCommandController, void>(
      SubjectFileCommandController.new,
    );

final class SubjectFileCommandController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int?> uploadFile({
    required int subjectId,
    required int semesterId,
    required String title,
    required String fileName,
    required Uint8List bytes,
  }) async {
    state = const AsyncLoading();
    int? createdId;
    state = await AsyncValue.guard(() async {
      final storage = ref.read(subjectFileStorageServiceProvider);
      final saved = await storage.saveFile(
        subjectId: subjectId,
        originalFileName: fileName,
        bytes: bytes,
      );

      final newFile = (
        subjectId: subjectId,
        semesterId: semesterId,
        title: title.trim().isEmpty ? fileName : title.trim(),
        fileName: fileName,
        fileExtension: saved.fileExtension,
        fileSizeBytes: saved.fileSizeBytes,
        mimeType: _guessMimeType(saved.fileExtension),
        relativeFilePath: saved.relativeFilePath,
      );

      createdId = await ref.read(subjectFileRepositoryProvider).create(newFile);
      
      if (createdId != null && saved.fileExtension.toLowerCase() == 'pdf') {
        // Trigger indexing in background without awaiting
        ref.read(pdfIndexCommandProvider.notifier).indexFile(createdId!, saved.relativeFilePath);
      }
    });
    return state.hasError ? null : createdId;
  }

  Future<bool> deleteFile(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(pdfSearchDaoProvider).deleteFileIndex(id);
      await ref.read(subjectFileRepositoryProvider).delete(id);
    });
    return !state.hasError;
  }

  Future<bool> openOrShareFile(SubjectFile file) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(subjectFileStorageServiceProvider)
          .openOrShareFile(file.relativeFilePath, file.title);
    });
    return !state.hasError;
  }

  static String _guessMimeType(String ext) {
    return switch (ext.toLowerCase()) {
      'pdf' => 'application/pdf',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
