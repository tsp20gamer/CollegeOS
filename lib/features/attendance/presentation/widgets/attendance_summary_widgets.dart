import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:college_os/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';

String formatAttendancePercentage(double? value) =>
    value == null ? '—' : '${value.toStringAsFixed(1)}%';

String formatTarget(double target) => '${(target * 100).toStringAsFixed(0)}%';

String attendanceGuidance(AttendanceMetrics metrics) {
  return switch (metrics.standing) {
    AttendanceStanding.noClasses => 'No classes recorded yet',
    AttendanceStanding.atOrAboveTarget => switch (metrics.safeBunks!) {
      0 => 'At target — attend the next class',
      1 => 'You can miss 1 class',
      final count => 'You can miss $count classes',
    },
    AttendanceStanding.belowTarget => switch (metrics.classesRequired!) {
      1 => 'Attend the next class to reach ${formatTarget(metrics.target)}',
      final count =>
        'Attend next $count classes to reach ${formatTarget(metrics.target)}',
    },
    AttendanceStanding.unreachable =>
      'A ${formatTarget(metrics.target)} target requires perfect attendance',
  };
}

Color attendanceStatusColor(BuildContext context, AttendanceMetrics metrics) {
  final semantic = Theme.of(context).extension<AppSemanticColors>()!;
  return switch (metrics.standing) {
    AttendanceStanding.atOrAboveTarget => semantic.success,
    AttendanceStanding.belowTarget ||
    AttendanceStanding.unreachable => Theme.of(context).colorScheme.error,
    AttendanceStanding.noClasses => semantic.info,
  };
}

class AttendanceProgressRing extends StatelessWidget {
  const AttendanceProgressRing({
    required this.metrics,
    this.size = 72,
    super.key,
  });

  final AttendanceMetrics metrics;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = attendanceStatusColor(context, metrics);
    final targetValue = (metrics.attendancePercentage ?? 0) / 100;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: metrics.attendancePercentage == null
          ? 'No held classes'
          : '${formatAttendancePercentage(metrics.attendancePercentage)} attendance',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GradientProgressRing(
              value: targetValue,
              size: size,
              // Thin and light: the number is the point, the ring is context.
              strokeWidth: size >= 80 ? 5 : 4,
              color: metrics.hasClasses ? color : null,
              child: const SizedBox.shrink(),
            ),
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : AppDurations.fast,
              child: Text(
                metrics.attendancePercentage == null
                    ? '—'
                    : '${metrics.attendancePercentage!.round()}%',
                key: ValueKey(metrics.attendancePercentage?.round()),
                // Plain theme text, not the status colour: the centre of the
                // ring shows the value, and the badge below carries the status.
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceSubjectCard extends StatelessWidget {
  const AttendanceSubjectCard({
    required this.view,
    required this.onTap,
    super.key,
  });

  final SubjectAttendanceResult view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = attendanceStatusColor(context, view.metrics);
    final (statusLabel, statusIcon) = switch (view.metrics.standing) {
      AttendanceStanding.noClasses => (
        'Not started',
        Icons.hourglass_empty_rounded,
      ),
      AttendanceStanding.atOrAboveTarget => (
        'On track',
        Icons.check_circle_rounded,
      ),
      AttendanceStanding.belowTarget => (
        'Below target',
        Icons.trending_down_rounded,
      ),
      AttendanceStanding.unreachable => (
        'Needs correction',
        Icons.error_outline_rounded,
      ),
    };
    return LayoutBuilder(
      builder: (context, constraints) => PremiumSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AttendanceProgressRing(
                  metrics: view.metrics,
                  size: constraints.maxWidth < 350 ? 64 : 72,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.subject.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${view.metrics.presentCount} of ${view.metrics.heldClasses} attended  •  Target ${formatTarget(view.metrics.target)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      StatusBadge(
                        label: statusLabel,
                        icon: statusIcon,
                        foreground: statusColor,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        attendanceGuidance(view.metrics),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIconSize.sm,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GradientProgressBar(
              value: (view.metrics.attendancePercentage ?? 0) / 100,
              color: view.metrics.hasClasses ? statusColor : null,
              semanticLabel: '${view.subject.name} attendance',
            ),
          ],
        ),
      ),
    );
  }
}
