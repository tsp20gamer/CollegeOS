import 'package:college_os/core/database/app_database.dart';
import 'package:drift/drift.dart';

part 'pdf_search_dao.g.dart';

@DriftAccessor(include: {'../tables/pdf_search_index.drift'})
class PdfSearchDao extends DatabaseAccessor<AppDatabase>
    with _$PdfSearchDaoMixin {
  PdfSearchDao(super.attachedDatabase);

  Future<void> markAsUnsupported(int fileId) async {
    await into(pdfSearchMetadata).insert(
      PdfSearchMetadataCompanion.insert(
        fileId: Value(fileId),
        status: 'unsupported',
        pageCount: const Value(0),
        indexedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> markAsError(int fileId) async {
    await into(pdfSearchMetadata).insert(
      PdfSearchMetadataCompanion.insert(
        fileId: Value(fileId),
        status: 'error',
        pageCount: const Value(0),
        indexedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> beginIndexing(int fileId) async {
    await (delete(pdfPageFts)..where((row) => row.fileId.equals(fileId.toString()))).go();
    await into(pdfSearchMetadata).insert(
      PdfSearchMetadataCompanion.insert(
        fileId: Value(fileId),
        status: 'indexing',
        pageCount: const Value(0),
        indexedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateProgress(int fileId, int currentPage, int totalPages) async {
    await into(pdfSearchMetadata).insert(
      PdfSearchMetadataCompanion.insert(
        fileId: Value(fileId),
        status: 'indexing ($currentPage/$totalPages)',
        pageCount: Value(totalPages),
        indexedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> saveExtractedPage(int fileId, int pageNumber, String text) async {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      await into(pdfPageFts).insert(
        PdfPageFtsCompanion.insert(
          fileId: fileId.toString(),
          pageNumber: pageNumber.toString(),
          pageText: trimmed,
        ),
      );
    }
  }

  Future<void> completeIndexing(int fileId, int totalPages) async {
    await into(pdfSearchMetadata).insert(
      PdfSearchMetadataCompanion.insert(
        fileId: Value(fileId),
        status: 'indexed',
        pageCount: Value(totalPages),
        indexedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> saveExtractedPages(
    int fileId,
    List<String> pageTexts,
  ) async {
    return transaction(() async {
      await beginIndexing(fileId);

      for (int i = 0; i < pageTexts.length; i++) {
        await saveExtractedPage(fileId, i + 1, pageTexts[i]);
      }

      await completeIndexing(fileId, pageTexts.length);
    });
  }

  Future<void> deleteFileIndex(int fileId) async {
    return transaction(() async {
      await (delete(pdfPageFts)..where((row) => row.fileId.equals(fileId.toString()))).go();
      await (delete(pdfSearchMetadata)..where((row) => row.fileId.equals(fileId))).go();
    });
  }

  Future<List<PdfSearchMetadataData>> getAllMetadata() => select(pdfSearchMetadata).get();
  
  Future<PdfSearchMetadataData?> getMetadata(int fileId) =>
      (select(pdfSearchMetadata)..where((row) => row.fileId.equals(fileId))).getSingleOrNull();

  Future<List<PdfSearchResultRow>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // Sanitize query to prevent FTS5 syntax errors
    final sanitized = query.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();
    if (sanitized.isEmpty) return [];

    // Create a prefix search for each word: word1* word2*
    final ftsQuery = sanitized.split(RegExp(r'\s+')).map((w) => '$w*').join(' ');

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

  Future<List<PdfAiContextRow>> searchForAiContext(
    String query, {
    int limit = 8,
  }) async {
    if (query.trim().isEmpty) return [];

    final sanitized =
        query.replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();
    if (sanitized.isEmpty) return [];

    final ftsQuery =
        sanitized.split(RegExp(r'\s+')).map((w) => '$w*').join(' ');

    try {
      final rows = await customSelect(
        '''
        SELECT
          pdf_page_fts.file_id,
          pdf_page_fts.page_number,
          pdf_page_fts.page_text,
          rank
        FROM pdf_page_fts
        WHERE pdf_page_fts MATCH ?
        ORDER BY rank
        LIMIT ?
        ''',
        variables: [
          Variable.withString(ftsQuery),
          Variable.withInt(limit),
        ],
        readsFrom: {pdfPageFts},
      ).get();

      return rows.map((row) {
        return PdfAiContextRow(
          fileId: int.parse(row.read<String>('file_id')),
          pageNumber: int.parse(row.read<String>('page_number')),
          pageText: row.read<String>('page_text'),
          rank: row.read<double>('rank'),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

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

class PdfAiContextRow {
  final int fileId;
  final int pageNumber;
  final String pageText;
  final double rank;

  const PdfAiContextRow({
    required this.fileId,
    required this.pageNumber,
    required this.pageText,
    required this.rank,
  });
}
