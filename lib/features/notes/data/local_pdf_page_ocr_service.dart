import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../domain/pdf_page_ocr_service.dart';

/// On-device OCR for Android. The Latin and Devanagari ML Kit models are
/// bundled in the APK, so scanned pages work without downloading a model.
final class LocalPdfPageOcrService implements PdfPageOcrService {
  const LocalPdfPageOcrService();

  static const _maxRasterDimension = 2200.0;
  static const _rasterScale = 2.0;

  @override
  bool get isAvailable => Platform.isAndroid;

  @override
  Future<Map<int, String>> extractText({
    required String filePath,
    required List<int> pageNumbers,
  }) async {
    if (!isAvailable || pageNumbers.isEmpty) return const {};

    final document = await pdfx.PdfDocument.openFile(filePath);
    final latin = TextRecognizer(script: TextRecognitionScript.latin);
    final devanagari = TextRecognizer(script: TextRecognitionScript.devanagiri);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'collegeos_ocr_',
    );
    final texts = <int, String>{};

    try {
      for (final pageNumber in pageNumbers) {
        final page = await document.getPage(pageNumber);
        try {
          final scale = _scaleFor(page.width, page.height);
          final image = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: pdfx.PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 88,
          );
          if (image == null) continue;

          final imageFile = File(
            '${temporaryDirectory.path}${Platform.pathSeparator}$pageNumber.jpg',
          );
          await imageFile.writeAsBytes(image.bytes, flush: true);
          final input = InputImage.fromFilePath(imageFile.path);
          final latinText = (await latin.processImage(input)).text;
          final devanagariText = (await devanagari.processImage(input)).text;
          final lines = <String>{
            ...latinText.split(RegExp(r'\r?\n')).map((line) => line.trim()),
            ...devanagariText
                .split(RegExp(r'\r?\n'))
                .map((line) => line.trim()),
          }..removeWhere((line) => line.isEmpty);
          texts[pageNumber] = lines.join('\n');
          await imageFile.delete();
        } finally {
          await page.close();
        }
      }
      return texts;
    } finally {
      await latin.close();
      await devanagari.close();
      await document.close();
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  double _scaleFor(double width, double height) {
    final longestSide = width > height ? width : height;
    if (longestSide <= 0) return _rasterScale;
    return (_maxRasterDimension / longestSide)
        .clamp(0.5, _rasterScale)
        .toDouble();
  }
}
