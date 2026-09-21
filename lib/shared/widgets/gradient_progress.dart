import 'dart:math' as math;

import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/effects.dart';
import 'package:flutter/material.dart';

class GradientProgressRing extends StatelessWidget {
  const GradientProgressRing({
    required this.value,
    required this.child,
    this.size = 72,
    this.strokeWidth = 8,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final Widget child;
  final double size;
  final double strokeWidth;
  final String? semanticLabel;

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
                  key: const Key('gradient_ring_static_glow'),
                  isComplex: true,
                  willChange: false,
                  painter: _GradientRingGlowPainter(
                    value: value.clamp(0, 1),
                    strokeWidth: strokeWidth,
                    trackColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .28),
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
  const _GradientRingPainter({required this.value, required this.strokeWidth});

  final double value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final progress = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.violet, AppColors.blue, AppColors.violet],
        stops: [0, .65, 1],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(bounds)
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
      value != oldDelegate.value || strokeWidth != oldDelegate.strokeWidth;
}

class _GradientRingGlowPainter extends CustomPainter {
  const _GradientRingGlowPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);
    if (value <= 0) return;

    final glow = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.violet.withValues(alpha: .50),
          AppColors.blue.withValues(alpha: .50),
          AppColors.violet.withValues(alpha: .50),
        ],
        stops: const [0, .65, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(bounds, -math.pi / 2, math.pi * 2 * value, false, glow);
  }

  @override
  bool shouldRepaint(covariant _GradientRingGlowPainter oldDelegate) =>
      value != oldDelegate.value ||
      strokeWidth != oldDelegate.strokeWidth ||
      trackColor != oldDelegate.trackColor;
}

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    required this.value,
    this.height = 7,
    this.semanticLabel,
    super.key,
  });

  final double value;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
                  ).colorScheme.outlineVariant.withValues(alpha: .25),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : AppDurations.medium,
                    curve: AppCurves.standard,
                    width: constraints.maxWidth * value.clamp(0, 1),
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                    ),
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
