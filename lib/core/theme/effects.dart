import 'package:college_os/core/theme/color_tokens.dart';
import 'package:flutter/material.dart';

abstract final class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.violet, AppColors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient subtle(Brightness brightness) => LinearGradient(
    colors: [
      AppColors.violet.withValues(
        alpha: brightness == Brightness.dark ? .20 : .11,
      ),
      AppColors.blue.withValues(
        alpha: brightness == Brightness.dark ? .12 : .07,
      ),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract final class AppGlows {
  static List<BoxShadow> primary({double strength = 1}) => [
    BoxShadow(
      color: AppColors.violet.withValues(alpha: .18 * strength),
      blurRadius: 18 * strength,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: AppColors.blue.withValues(alpha: .10 * strength),
      blurRadius: 24 * strength,
      spreadRadius: -6,
    ),
  ];

  static List<Shadow> text({double strength = 1}) => [
    Shadow(
      color: AppColors.violet.withValues(alpha: .34 * strength),
      blurRadius: 10 * strength,
    ),
    Shadow(
      color: AppColors.blue.withValues(alpha: .18 * strength),
      blurRadius: 16 * strength,
    ),
  ];

  /// A restrained glow for small subject-colour accents such as timetable
  /// rails. Keeping this here gives every subject the same visual treatment
  /// without scattering shadow values through feature widgets.
  static List<BoxShadow> subjectAccent(
    Color color, {
    required Brightness brightness,
  }) {
    final glowColor = brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, .12)!
        : color;
    return [
      BoxShadow(
        color: glowColor.withValues(
          alpha: brightness == Brightness.dark ? .32 : .18,
        ),
        blurRadius: 6,
      ),
      BoxShadow(
        color: glowColor.withValues(
          alpha: brightness == Brightness.dark ? .14 : .07,
        ),
        blurRadius: 14,
        spreadRadius: -3,
      ),
    ];
  }
}
