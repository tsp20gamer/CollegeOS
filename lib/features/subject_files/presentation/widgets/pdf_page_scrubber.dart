import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:flutter/material.dart';

/// How wide the rail's touch area is.
///
/// The visible groove and thumb are far slimmer than this: the extra width is
/// what makes an edge control grabbable without a steady hand.
const double _railTouchWidth = 36;

/// Width of the groove the thumb travels in.
const double _trackWidth = 4;

/// Width of the thumb, resting and under the finger.
const double _thumbWidth = 6;
const double _thumbDraggedWidth = 10;

/// Shortest the thumb may ever get.
///
/// A long document would otherwise shrink the thumb to something that reads as
/// a speck rather than as a position the student can grab.
const double _minThumbLength = 36;

/// How far the rail keeps clear of the page's own top and bottom edges.
const double _railTopInset = AppSpacing.md;
const double _railBottomInset = AppSpacing.md;

/// Height of the page bubble shown while scrubbing.
const double _bubbleHeight = 28;

/// A page scrubber for the right edge of a document.
///
/// Syncfusion's viewer owns its own scrolling and exposes no pixel extent, so
/// this rail is honest about what it can measure: it is a *page* rail. The
/// thumb's travel maps to the document's pages, dragging it turns pages, and
/// the bubble names the page under the finger, and a persistent page label
/// stays visible at the bottom edge. It is the whole right edge's scrolling
/// affordance, so it stays visible instead of fading out.
class PdfPageScrubber extends StatefulWidget {
  const PdfPageScrubber({
    required this.pageCount,
    required this.currentPage,
    required this.onPageSelected,
    super.key,
  });

  /// Total pages in the open document. Fewer than two pages render nothing.
  final int pageCount;

  /// The page the viewer is showing.
  final int currentPage;

  /// Called with a page number the student asked for.
  final ValueChanged<int> onPageSelected;

  @override
  State<PdfPageScrubber> createState() => _PdfPageScrubberState();
}

class _PdfPageScrubberState extends State<PdfPageScrubber> {
  /// The page under the finger while dragging, so the thumb follows the drag
  /// without waiting for the viewer to report the page it turned to.
  int? _draggedPage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pageCount = widget.pageCount;
    if (pageCount < 2) return const SizedBox.shrink();

    final page = _draggedPage ?? widget.currentPage.clamp(1, pageCount);

    return Semantics(
      container: true,
      slider: true,
      label: 'Document pages',
      value: 'Page $page of $pageCount',
      increasedValue: page < pageCount ? 'Page ${page + 1} of $pageCount' : '',
      decreasedValue: page > 1 ? 'Page ${page - 1} of $pageCount' : '',
      onIncrease: page < pageCount ? () => _select(page + 1) : null,
      onDecrease: page > 1 ? () => _select(page - 1) : null,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(
            top: _railTopInset,
            bottom: MediaQuery.paddingOf(context).bottom + _railBottomInset,
          ),
          child: SizedBox(
            width: _railTouchWidth,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackHeight = constraints.maxHeight;
                final thumbLength = _thumbLength(trackHeight, pageCount);
                final travel = trackHeight - thumbLength;
                final thumbTop = pageCount <= 1
                    ? 0.0
                    : (page - 1) / (pageCount - 1) * travel;
                final thumbWidth = _draggedPage == null
                    ? _thumbWidth
                    : _thumbDraggedWidth;
                final bubbleTop =
                    thumbTop + thumbLength / 2 - _bubbleHeight / 2;

                return GestureDetector(
                  key: const Key('pdf_page_scrubber_gestures'),
                  behavior: HitTestBehavior.opaque,
                  // A tap is a jump, so it leaves no thumb behind the finger
                  // and no bubble; a drag is a scrub and shows both.
                  onTapDown: (details) => _seek(
                    details.localPosition.dy,
                    trackHeight: trackHeight,
                    thumbLength: thumbLength,
                    pageCount: pageCount,
                    follow: false,
                  ),
                  onVerticalDragStart: (details) => _seek(
                    details.localPosition.dy,
                    trackHeight: trackHeight,
                    thumbLength: thumbLength,
                    pageCount: pageCount,
                    follow: true,
                  ),
                  onVerticalDragUpdate: (details) => _seek(
                    details.localPosition.dy,
                    trackHeight: trackHeight,
                    thumbLength: thumbLength,
                    pageCount: pageCount,
                    follow: true,
                  ),
                  onVerticalDragEnd: (_) => _endDrag(),
                  onVerticalDragCancel: _endDrag,
                  child: Stack(
                    // The bubble sits left of the rail, over the page.
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        key: const Key('pdf_page_scrubber_page_label'),
                        right: _railTouchWidth + AppSpacing.xxs,
                        bottom: 0,
                        child: IgnorePointer(
                          child: _PageLabel(text: 'Page $page of $pageCount'),
                        ),
                      ),
                      Positioned(
                        right: _centerOffset(_trackWidth),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: _trackWidth,
                          decoration: BoxDecoration(
                            color: colors.outlineVariant.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      Positioned(
                        right: _centerOffset(thumbWidth),
                        top: thumbTop,
                        child: AnimatedContainer(
                          key: const Key('pdf_page_scrubber_thumb'),
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOutCubic,
                          width: thumbWidth,
                          height: thumbLength,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .18),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_draggedPage != null)
                        Positioned(
                          key: const Key('pdf_page_scrubber_bubble'),
                          right: _railTouchWidth + AppSpacing.xxs,
                          top: bubbleTop.clamp(
                            0.0,
                            (trackHeight - _bubbleHeight).clamp(
                              0.0,
                              double.maxFinite,
                            ),
                          ),
                          child: Material(
                            color: colors.inverseSurface,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxxs,
                              ),
                              child: Text(
                                'Page $page of $pageCount',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: colors.onInverseSurface),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Distance from the column's right edge that centres a [width]-wide element.
  double _centerOffset(double width) => (_railTouchWidth - width) / 2;

  /// The thumb stands for one page out of many, but never shrinks past a
  /// grabbable length.
  double _thumbLength(double trackHeight, int pageCount) {
    final proportional = trackHeight / pageCount;
    final shortest = _minThumbLength.clamp(0.0, trackHeight);
    return proportional.clamp(shortest, trackHeight).toDouble();
  }

  /// Turns a vertical position in the rail into a page, following the finger.
  ///
  /// The thumb is centred on the touch so grabbing it never jumps the page, and
  /// anywhere on the rail is a seek, so a tap near the middle of the track goes
  /// straight there. [follow] keeps the thumb and the page bubble under the
  /// finger while scrubbing.
  void _seek(
    double localY, {
    required double trackHeight,
    required double thumbLength,
    required int pageCount,
    required bool follow,
  }) {
    final travel = trackHeight - thumbLength;
    final thumbTop = (localY - thumbLength / 2).clamp(0.0, travel);
    final fraction = travel <= 0 ? 0.0 : thumbTop / travel;
    final page = (1 + fraction * (pageCount - 1)).round().clamp(1, pageCount);
    if (follow || _draggedPage != null) {
      setState(() => _draggedPage = follow ? page : null);
    }
    _select(page);
  }

  void _endDrag() {
    if (_draggedPage == null) return;
    setState(() => _draggedPage = null);
  }

  void _select(int page) {
    if (page == widget.currentPage) return;
    widget.onPageSelected(page);
  }
}

class _PageLabel extends StatelessWidget {
  const _PageLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
