import 'dart:math' as math;

import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

class GradientProgressRing extends StatelessWidget {
  const GradientProgressRing({
    required this.value,
    required this.child,
    this.size = 72,
    this.strokeWidth = 5,
    this.semanticLabel,
    this.color,
    super.key,
  });

  final double value;
  final Widget child;
  final double size;
  final double strokeWidth;
  final String? semanticLabel;

  /// Draws the arc in this color instead of the default cobalt fill,
  /// letting callers match a status or a feature's signature hue.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticLabel,
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  key: const Key('gradient_ring_track'),
                  isComplex: true,
                  willChange: false,
                  painter: _GradientRingTrackPainter(
                    strokeWidth: strokeWidth,
                    trackColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .55),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(end: value.clamp(0, 1)),
                duration: reduceMotion ? Duration.zero : AppDurations.slow,
                curve: AppCurves.standard,
                builder: (context, animatedValue, _) => CustomPaint(
                  key: const Key('gradient_ring_animated_arc'),
                  willChange: !reduceMotion,
                  painter: _GradientRingPainter(
                    value: animatedValue,
                    strokeWidth: strokeWidth,
                    color: color,
                  ),
                ),
              ),
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
  });

  final double value;
  final double strokeWidth;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    // Use a solid cobalt fill (or caller-provided color) — no multi-color sweep.
    final fillColor = color ?? AppColors.cobalt;
    final progress = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (value > 0) {
      canvas.drawArc(
        bounds,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      value != oldDelegate.value ||
      strokeWidth != oldDelegate.strokeWidth ||
      color != oldDelegate.color;
}

/// The quiet track behind the arc.
///
/// It used to carry a blurred halo as well; the halo is gone, because a glow
/// around a progress ring is exactly the decoration this design system removes.
/// What remains is a single low-contrast circle.
class _GradientRingTrackPainter extends CustomPainter {
  const _GradientRingTrackPainter({
    required this.strokeWidth,
    required this.trackColor,
  });

  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);
  }

  @override
  bool shouldRepaint(covariant _GradientRingTrackPainter oldDelegate) =>
      strokeWidth != oldDelegate.strokeWidth ||
      trackColor != oldDelegate.trackColor;
}

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    required this.value,
    this.height = 7,
    this.semanticLabel,
    this.color,
    super.key,
  });

  final double value;
  final double height;
  final String? semanticLabel;

  /// Fills the bar with this color instead of the default cobalt,
  /// for status- or feature-tinted progress.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fillColor = color ?? AppColors.cobalt;
    return Semantics(
      label: semanticLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: .22),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : AppDurations.medium,
                    curve: AppCurves.standard,
                    width: constraints.maxWidth * value.clamp(0, 1),
                    color: fillColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
