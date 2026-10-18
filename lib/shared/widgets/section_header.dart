import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/shared/widgets/icon_pop.dart';
import 'package:flutter/material.dart';

/// How loud a section header is.
enum SectionHeaderVariant {
  /// Large, weighted title for the page's primary sections.
  primary,

  /// Compact chip-style header that groups secondary content without
  /// competing with the primary sections around it.
  secondary,
}

/// Section titles that carry more hierarchy than "icon plus text": primary
/// sections get a tinted icon coin and a large weighted title, secondary ones
/// a small pill icon and a compact title.
///
/// Pass [accent] (usually a feature's signature hue) to tint the icon coin
/// toward that feature instead of the shared primary color.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.variant = SectionHeaderVariant.primary,
    this.icon,
    this.accent,
    this.caption,
    this.action,
    super.key,
  });

  final String title;
  final SectionHeaderVariant variant;
  final IconData? icon;
  final Color? accent;
  final String? caption;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPrimary = variant == SectionHeaderVariant.primary;
    final tint = accent ?? colors.primary;
    final titleStyle =
        (isPrimary ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
            ?.copyWith(
              fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: isPrimary ? -.2 : .15,
              color: isPrimary ? colors.onSurface : colors.onSurfaceVariant,
            );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon case final icon?) ...[
          // The coin pops in as its section arrives, the dock's own
          // rise-and-settle — the icon a row is filed under should greet the
          // row, not simply appear beside it.
          IconPop(
            popOnMount: true,
            fromScale: .72,
            child: Container(
              width: isPrimary ? 34 : 24,
              height: isPrimary ? 34 : 24,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Color.alphaBlend(
                        tint.withValues(alpha: .16),
                        colors.surface,
                      )
                    : tint.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isPrimary ? AppIconSize.sm : 14,
                color: tint,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle, maxLines: 1),
              if (isPrimary)
                if (caption case final caption?)
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
