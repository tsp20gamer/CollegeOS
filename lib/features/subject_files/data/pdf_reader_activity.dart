import 'dart:io';

/// A cross-isolate "the student is scrolling a PDF right now" signal.
///
/// Background OCR indexing runs in the foreground service's own isolate, in the
/// same app process as the reader. Rendering a page for OCR while the reader is
/// rendering pages for the screen doubles the bitmaps and native renderer work
/// at exactly the moment the student is flinging through a document, so the
/// reader touches a small marker file while it scrolls and the OCR loop waits
/// between pages while the marker is fresh. Both sides live in one process, so
/// they share the same temporary directory and no plugin is needed.
class PdfReaderActivity {
  PdfReaderActivity._();

  /// How long after the last scroll the indexer keeps waiting.
  static const Duration activeWindow = Duration(seconds: 3);

  /// Longest a single OCR page waits, so indexing always makes progress.
  static const Duration maxWait = Duration(seconds: 20);

  static const Duration _markThrottle = Duration(milliseconds: 800);
  static DateTime? _lastMark;

  static File _marker() => File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}collegeos_pdf_reader_active',
  );

  /// Records that the reader is scrolling. Cheap and throttled; never throws.
  static void markActive({DateTime? now}) {
    final time = now ?? DateTime.now();
    final last = _lastMark;
    if (last != null && time.difference(last) < _markThrottle) return;
    _lastMark = time;
    try {
      _marker().writeAsStringSync(
        time.millisecondsSinceEpoch.toString(),
        flush: false,
      );
    } catch (_) {
      // The signal is only a courtesy to the indexer.
    }
  }

  /// Clears the signal (the reader closed).
  static void clear() {
    _lastMark = null;
    try {
      final marker = _marker();
      if (marker.existsSync()) marker.deleteSync();
    } catch (_) {}
  }

  /// Whether the reader scrolled within [activeWindow] of [now].
  static bool isActive({DateTime? now}) {
    try {
      final marker = _marker();
      if (!marker.existsSync()) return false;
      final millis = int.tryParse(marker.readAsStringSync().trim());
      if (millis == null) return false;
      final last = DateTime.fromMillisecondsSinceEpoch(millis);
      final age = (now ?? DateTime.now()).difference(last);
      return !age.isNegative && age < activeWindow;
    } catch (_) {
      return false;
    }
  }

  /// Waits (up to [maxWait]) while the reader is scrolling.
  static Future<void> yieldWhileReading({
    Duration poll = const Duration(milliseconds: 400),
    Duration? limit,
  }) async {
    final deadline = DateTime.now().add(limit ?? maxWait);
    while (isActive() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(poll);
    }
  }
}
