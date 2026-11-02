import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:college_os/features/subject_files/data/pdf_page_rasterizer.dart';
import 'package:college_os/features/subject_files/data/pdf_reader_activity.dart';
import 'package:college_os/features/subject_files/data/pdf_render_budget.dart';
import 'package:college_os/features/subject_files/data/pdf_render_queue.dart';
import 'package:flutter/material.dart';

/// Gap between pages, in logical pixels.
const double kLargePdfPageGap = 8;

/// Turns pages of a [LargePdfReader] from outside (the page scrubber, search).
class LargePdfReaderController extends ChangeNotifier {
  int _pageNumber = 1;
  int? _pendingJump;

  int get pageNumber => _pageNumber;

  void jumpToPage(int pageNumber) {
    _pendingJump = pageNumber;
    notifyListeners();
  }

  int? _takeJump() {
    final jump = _pendingJump;
    _pendingJump = null;
    return jump;
  }
}

/// Where each page sits in the continuous vertical layout.
class LargePdfLayout {
  LargePdfLayout._(this.width, this.tops, this.heights, this.totalHeight);

  factory LargePdfLayout.compute(List<Size> pageSizes, double width) {
    final tops = <double>[];
    final heights = <double>[];
    var y = 0.0;
    for (final size in pageSizes) {
      final aspect = (size.width > 0 && size.height > 0)
          ? size.height / size.width
          : math.sqrt2;
      final height = width * aspect;
      tops.add(y);
      heights.add(height);
      y += height + kLargePdfPageGap;
    }
    final total = pageSizes.isEmpty ? 0.0 : y - kLargePdfPageGap;
    return LargePdfLayout._(width, tops, heights, total);
  }

  final double width;
  final List<double> tops;
  final List<double> heights;
  final double totalHeight;

  int get pageCount => tops.length;

  /// Index (0-based) of the page covering layout offset [y].
  int indexAt(double y) {
    if (tops.isEmpty) return 0;
    var low = 0;
    var high = tops.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (tops[mid] <= y) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// 0-based indexes of the pages overlapping [top]..[bottom].
  (int, int) range(double top, double bottom) {
    if (tops.isEmpty) return (0, -1);
    final first = indexAt(math.max(0, top));
    final last = indexAt(math.max(0, bottom));
    return (first, last);
  }
}

/// A continuous, lazily drawn reader for long or heavy PDFs.
///
/// Only the pages on (or next to) the screen exist as widgets; each one is
/// rendered at the width it is shown at, times the device pixel ratio, and
/// capped by [PdfRenderBudget]; renders go through a [PdfRenderQueue] one at a
/// time, newest first, and only once a page has stayed in view briefly, so a
/// fling does not queue every page it passes. Rendered pages are kept in a
/// small LRU cache bounded by count and bytes, and every image is disposed
/// when it leaves both the cache and the screen. A page that fails to draw
/// shows a placeholder with a retry instead of taking the reader down.
/// Pinch or double-tap zooms; once a zoom settles the visible pages are
/// re-rendered sharper, still inside the pixel budget.
class LargePdfReader extends StatefulWidget {
  const LargePdfReader({
    required this.rasterizer,
    required this.pageSizes,
    this.controller,
    this.initialPageNumber,
    this.onPageChanged,
    this.budget = const PdfRenderBudget(),
    this.cacheMaxEntries = 12,
    this.cacheMaxBytes = 96 * 1024 * 1024,
    this.renderDelay = const Duration(milliseconds: 90),
    super.key,
  });

  final PdfPageRasterizer rasterizer;
  final List<Size> pageSizes;
  final LargePdfReaderController? controller;
  final int? initialPageNumber;
  final ValueChanged<int>? onPageChanged;
  final PdfRenderBudget budget;
  final int cacheMaxEntries;
  final int cacheMaxBytes;

  /// How long a page must stay in view before it is rendered.
  final Duration renderDelay;

  @override
  State<LargePdfReader> createState() => LargePdfReaderState();
}

class LargePdfReaderState extends State<LargePdfReader> {
  final TransformationController _transform = TransformationController();
  late final PdfRenderQueue _queue = PdfRenderQueue(
    maxConcurrent: 1,
    onDiscard: (result) {
      if (result is ui.Image) result.dispose();
    },
  );
  late final BoundedLruCache<String, ui.Image> _cache =
      BoundedLruCache<String, ui.Image>(
        maxEntries: widget.cacheMaxEntries,
        maxBytes: widget.cacheMaxBytes,
        sizeOf: (image) => image.width * image.height * 4,
        onEvict: (_, image) => image.dispose(),
      );

  /// Each page's best render size so far, so a page that comes back into view
  /// shows its cached image at once.
  final Map<int, String> _bestKeyForPage = {};

  LargePdfLayout? _layout;
  Size _viewport = Size.zero;
  int _currentPage = 1;
  double _renderZoom = 1;
  Offset? _doubleTapPosition;
  bool _initialJumpDone = false;

  @visibleForTesting
  BoundedLruCache<String, ui.Image> get cache => _cache;

  @visibleForTesting
  PdfRenderQueue get queue => _queue;

  int get currentPage => _currentPage;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
    widget.controller?.addListener(_onControllerJump);
  }

  @override
  void didUpdateWidget(covariant LargePdfReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerJump);
      widget.controller?.addListener(_onControllerJump);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerJump);
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    _queue.close();
    _cache.clear();
    _bestKeyForPage.clear();
    PdfReaderActivity.clear();
    super.dispose();
  }

  // -- Rendering service for the page widgets --------------------------------

  /// A clone of the best cached image for [pageNumber], if any.
  ui.Image? cachedImage(int pageNumber, {String? exactKey}) {
    final key = exactKey ?? _bestKeyForPage[pageNumber];
    if (key == null) return null;
    final image = _cache.get(key);
    return image?.clone();
  }

  PdfRenderTicket<ui.Image> requestRender(
    int pageNumber,
    PdfRenderSize size,
  ) {
    final key = _key(pageNumber, size);
    return _queue.schedule<ui.Image>(() async {
      final cached = _cache.get(key);
      if (cached != null) return cached.clone();
      final image = await widget.rasterizer.render(
        pageNumber,
        size.width,
        size.height,
      );
      if (!mounted) {
        image.dispose();
        throw StateError('reader closed');
      }
      // The page gets its own handle before the cache may evict (and
      // dispose) the original.
      final shown = image.clone();
      _bestKeyForPage[pageNumber] = key;
      _cache.put(key, image);
      return shown;
    });
  }

  String keyFor(int pageNumber, PdfRenderSize size) => _key(pageNumber, size);

  static String _key(int pageNumber, PdfRenderSize size) =>
      '$pageNumber@${size.width}x${size.height}';

  PdfRenderSize renderSizeFor(int pageNumber) {
    final pageSize = widget.pageSizes[pageNumber - 1];
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    return widget.budget.sizeFor(
      pageWidth: pageSize.width,
      pageHeight: pageSize.height,
      displayWidth: _layout?.width ?? _viewport.width,
      devicePixelRatio: dpr,
      zoom: _renderZoom,
    );
  }

  // -- Scrolling and page tracking --------------------------------------------

  double get _scale => _transform.value.getMaxScaleOnAxis();

  void _onTransformChanged() {
    PdfReaderActivity.markActive();
    _updateCurrentPage();
  }

  void _updateCurrentPage() {
    final layout = _layout;
    if (layout == null || layout.pageCount == 0) return;
    final scale = _scale;
    final top = -_transform.value.getTranslation().y / scale;
    final visibleHeight = _viewport.height / scale;
    // The page under the upper third of the screen is "the page".
    final index = layout.indexAt(top + visibleHeight / 3);
    final page = index + 1;
    if (page != _currentPage) {
      _currentPage = page;
      widget.controller?._pageNumber = page;
      widget.onPageChanged?.call(page);
    }
  }

  void _onControllerJump() {
    final page = widget.controller?._takeJump();
    if (page != null) jumpToPage(page);
  }

  /// Keeps a translation inside the document at [scale].
  Matrix4 _clamped(double x, double y, double scale) {
    final layout = _layout;
    final contentHeight = (layout?.totalHeight ?? 0) * scale;
    final contentWidth = (layout?.width ?? _viewport.width) * scale;
    final minY = math.min(0.0, _viewport.height - contentHeight);
    final minX = math.min(0.0, _viewport.width - contentWidth);
    return Matrix4.identity()
      ..translateByDouble(x.clamp(minX, 0.0), y.clamp(minY, 0.0), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void jumpToPage(int pageNumber) {
    final layout = _layout;
    if (layout == null || layout.pageCount == 0) return;
    final index = pageNumber.clamp(1, layout.pageCount) - 1;
    final scale = _scale;
    final x = _transform.value.getTranslation().x;
    _transform.value = _clamped(x, -layout.tops[index] * scale, scale);
    _updateCurrentPage();
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final scale = _scale;
    final bucket = scale < 1.25
        ? 1.0
        : math.min(widget.budget.maxZoomRenderScale, (scale * 2).round() / 2);
    if (bucket != _renderZoom) {
      setState(() => _renderZoom = bucket);
    }
  }

  void _onDoubleTap() {
    final position = _doubleTapPosition;
    if (position == null) return;
    final scale = _scale;
    if (scale > 1.05) {
      final y = _transform.value.getTranslation().y / scale;
      _transform.value = _clamped(0, y, 1);
      setState(() => _renderZoom = 1);
    } else {
      const target = 2.5;
      final scene = _transform.toScene(position);
      _transform.value = _clamped(
        position.dx - scene.dx * target,
        position.dy - scene.dy * target,
        target,
      );
      setState(() => _renderZoom = target);
    }
    _updateCurrentPage();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        if (_layout == null || _layout!.width != viewport.width) {
          _layout = LargePdfLayout.compute(widget.pageSizes, viewport.width);
        }
        _viewport = viewport;
        final layout = _layout!;
        if (!_initialJumpDone) {
          _initialJumpDone = true;
          final initial = widget.initialPageNumber;
          if (initial != null && initial > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) jumpToPage(initial);
            });
          }
        }
        return GestureDetector(
          onDoubleTapDown: (details) =>
              _doubleTapPosition = details.localPosition,
          onDoubleTap: _onDoubleTap,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: InteractiveViewer.builder(
              transformationController: _transform,
              minScale: 1,
              maxScale: 5,
              boundaryMargin: EdgeInsets.zero,
              onInteractionEnd: _onInteractionEnd,
              builder: (context, viewportQuad) {
                final ys = [
                  viewportQuad.point0.y,
                  viewportQuad.point1.y,
                  viewportQuad.point2.y,
                  viewportQuad.point3.y,
                ];
                final top = ys.reduce(math.min);
                final bottom = ys.reduce(math.max);
                // Half a screen of look-ahead on each side.
                final margin = (bottom - top) / 2;
                final (first, last) = layout.range(
                  top - margin,
                  bottom + margin,
                );
                return SizedBox(
                  width: layout.width,
                  height: math.max(layout.totalHeight, viewport.height),
                  child: Stack(
                    children: [
                      for (var index = first; index <= last; index++)
                        Positioned(
                          key: ValueKey<int>(index),
                          left: 0,
                          top: layout.tops[index],
                          width: layout.width,
                          height: layout.heights[index],
                          child: LargePdfPage(
                            reader: this,
                            pageNumber: index + 1,
                            renderZoom: _renderZoom,
                            renderDelay: widget.renderDelay,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// One page of a [LargePdfReader].
class LargePdfPage extends StatefulWidget {
  const LargePdfPage({
    required this.reader,
    required this.pageNumber,
    required this.renderZoom,
    required this.renderDelay,
    super.key,
  });

  final LargePdfReaderState reader;
  final int pageNumber;
  final double renderZoom;
  final Duration renderDelay;

  @override
  State<LargePdfPage> createState() => _LargePdfPageState();
}

class _LargePdfPageState extends State<LargePdfPage> {
  ui.Image? _image;
  String? _imageKey;
  PdfRenderTicket<ui.Image>? _ticket;
  Timer? _delay;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureImage();
  }

  @override
  void didUpdateWidget(covariant LargePdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.renderZoom != widget.renderZoom ||
        oldWidget.pageNumber != widget.pageNumber) {
      _ensureImage();
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _ticket?.cancel();
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  void _ensureImage() {
    final reader = widget.reader;
    final size = reader.renderSizeFor(widget.pageNumber);
    final key = reader.keyFor(widget.pageNumber, size);
    if (_imageKey == key || _failed) return;

    // Show whatever the cache holds right away (exact size, else the best
    // earlier render of this page, scaled) while a sharper one is drawn.
    final exact = reader.cachedImage(widget.pageNumber, exactKey: key);
    if (exact != null) {
      _setImage(exact, key, rebuild: false);
      return;
    }
    if (_image == null) {
      final earlier = reader.cachedImage(widget.pageNumber);
      if (earlier != null) _setImage(earlier, null, rebuild: false);
    }

    _delay?.cancel();
    _ticket?.cancel();
    _delay = Timer(widget.renderDelay, () => _startRender(size, key));
  }

  void _startRender(PdfRenderSize size, String key) {
    if (!mounted) return;
    final ticket = widget.reader.requestRender(widget.pageNumber, size);
    _ticket = ticket;
    ticket.future.then(
      (image) {
        if (image == null) return;
        if (!mounted || !identical(_ticket, ticket)) {
          image.dispose();
          return;
        }
        _setImage(image, key);
      },
      onError: (Object _) {
        if (!mounted || !identical(_ticket, ticket)) return;
        setState(() => _failed = true);
      },
    );
  }

  void _setImage(ui.Image image, String? key, {bool rebuild = true}) {
    final old = _image;
    if (rebuild && mounted) {
      setState(() {
        _image = image;
        _imageKey = key;
        _failed = false;
      });
    } else {
      _image = image;
      _imageKey = key;
    }
    old?.dispose();
  }

  void _retry() {
    setState(() {
      _failed = false;
      _imageKey = null;
    });
    _ensureImage();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = _image;
    Widget child;
    if (_failed && image == null) {
      child = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              "Couldn't show page ${widget.pageNumber}",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            TextButton(onPressed: _retry, child: const Text('Retry')),
          ],
        ),
      );
    } else if (image == null) {
      child = Center(
        child: Text(
          '${widget.pageNumber}',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      child = RawImage(
        image: image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Semantics(label: 'Page ${widget.pageNumber}', child: child),
    );
  }
}
