import 'package:college_os/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

abstract final class AppGradients {
  /// Cobalt solid fill — kept as a gradient type for drop-in compatibility
  /// with widgets that accept a [LinearGradient], but uses a single hue so
  /// it reads as solid rather than multi-color.
  static const primary = LinearGradient(
    colors: [AppColors.cobalt, Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract final class AppGlows {
  /// A restrained, non-neon depth shadow for elevated cobalt elements.
  static List<BoxShadow> primary({double strength = 1}) => [
    BoxShadow(
      color: AppColors.cobalt.withValues(alpha: .12 * strength),
      blurRadius: 16 * strength,
      spreadRadius: -4,
      offset: const Offset(0, 4),
    ),
  ];

  /// No text glow — removed to match the clean, product-quality direction.
  /// Returns an empty list so call sites still compile without changes.
  static List<Shadow> text({double strength = 1}) => const [];
}
