import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WeeklyAttendanceCard extends ConsumerWidget {
  const WeeklyAttendanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklyAttendanceSummaryProvider);
    if (summary == null) return const SizedBox.shrink();
    final report = summary.current;
    final change = summary.change;
    final theme = Theme.of(context);
    return Card(
      key: const Key('weekly_attendance_summary'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('This week', style: theme.textTheme.titleLarge),
                ),
                Text(
                  report.percentage == null
                      ? '—'
                      : '${report.percentage!.toStringAsFixed(1)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              report.held == 0
                  ? 'No marked classes this week yet.'
                  : '${report.present} present · ${report.absent} missed · ${report.held} held',
            ),
            if (change != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} percentage points vs last week',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (summary.needsAttention.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Below target this week: ${summary.needsAttention.map((row) => row.shortCode.isEmpty ? row.subjectName : row.shortCode).join(', ')}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (report.unmarked > 0)
              TextButton.icon(
                onPressed: () => context.push('/attendance/pending'),
                icon: const Icon(Icons.pending_actions_rounded),
                label: Text('${report.unmarked} unmarked · Review'),
              )
            else
              TextButton(
                onPressed: () => context.go(RoutePaths.attendance),
                child: const Text('View attendance'),
              ),
          ],
        ),
      ),
    );
  }
}
