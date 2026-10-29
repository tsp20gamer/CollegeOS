/// Recognizes text on PDF pages that have no embedded text layer.
abstract interface class PdfPageOcrService {
  bool get isAvailable;

  Future<Map<int, String>> extractText({
    required String filePath,
    required List<int> pageNumbers,
  });
}

/// Keeps non-Android use and extraction unit tests independent of platform OCR.
final class NoopPdfPageOcrService implements PdfPageOcrService {
  const NoopPdfPageOcrService();

  @override
  bool get isAvailable => false;

  @override
  Future<Map<int, String>> extractText({
    required String filePath,
    required List<int> pageNumbers,
  }) async => const {};
}
