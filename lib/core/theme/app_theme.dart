import 'package:college_os/core/theme/card_styles.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/page_transitions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/core/theme/system_ui_style.dart';
import 'package:college_os/core/theme/typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseColors = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final colors = baseColors.copyWith(
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceContainerLowest: isDark
          ? AppColors.darkSurfaceLowest
          : AppColors.lightSurfaceLowest,
      surfaceContainerLow: isDark
          ? AppColors.darkSurfaceLow
          : AppColors.lightSurfaceLow,
      surfaceContainer: isDark
          ? AppColors.darkSurfaceLow
          : AppColors.lightSurfaceLow,
      surfaceContainerHigh: isDark
          ? AppColors.darkSurfaceHigh
          : AppColors.lightSurfaceHigh,
      surfaceContainerHighest: isDark
          ? const Color(0xFF252830)
          : const Color(0xFFE5E7EB),
      primary: AppColors.cobalt,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF1E3A5F)
          : const Color(0xFFDBEAFE),
      onPrimaryContainer: isDark
          ? const Color(0xFFBFDBFE)
          : const Color(0xFF1E3A5F),
      secondary: AppColors.cobalt,
      // Quiet outlines — rely on surface contrast, not heavy borders.
      outline: isDark ? const Color(0xFF2E3138) : const Color(0xFFD1D5DB),
      outlineVariant: isDark
          ? const Color(0xFF252830)
          : const Color(0xFFE5E7EB),
    );
    final textTheme = AppTypography.textTheme(colors.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      cardTheme: AppCardStyles.theme(colors, isDark: isDark),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [
        isDark ? AppSemanticColors.dark : AppSemanticColors.light,
        isDark ? FeatureColors.dark : FeatureColors.light,
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: CollegePageTransitionsBuilder()},
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        systemOverlayStyle: AppSystemUiStyle.forBrightness(brightness),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          // No glow — clean, product-quality typography.
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.darkSurfaceLow
            : AppColors.lightSurfaceLowest,
        indicatorColor: colors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppLayout.minimumTouchTarget,
            AppLayout.minimumTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: BorderSide(
            color: isDark
                ? colors.outline
                : colors.outline.withValues(alpha: .7),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceLow
            : AppColors.lightSurfaceLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: isDark ? colors.outlineVariant : colors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        helperStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppLayout.minimumTouchTarget),
          iconSize: AppIconSize.md,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.raised,
        focusElevation: AppElevation.raised,
        hoverElevation: AppElevation.raised,
        highlightElevation: AppElevation.raised,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceLow
            : AppColors.lightSurfaceLowest,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: isDark
            ? AppColors.darkSurfaceLow
            : AppColors.lightSurfaceLowest,
        modalBarrierColor: Colors.black.withValues(alpha: isDark ? .60 : .40),
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: AppElevation.floating,
        backgroundColor: isDark
            ? AppColors.darkSurfaceLow
            : AppColors.lightSurfaceLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        selectedColor: colors.primaryContainer,
        // No border — surface contrast defines chip boundary.
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        labelStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 42)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.primaryContainer
                : colors.surfaceContainerLowest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colors.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF252830)
            : const Color(0xFF1F2937),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        circularTrackColor: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : colors.outline,
        ),
      ),
      dividerTheme: DividerThemeData(
        // Barely-there separators: rows are grouped by a whisper of a line, not
        // an outline. Dark is white/5, light an extremely subtle neutral.
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        space: 1,
      ),
    );
  }
}
