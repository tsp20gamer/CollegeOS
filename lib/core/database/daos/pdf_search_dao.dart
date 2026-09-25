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

  Future<void> saveExtractedPages(
    int fileId,
    List<String> pageTexts,
  ) async {
    return transaction(() async {
      await (delete(pdfPageFts)..where((row) => row.fileId.equals(fileId.toString()))).go();

      for (int i = 0; i < pageTexts.length; i++) {
        final text = pageTexts[i].trim();
        if (text.isNotEmpty) {
          await into(pdfPageFts).insert(
            PdfPageFtsCompanion.insert(
              fileId: fileId.toString(),
              pageNumber: (i + 1).toString(),
              pageText: text,
            ),
          );
        }
      }

      await into(pdfSearchMetadata).insert(
        PdfSearchMetadataCompanion.insert(
          fileId: Value(fileId),
          status: 'indexed',
          pageCount: Value(pageTexts.length),
          indexedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        mode: InsertMode.insertOrReplace,
      );
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
      // Return empty results if there's a malformed query error
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
