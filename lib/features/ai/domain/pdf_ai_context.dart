/// A single PDF page surface that is relevant to an AI query.
///
/// [fileId] and [pageNumber] uniquely identify the page inside the local
/// database so callers can navigate back to it if needed.
///
/// [pageText] is the full extracted text of the page — **not** a short
/// snippet — so the AI model receives enough content to reason about.
///
/// [rank] is an optional FTS5 relevance score (negative; closer to 0 is
/// better).  It is `null` when the source did not produce a rank.
///
/// [fileName] is the human-readable name of the source document. It comes from
/// the local `subject_files` table, never from the model, and is what the
/// context block shows the model so it can attribute an answer to a document a
/// student recognises.
class PdfAiContext {
  final int fileId;
  final int pageNumber;
  final String pageText;
  final double? rank;
  final String? fileName;

  const PdfAiContext({
    required this.fileId,
    required this.pageNumber,
    required this.pageText,
    this.rank,
    this.fileName,
  });

  /// Name shown in context blocks and citations.
  ///
  /// Falls back to a stable synthetic label when the file row is missing (for
  /// example the PDF was deleted but its FTS rows have not been cleaned up), so
  /// a block is never labelled with an empty string.
  String get displayFileName {
    final name = fileName?.trim() ?? '';
    return name.isEmpty ? 'Document $fileId' : name;
  }

  @override
  String toString() =>
      'PdfAiContext(fileId: $fileId, page: $pageNumber, chars: ${pageText.length}, rank: $rank, file: $fileName)';
}
