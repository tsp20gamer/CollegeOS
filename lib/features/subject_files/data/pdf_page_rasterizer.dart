import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

/// Draws single pages of one open document.
abstract class PdfPageRasterizer {
  int get pageCount;

  /// Each page's size in PDF points, page 1 first.
  Future<List<Size>> pageSizes();

  /// Renders page [pageNumber] (1-based) to an image of exactly
  /// [width] x [height] pixels.
  Future<ui.Image> render(int pageNumber, int width, int height);

  Future<void> close();
}

/// [PdfPageRasterizer] on Android's own PdfRenderer (through pdfx).
///
/// The page is drawn on a background thread by the platform, compressed, and
/// decoded by the engine off the UI thread, so neither the Dart UI isolate nor
/// the Android main thread ever parses the document. The PDF itself is opened
/// by path: no copy of the file is read into memory.
class PdfxPageRasterizer implements PdfPageRasterizer {
  PdfxPageRasterizer._(this._document);

  final pdfx.PdfDocument _document;
  bool _closed = false;

  static Future<PdfxPageRasterizer> open(String path) async {
    final document = await pdfx.PdfDocument.openFile(path);
    return PdfxPageRasterizer._(document);
  }

  @override
  int get pageCount => _document.pagesCount;

  @override
  Future<List<Size>> pageSizes() async {
    final sizes = <Size>[];
    for (var number = 1; number <= _document.pagesCount; number++) {
      if (_closed) break;
      try {
        final page = await _document.getPage(number, autoCloseAndroid: true);
        sizes.add(Size(page.width, page.height));
      } catch (_) {
        // A page whose size cannot be read takes its neighbour's shape; it
        // gets its own error placeholder when it is drawn.
        sizes.add(sizes.isEmpty ? const Size(595, 842) : sizes.last);
      }
    }
    return sizes;
  }

  @override
  Future<ui.Image> render(int pageNumber, int width, int height) async {
    if (_closed) throw StateError('document closed');
    final page = await _document.getPage(pageNumber);
    pdfx.PdfPageImage? image;
    try {
      image = await page.render(
        width: width.toDouble(),
        height: height.toDouble(),
        format: pdfx.PdfPageImageFormat.jpeg,
        backgroundColor: '#FFFFFF',
        quality: 90,
      );
    } finally {
      await page.close();
    }
    if (image == null) {
      throw StateError('page $pageNumber could not be drawn');
    }
    final codec = await ui.instantiateImageCodec(image.bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _document.close();
  }
}
