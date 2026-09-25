import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PendingAttendanceScreen extends ConsumerWidget {
  const PendingAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider).value;
    final groups = ref.watch(pendingAttendanceGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Attendance')),
      body: SafeArea(
        bottom: false,
        child: groups.when(
          loading: () => const LoadingState(label: 'Finding unmarked classes'),
          error: (error, _) => ErrorState(
            title: 'Could not load pending attendance',
            message: error.toString(),
            onRetry: () => ref.invalidate(attendanceEngineProvider),
          ),
          data: (items) {
            if (semester == null || items.isEmpty) {
              return const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Attendance is up to date',
                message: 'There are no completed classes waiting for review.',
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppLayout.scaffoldBottomPadding(context),
              ),
              children: [
                _PendingSummary(
                  classCount: items.fold<int>(
                    0,
                    (sum, item) => sum + item.sessions.length,
                  ),
                  dayCount: items.length,
                  oldestDate: items.first.date,
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final group in items) ...[
                  _PendingDayCard(group: group, semesterId: semester.id),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingSummary extends StatelessWidget {
  const _PendingSummary({
    required this.classCount,
    required this.dayCount,
    required this.oldestDate,
  });

  final int classCount;
  final int dayCount;
  final DateTime oldestDate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label:
          '$classCount unmarked classes across $dayCount days. Oldest is ${DateFormat.yMMMMd().format(oldestDate)}.',
      child: Card(
        color: colors.primaryContainer.withValues(alpha: .32),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pending_actions_rounded, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '$classCount classes need attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$dayCount ${dayCount == 1 ? 'day' : 'days'} • Oldest ${DateFormat('d MMM').format(oldestDate)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Only completed classes appear here. Unmarked classes are never silently treated as absent.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingDayCard extends ConsumerWidget {
  const _PendingDayCard({required this.group, required this.semesterId});

  final PendingAttendanceGroup group;
  final int semesterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(group.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${group.sessions.length} unmarked ${group.sessions.length == 1 ? 'class' : 'classes'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      _markGroup(context, ref, ClassAttendanceStatus.present),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('All present'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmAllAbsent(context, ref),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('All absent'),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          for (final session in group.sessions) ...[
            _PendingSessionTile(session: session, semesterId: semesterId),
            if (session != group.sessions.last)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    ),
  );

  Future<void> _markGroup(
    BuildContext context,
    WidgetRef ref,
    ClassAttendanceStatus status,
  ) async {
    final success = await ref
        .read(attendanceCommandProvider.notifier)
        .markPendingGroup(group, semesterId, status);
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not update the day.')));
  }

  Future<void> _confirmAllAbsent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark this day absent?'),
        content: Text(
          'All ${group.sessions.length} unmarked classes on ${DateFormat('d MMMM').format(group.date)} will be marked absent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark absent'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _markGroup(context, ref, ClassAttendanceStatus.absent);
    }
  }
}

class _PendingSessionTile extends ConsumerWidget {
  const _PendingSessionTile({required this.session, required this.semesterId});

  final ProjectedClassSession session;
  final int semesterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    container: true,
    label:
        '${session.subject.name}, ${_formatMinutes(context, session.startTime)}, attendance unmarked',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            _formatMinutes(context, session.startTime),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.subject.name, maxLines: 2),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Present'),
                    onPressed: () =>
                        _mark(context, ref, ClassAttendanceStatus.present),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Absent'),
                    onPressed: () =>
                        _mark(context, ref, ClassAttendanceStatus.absent),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.remove_rounded, size: 17),
                    label: const Text('Cancelled'),
                    onPressed: () =>
                        _mark(context, ref, ClassAttendanceStatus.cancelled),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _mark(
    BuildContext context,
    WidgetRef ref,
    ClassAttendanceStatus status,
  ) async {
    final success = await ref
        .read(attendanceCommandProvider.notifier)
        .markSession(session, semesterId, status);
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not update attendance.')),
    );
  }
}

String _formatMinutes(BuildContext context, int value) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: value ~/ 60, minute: value % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
