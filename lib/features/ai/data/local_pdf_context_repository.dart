import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/features/ai/domain/ai_context_limits.dart';
import 'package:college_os/features/ai/domain/ai_query_builder.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:college_os/features/ai/domain/pdf_context_repository.dart';
import 'package:college_os/features/subject_files/domain/subject_file_repository.dart';

/// SQLite-backed implementation of [PdfContextRepository].
///
/// Delegates to [PdfSearchDao.searchAiContextByExpression], which queries the
/// existing `pdf_page_fts` FTS5 virtual table. No data is written or deleted;
/// this is a pure read path over the index the PDF pipeline already built.
///
/// File names are resolved from the `subject_files` table so every context
/// block can be attributed to a document the student recognises. Names are
/// cached in memory because the same handful of PDFs back every question, and
/// a missing row degrades to a synthetic label rather than failing the search.
final class LocalPdfContextRepository implements PdfContextRepository {
  LocalPdfContextRepository(
    this._dao, [
    this._fileRepository,
    this._limits = AiContextLimits.defaults,
  ]);

  final PdfSearchDao _dao;
  final SubjectFileRepository? _fileRepository;
  final AiContextLimits _limits;

  /// `fileId -> display name`. Small, long-lived, and only ever populated from
  /// local rows, so it cannot leak anything the user cannot already see.
  final Map<int, String> _nameCache = {};

  @override
  Future<List<PdfAiContext>> retrieveContext(
    String question, {
    int? limit,
  }) async {
    final effectiveLimit = limit ?? _limits.maxContextPages;
    if (question.trim().isEmpty || effectiveLimit <= 0) return const [];

    // A question is not a keyword list: build an OR expression so BM25 can rank
    // pages that match the most meaningful terms instead of demanding all of them.
    final expression = AiQueryBuilder.buildFtsExpression(question);
    if (expression == null) return const [];

    final rows = await _dao.searchAiContextByExpression(
      expression,
      limit: effectiveLimit,
    );
    if (rows.isEmpty) return const [];

    final names = await _resolveFileNames(rows.map((r) => r.fileId).toSet());

    return rows
        .map(
          (r) => PdfAiContext(
            fileId: r.fileId,
            pageNumber: r.pageNumber,
            pageText: r.pageText,
            rank: r.rank,
            fileName: names[r.fileId],
          ),
        )
        .toList();
  }

  /// Looks up display names for [fileIds], consulting the cache first.
  ///
  /// Never throws: a database hiccup degrades to synthetic labels, because a
  /// missing file name must not stop a student from getting an answer.
  Future<Map<int, String>> _resolveFileNames(Set<int> fileIds) async {
    final unresolved = fileIds
        .where((id) => !_nameCache.containsKey(id))
        .toList();

    final repository = _fileRepository;
    if (repository != null && unresolved.isNotEmpty) {
      for (final id in unresolved) {
        try {
          final file = await repository.getById(id);
          final title = file?.title.trim() ?? '';
          final name = title.isEmpty ? file?.fileName.trim() ?? '' : title;
          if (name.isNotEmpty) _nameCache[id] = name;
        } catch (_) {
          // Leave it unresolved; the caller falls back to a synthetic label.
        }
      }
    }

    return {
      for (final id in fileIds)
        if (_nameCache[id] != null) id: _nameCache[id]!,
    };
  }
}
