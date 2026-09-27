import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:college_os/features/ai/domain/pdf_context_repository.dart';

/// SQLite-backed implementation of [PdfContextRepository].
///
/// Delegates directly to [PdfSearchDao.searchForAiContext], which queries the
/// existing `pdf_page_fts` FTS5 virtual table.  No data is written or
/// deleted; this is a pure read path.
final class LocalPdfContextRepository implements PdfContextRepository {
  const LocalPdfContextRepository(this._dao);

  final PdfSearchDao _dao;

  @override
  Future<List<PdfAiContext>> retrieveContext(
    String question, {
    int limit = 8,
  }) async {
    final rows = await _dao.searchForAiContext(question, limit: limit);

    return rows
        .map(
          (r) => PdfAiContext(
            fileId: r.fileId,
            pageNumber: r.pageNumber,
            pageText: r.pageText,
            rank: r.rank,
          ),
        )
        .toList();
  }
}
