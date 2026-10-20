import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A dock destination's glyph: a bundled Lottie animation painted in one colour
/// through the same accent the Material icon it replaces used.
///
/// The dock's language is one accent, not five palettes: every animation is
/// flattened to [tint] with a `srcIn` filter, so the selected destination is
/// cobalt and the rest are muted exactly as before, in both themes.
///
/// Playback is deliberately restrained:
/// - a destination that is already selected when the dock mounts rests on the
///   animation's final frame instead of animating on launch;
/// - choosing a destination plays the animation once, accelerated to at most
///   [AppDurations.dockLottieMaxPlayback], and holds the final frame;
/// - leaving a destination snaps it back to its resting frame ([restAt]), so the
///   unselected row is always the same still image;
/// - when Android asks for reduced motion, or an asset is missing, the Material
///   icon is shown instead and nothing animates.
class DockLottieIcon extends StatefulWidget {
  const DockLottieIcon({
    required this.asset,
    required this.label,
    required this.selected,
    required this.reduceMotion,
    required this.tint,
    required this.fallbackIcon,
    this.glyphScale = 1,
    this.restAt = 1,
    super.key,
  });

  /// Bundled animation, for example `assets/lottie/home.json`.
  final String asset;

  /// Destination name, used for keys and for the fallback icon's key.
  final String label;

  final bool selected;
  final bool reduceMotion;

  /// Colour the whole animation is painted in.
  final Color tint;

  /// Icon shown when motion is reduced or the animation cannot be loaded.
  final IconData fallbackIcon;

  /// How much the animation's own artwork is enlarged inside the 24 px glyph
  /// box.
  ///
  /// Each source animation draws its subject at a different size inside its
  /// canvas — the Tasks tick fills nearly the whole frame while the Home
  /// dashboard occupies a fifth of it — so the dock normalises them here
  /// instead of shipping five glyphs of five different visual weights.
  final double glyphScale;

  /// Progress the animation rests on while the destination is not selected.
  ///
  /// The dock's animations draw themselves in from an empty first frame, so the
  /// resting state is the finished frame: an unselected destination is a still,
  /// complete glyph, and choosing it replays the drawing.
  final double restAt;

  /// Key of the Material fallback, kept for the dock's existing selectors.
  Key get fallbackKey => Key('dock_icon_${label}_$selected');

  @override
  State<DockLottieIcon> createState() => _DockLottieIconState();
}

class _DockLottieIconState extends State<DockLottieIcon>
    with SingleTickerProviderStateMixin {
  // Created eagerly: a destination that renders the Material fallback never
  // builds an animation, and a lazily created controller would otherwise be
  // constructed for the first time inside dispose(), while the element is
  // already deactivated.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  /// True once a composition has been handed to us by the player.
  bool _loaded = false;

  /// Set when a destination is chosen before its animation has loaded.
  bool _playWhenLoaded = false;

  @override
  void didUpdateWidget(covariant DockLottieIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected) return;
    if (widget.selected) {
      if (_loaded && !widget.reduceMotion) {
        _controller.forward(from: 0);
      } else {
        _playWhenLoaded = true;
      }
    } else {
      _playWhenLoaded = false;
      // Unselected destinations always rest on the same still frame.
      _controller.value = widget.restAt;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLoaded(LottieComposition composition) {
    if (!mounted) return;
    _loaded = true;
    // The native animations run 1–4.6 s; the dock's beat is far shorter, so the
    // controller's duration is the shorter of the two and the composition is
    // played proportionally faster.
    final native = composition.duration;
    _controller.duration = native < AppDurations.dockLottieMaxPlayback
        ? native
        : AppDurations.dockLottieMaxPlayback;
    if (_playWhenLoaded) {
      _playWhenLoaded = false;
      _controller.forward(from: 0);
    } else {
      // The destination that is already selected rests on the finished frame.
      _controller.value = widget.selected ? 1.0 : widget.restAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      widget.fallbackIcon,
      key: widget.fallbackKey,
      color: widget.tint,
      size: AppIconSize.md,
    );
    if (widget.reduceMotion) return fallback;

    return SizedBox.square(
      dimension: AppIconSize.md,
      // Enlarging the artwork about the box centre crops the canvas's empty
      // margin instead of the drawing: every source subject is centred, so the
      // clip only ever removes transparent pixels.
      child: ClipRect(
        child: Transform.scale(
          scale: widget.glyphScale,
          // The animation repaints on its own schedule; keeping it in its own
          // layer stops the glass dock's blur from being dragged into every
          // frame.
          child: RepaintBoundary(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(widget.tint, BlendMode.srcIn),
              child: Lottie.asset(
                widget.asset,
                key: ValueKey('dock_lottie_${widget.label}'),
                controller: _controller,
                fit: BoxFit.contain,
                onLoaded: _handleLoaded,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
