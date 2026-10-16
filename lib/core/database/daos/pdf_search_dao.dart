import 'package:college_os/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'pdf_search_dao.g.dart';

@DriftAccessor(include: {'../tables/pdf_search_index.drift'})
class PdfSearchDao extends DatabaseAccessor<AppDatabase>
    with _$PdfSearchDaoMixin {
  PdfSearchDao(super.attachedDatabase);

  /// Deletes every page of [fileId] from the FTS index, keeping its metadata.
  ///
  /// Used when a previous run has to be thrown away completely, for example
  /// when the document's page count no longer matches what was indexed.
  Future<void> deleteFilePages(int fileId) async {
    await (delete(
      pdfPageFts,
    )..where((row) => row.fileId.equals(fileId.toString()))).go();
  }

  Future<void> markAsUnsupported(int fileId) =>
      _writeMetadata(fileId, status: 'unsupported');

  /// Marks [fileId] as failed, keeping how far the run got.
  ///
  /// Keeping [pageCount] and [lastIndexedPage] means a retry after a transient
  /// failure (out of memory, process kill, unreadable page) can continue where
  /// it stopped instead of extracting the whole document again.
  Future<void> markAsError(
    int fileId, {
    int pageCount = 0,
    int lastIndexedPage = 0,
  }) => _writeMetadata(
    fileId,
    status: 'error',
    pageCount: pageCount,
    lastIndexedPage: lastIndexedPage,
  );

  /// Prepares [fileId] for indexing and reports where to resume.
  ///
  /// Unlike the previous implementation this does **not** delete the whole FTS
  /// index up front: pages stored by an interrupted run are kept and indexing
  /// restarts after the last page that was stored. Rows are only cleared when
  /// the earlier run never stored a single page.
  Future<PdfIndexStart> beginIndexing(int fileId) async {
    final meta = await getMetadata(fileId);
    final resumablePage = meta?.lastIndexedPage ?? 0;
    if (resumablePage > 0) {
      await _writeMetadata(
        fileId,
        status: 'indexing',
        pageCount: meta!.pageCount,
        lastIndexedPage: resumablePage,
      );
      return PdfIndexStart(
        resumeFromPage: resumablePage,
        previousPageCount: meta.pageCount,
      );
    }

    await transaction(() async {
      await deleteFilePages(fileId);
      await _writeMetadata(fileId, status: 'indexing');
    });
    return const PdfIndexStart(resumeFromPage: 0, previousPageCount: 0);
  }

  /// Stores one extracted [pages] batch and advances the progress metadata in a
  /// single transaction, so progress can never claim pages that were not
  /// actually written and an interruption leaves a consistent resume point.
  Future<void> saveExtractedBatch(
    int fileId,
    List<PdfExtractedPage> pages, {
    required int lastPageIndexed,
    required int totalPages,
  }) async {
    await transaction(() async {
      for (final page in pages) {
        final trimmed = page.text.trim();
        if (trimmed.isEmpty) continue;
        await into(pdfPageFts).insert(
          PdfPageFtsCompanion.insert(
            fileId: fileId.toString(),
            pageNumber: page.pageNumber.toString(),
            pageText: trimmed,
          ),
        );
      }
      await _writeMetadata(
        fileId,
        status: 'indexing ($lastPageIndexed/$totalPages)',
        pageCount: totalPages,
        lastIndexedPage: lastPageIndexed,
      );
    });
  }

  Future<void> completeIndexing(int fileId, int totalPages) => _writeMetadata(
    fileId,
    status: 'indexed',
    pageCount: totalPages,
    lastIndexedPage: totalPages,
  );

  Future<void> deleteFileIndex(int fileId) async {
    return transaction(() async {
      await deleteFilePages(fileId);
      await (delete(
        pdfSearchMetadata,
      )..where((row) => row.fileId.equals(fileId))).go();
    });
  }

  /// Single write path for the metadata row so every column stays in sync.
  Future<void> _writeMetadata(
    int fileId, {
    required String status,
    int pageCount = 0,
    int lastIndexedPage = 0,
  }) async {
    await into(pdfSearchMetadata).insert(
      PdfSearchMetadataCompanion.insert(
        fileId: Value(fileId),
        status: status,
        pageCount: Value(pageCount),
        lastIndexedPage: Value(lastIndexedPage),
        indexedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<PdfSearchMetadataData>> getAllMetadata() =>
      select(pdfSearchMetadata).get();

  Future<PdfSearchMetadataData?> getMetadata(int fileId) => (select(
    pdfSearchMetadata,
  )..where((row) => row.fileId.equals(fileId))).getSingleOrNull();

  Future<List<PdfSearchResultRow>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // Sanitize query to prevent FTS5 syntax errors
    final sanitized = query
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim();
    if (sanitized.isEmpty) return [];

    // Create a prefix search for each word: word1* word2*
    final ftsQuery = sanitized
        .split(RegExp(r'\s+'))
        .map((w) => '$w*')
        .join(' ');

    try {
      final result = await customSelect(
        '''
        SELECT 
          pdf_page_fts.file_id, 
          pdf_page_fts.page_number, 
          snippet(pdf_page_fts, 2, '<b>', '</b>', '...', 64) AS snippet
        FROM pdf_page_fts 
        WHERE pdf_page_fts MATCH ? 
        ORDER BY rank
        ''',
        variables: [Variable.withString(ftsQuery)],
        readsFrom: {pdfPageFts},
      ).get();

      return result.map((row) {
        return PdfSearchResultRow(
          fileId: int.parse(row.read<String>('file_id')),
          pageNumber: int.parse(row.read<String>('page_number')),
          snippet: row.read<String>('snippet'),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Where an interrupted indexing run has to continue.
class PdfIndexStart {
  const PdfIndexStart({
    required this.resumeFromPage,
    required this.previousPageCount,
  });

  /// Highest page number already stored in `pdf_page_fts`. Indexing continues
  /// at `resumeFromPage + 1`; `0` means the file starts at page 1.
  final int resumeFromPage;

  /// Page count recorded when the previous run stopped, or `0` when unknown.
  /// The extraction service compares it with the page count it reads from the
  /// document and starts over when the file no longer matches its index.
  final int previousPageCount;
}

/// One page of extracted text on its way into `pdf_page_fts`.
class PdfExtractedPage {
  const PdfExtractedPage({required this.pageNumber, required this.text});

  final int pageNumber;
  final String text;
}

class PdfSearchResultRow {
  final int fileId;
  final int pageNumber;
  final String snippet;

  PdfSearchResultRow({
    required this.fileId,
    required this.pageNumber,
    required this.snippet,
  });
}
