import 'package:college_os/core/theme/radius.dart';
import 'package:flutter/material.dart';

abstract final class AppCardStyles {
  /// Cards use surface contrast for hierarchy rather than visible borders.
  ///
  /// - Dark: no border; the card color (#161920) separates naturally from
  ///   the scaffold background (#0F1115).
  /// - Light: a very soft shadow + barely-visible outline on white cards
  ///   above the #F8F9FA background.
  static CardThemeData theme(ColorScheme colors, {required bool isDark}) {
    return CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide.none
            : BorderSide(
                color: const Color(0xFF000000).withValues(alpha: 0.06),
              ),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }
}
