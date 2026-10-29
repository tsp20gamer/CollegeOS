import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/notes/domain/pdf_extraction_service.dart';
import 'package:college_os/features/notes/domain/pdf_search_result.dart';
import 'package:college_os/features/notes/domain/pdf_indexing_foreground_service.dart';
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

typedef PdfSearchRequest = ({String query, int? subjectId});
typedef PdfMissingPageRequest = ({int fileId, int pageCount});

final pdfPagesWithoutSearchTextProvider =
    FutureProvider.family<List<int>, PdfMissingPageRequest>((ref, request) {
      return ref
          .watch(pdfSearchDaoProvider)
          .pagesWithoutText(request.fileId, request.pageCount);
    });

final pdfSearchProvider =
    FutureProvider.family<List<PdfSearchResult>, PdfSearchRequest>((
      ref,
      request,
    ) async {
      if (request.query.trim().isEmpty) return [];
      return ref
          .watch(pdfSearchDaoProvider)
          .search(request.query, subjectId: request.subjectId);
    });

final pdfIndexCommandProvider =
    AsyncNotifierProvider<PdfIndexCommandController, void>(
      PdfIndexCommandController.new,
    );

class PdfIndexCommandController extends AsyncNotifier<void> {
  static final Set<int> _activeJobs = {};

  @override
  Future<void> build() async {}

  Future<void> indexFile(int fileId, String relativeFilePath) async {
    if (_activeJobs.contains(fileId)) return;

    _activeJobs.add(fileId);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await PdfIndexingForegroundService.startIndexing(
        fileId,
        relativeFilePath,
      );
    });

    _activeJobs.remove(fileId);
  }

  Future<void> retryIndexing(int fileId, String relativeFilePath) async {
    await indexFile(fileId, relativeFilePath);
  }

  Future<void> indexMissingPdfs(List<SubjectFile> files) async {
    final pdfs = files
        .where((f) => f.fileExtension.toLowerCase() == 'pdf')
        .toList();
    if (pdfs.isEmpty) return;

    final metadata = await ref.read(pdfSearchDaoProvider).getAllMetadata();
    final metaMap = {for (final m in metadata) m.fileId: m};

    for (final pdf in pdfs) {
      final meta = metaMap[pdf.id];
      if (meta == null) {
        // Never indexed
        await indexFile(pdf.id, pdf.relativeFilePath);
      } else if (meta.status == 'indexed' ||
          meta.status == 'ocr_error' ||
          meta.status == 'error') {
        // Add OCR to indexes built before scanned-page support, or retry a
        // scanned page whose platform OCR failed previously.
        await indexFile(pdf.id, pdf.relativeFilePath);
      } else if (meta.status.startsWith('indexing') &&
          !_activeJobs.contains(pdf.id)) {
        // Stuck in indexing from a previous app session (isolate died)
        await indexFile(pdf.id, pdf.relativeFilePath);
      }
    }
  }
}

final pdfSearchMetadataProvider = StreamProvider<List<PdfSearchMetadataData>>((
  ref,
) {
  // We can't watch custom selects easily with complex mapping, but drift supports watching tables.
  return ref
      .watch(pdfSearchDaoProvider)
      .select(ref.watch(appDatabaseProvider).pdfSearchMetadata)
      .watch();
});
