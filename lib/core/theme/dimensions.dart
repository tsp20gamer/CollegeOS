import 'package:college_os/core/theme/spacing.dart';
import 'package:flutter/widgets.dart';

abstract final class AppIconSize {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 40;
}

abstract final class AppElevation {
  static const double flat = 0;
  static const double raised = 1;
  static const double floating = 6;
}

abstract final class AppLayout {
  static const double compactPhone = 380;
  static const double contentMaxWidth = 720;
  static const double minimumTouchTarget = 48;
  static const double compactCalendarDayExtent = 40;

  /// Height of the bottom navigation bar's own content.
  ///
  /// The bar is laid out flush with the physical bottom edge and paints behind
  /// the system inset itself, so its total footprint on screen is this value
  /// plus [MediaQueryData.padding]'s bottom inset.
  static const double navigationBarHeight = 64;

  /// Bottom padding that keeps scrolling content clear of whatever occupies the
  /// bottom of the screen.
  ///
  /// `Scaffold.extendBody` folds the bottom navigation bar's total height into
  /// `MediaQuery.padding.bottom` for the shell body, while a route pushed above
  /// the shell only sees the system inset. Reading the resolved padding
  /// therefore clears the bar inside the shell and the system bar everywhere
  /// else, without any screen needing to know which case it is in.
  static double scaffoldBottomPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + AppSpacing.md;
  }
}
