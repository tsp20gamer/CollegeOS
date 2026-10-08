import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.accentColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  /// Tints the icon container toward a feature's signature hue instead of
  /// the shared primary container, so each area's empty state reads as its
  /// own. Both the accent and the container should come from the same
  /// [FeaturePalette].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final containerColor = accentColor == null
        ? colors.primaryContainer
        : Color.alphaBlend(
            accentColor!.withValues(alpha: .16),
            colors.surfaceContainerLow,
          );
    return Semantics(
      container: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: PremiumSurface(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: accentColor ?? colors.onPrimaryContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (action case final action?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
