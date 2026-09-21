import 'package:college_os/core/theme/radius.dart';
import 'package:flutter/material.dart';

abstract final class AppCardStyles {
  static CardThemeData theme(ColorScheme colors) {
    return CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.38)),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }
}
