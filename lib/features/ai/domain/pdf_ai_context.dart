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
class PdfAiContext {
  final int fileId;
  final int pageNumber;
  final String pageText;
  final double? rank;

  const PdfAiContext({
    required this.fileId,
    required this.pageNumber,
    required this.pageText,
    this.rank,
  });

  @override
  String toString() =>
      'PdfAiContext(fileId: $fileId, page: $pageNumber, chars: ${pageText.length}, rank: $rank)';
}
