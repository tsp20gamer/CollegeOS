import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:flutter/material.dart';

class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Dark: no border — the card color (#161920) contrasts naturally with
    // the scaffold background (#0F1115).
    // Light: subtle hairline to separate white card from #F8F9FA background.
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: borderColor != null
          ? BorderSide(color: borderColor!)
          : isDark
          ? BorderSide.none
          : BorderSide(color: const Color(0xFF000000).withValues(alpha: .06)),
    );
    final content = Padding(padding: padding, child: child);
    final surface = Material(
      color: color ?? colors.surfaceContainerLow,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, customBorder: shape, child: content),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: _depthShadows(context),
        ),
        // Tappable cards press in under the finger and spring back, matching
        // the dock and every other pressable surface in the app. The shrink
        // stays shallow: a card is a page of information, not an icon.
        child: onTap == null
            ? surface
            : PressScale(pressedScale: .985, child: surface),
      ),
    );
  }

  /// Minimal depth: a single neutral shadow for light mode, slightly deeper
  /// for dark mode to separate card layers cleanly.
  List<BoxShadow> _depthShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: .20),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    // Light mode: soft shadow matching the ~0 4px 20px rgba(0,0,0,0.04) spec.
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: .04),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
