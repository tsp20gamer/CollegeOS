import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/notes/domain/pdf_extraction_service.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/core/database/app_database.dart';

final pdfSearchDaoProvider = Provider<PdfSearchDao>((ref) {
  return ref.watch(appDatabaseProvider).pdfSearchDao;
});

final pdfExtractionServiceProvider = Provider<PdfExtractionService>((ref) {
  return LocalPdfExtractionService(
    ref.watch(pdfSearchDaoProvider),
    ref.watch(subjectFileStorageServiceProvider),
  );
});

final pdfSearchProvider = FutureProvider.family<List<PdfSearchResultRow>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return ref.watch(pdfSearchDaoProvider).search(query);
});

final pdfIndexCommandProvider = AsyncNotifierProvider<PdfIndexCommandController, void>(
  PdfIndexCommandController.new,
);

class PdfIndexCommandController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> indexFile(int fileId, String relativeFilePath) async {
    final service = ref.read(pdfExtractionServiceProvider);
    
    // Fire and forget, don't wait for completion here
    // But we update state if we want to track loading
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await service.indexPdf(fileId, relativeFilePath);
    });
  }

  Future<void> retryIndexing(int fileId, String relativeFilePath) async {
    await indexFile(fileId, relativeFilePath);
  }

  Future<void> indexMissingPdfs(List<SubjectFile> files) async {
    final pdfs = files.where((f) => f.fileExtension.toLowerCase() == 'pdf').toList();
    if (pdfs.isEmpty) return;

    final metadata = await ref.read(pdfSearchDaoProvider).getAllMetadata();
    final indexedFileIds = metadata.map((m) => m.fileId).toSet();

    for (final pdf in pdfs) {
      if (!indexedFileIds.contains(pdf.id)) {
        await indexFile(pdf.id, pdf.relativeFilePath);
      }
    }
  }
}

final pdfSearchMetadataProvider = StreamProvider<List<PdfSearchMetadataData>>((ref) {
  // We can't watch custom selects easily with complex mapping, but drift supports watching tables.
  return ref.watch(pdfSearchDaoProvider).select(ref.watch(appDatabaseProvider).pdfSearchMetadata).watch();
});
