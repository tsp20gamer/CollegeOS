import 'dart:collection';
import 'dart:math' as math;

/// Pixel size of one rendered page image.
class PdfRenderSize {
  const PdfRenderSize(this.width, this.height);

  final int width;
  final int height;

  int get pixels => width * height;

  /// Bytes the decoded RGBA image holds in memory.
  int get bytes => pixels * 4;

  @override
  bool operator ==(Object other) =>
      other is PdfRenderSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => '${width}x$height';
}

/// How large a page may be rendered.
///
/// A page is drawn for the width it is shown at on screen (times the device
/// pixel ratio and the zoom), never at the PDF's own size: a scanned A3 page or
/// a poster can declare a page many times larger than a phone screen, and a
/// bitmap that size is what runs a phone out of memory. Every render is also
/// capped by a pixel budget and a longest side, so even a deep zoom on a huge
/// page stays a bounded allocation.
class PdfRenderBudget {
  const PdfRenderBudget({
    this.maxPixelsPerPage = 8 * 1000 * 1000,
    this.maxSidePixels = 4096,
    this.maxZoomRenderScale = 3,
  });

  /// Largest image (width x height) one page render may allocate.
  final int maxPixelsPerPage;

  /// Longest side of one page render, in pixels.
  final int maxSidePixels;

  /// Zoom beyond this is shown by scaling the sharpest render, not by
  /// rendering an even bigger bitmap.
  final double maxZoomRenderScale;

  /// The render size for a page of [pageWidth] x [pageHeight] (any unit, only
  /// the aspect ratio is used) shown [displayWidth] logical pixels wide.
  PdfRenderSize sizeFor({
    required double pageWidth,
    required double pageHeight,
    required double displayWidth,
    required double devicePixelRatio,
    double zoom = 1,
  }) {
    final aspect = (pageWidth > 0 && pageHeight > 0 && pageWidth.isFinite)
        ? pageHeight / pageWidth
        : math.sqrt2;
    final dpr = devicePixelRatio > 0 && devicePixelRatio.isFinite
        ? devicePixelRatio
        : 1.0;
    final effectiveZoom = zoom.isFinite
        ? zoom.clamp(1.0, maxZoomRenderScale).toDouble()
        : 1.0;
    final safeDisplayWidth = displayWidth.isFinite && displayWidth > 0
        ? displayWidth
        : 1.0;

    var width = safeDisplayWidth * dpr * effectiveZoom;
    var height = width * aspect;

    // Longest side first, then the area budget.
    final longest = math.max(width, height);
    if (longest > maxSidePixels) {
      final shrink = maxSidePixels / longest;
      width *= shrink;
      height *= shrink;
    }
    if (width * height > maxPixelsPerPage) {
      final shrink = math.sqrt(maxPixelsPerPage / (width * height));
      width *= shrink;
      height *= shrink;
    }
    return PdfRenderSize(
      math.max(1, width.floor()),
      math.max(1, height.floor()),
    );
  }
}

/// A least-recently-used cache bounded by entry count and by total size.
///
/// Every value that leaves the cache - evicted, replaced, removed or cleared -
/// is handed to [onEvict] exactly once, which is where page images are
/// disposed. Values shown on screen are held by their widgets through their
/// own handles, so evicting one here never pulls an image out from under a
/// page that is being painted.
class BoundedLruCache<K, V> {
  BoundedLruCache({
    required this.maxEntries,
    required this.maxBytes,
    required this.sizeOf,
    this.onEvict,
  }) : assert(maxEntries > 0),
       assert(maxBytes > 0);

  final int maxEntries;
  final int maxBytes;
  final int Function(V value) sizeOf;
  final void Function(K key, V value)? onEvict;

  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();
  int _bytes = 0;

  int get length => _entries.length;
  int get bytes => _bytes;
  Iterable<K> get keys => _entries.keys;

  bool containsKey(K key) => _entries.containsKey(key);

  /// Returns the value for [key] and marks it as the most recently used.
  V? get(K key) {
    final value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value;
    return value;
  }

  /// Stores [value] under [key] as the most recently used entry, then evicts
  /// the least recently used entries until both bounds hold. A value larger
  /// than [maxBytes] on its own is not kept at all.
  void put(K key, V value) {
    final previous = _entries.remove(key);
    if (previous != null) {
      _bytes -= sizeOf(previous);
      if (!identical(previous, value)) onEvict?.call(key, previous);
    }
    final size = sizeOf(value);
    if (size > maxBytes) {
      onEvict?.call(key, value);
      return;
    }
    _entries[key] = value;
    _bytes += size;
    _trim();
  }

  void remove(K key) {
    final value = _entries.remove(key);
    if (value == null) return;
    _bytes -= sizeOf(value);
    onEvict?.call(key, value);
  }

  void clear() {
    final entries = _entries.entries.toList();
    _entries.clear();
    _bytes = 0;
    for (final entry in entries) {
      onEvict?.call(entry.key, entry.value);
    }
  }

  void _trim() {
    while (_entries.isNotEmpty &&
        (_entries.length > maxEntries || _bytes > maxBytes)) {
      final oldest = _entries.keys.first;
      final value = _entries.remove(oldest) as V;
      _bytes -= sizeOf(value);
      onEvict?.call(oldest, value);
    }
  }
}
