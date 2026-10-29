/// A matching PDF page and the highlighted context returned by local search.
class PdfSearchResult {
  const PdfSearchResult({
    required this.fileId,
    required this.pageNumber,
    required this.snippet,
  });

  final int fileId;
  final int pageNumber;
  final String snippet;
}
