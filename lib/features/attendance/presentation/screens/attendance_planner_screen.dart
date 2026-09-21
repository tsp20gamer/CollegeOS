import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_planner.dart';
import 'package:college_os/features/attendance/presentation/widgets/attendance_summary_widgets.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendancePlannerScreen extends ConsumerStatefulWidget {
  const AttendancePlannerScreen({super.key});

  @override
  ConsumerState<AttendancePlannerScreen> createState() =>
      _AttendancePlannerScreenState();
}

class _AttendancePlannerScreenState
    extends ConsumerState<AttendancePlannerScreen> {
  int? _subjectId;
  int _plannedPresent = 1;
  int _plannedAbsent = 0;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(attendanceSubjectsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Planner')),
      body: SafeArea(
        child: subjects.when(
          loading: () => const LoadingState(label: 'Preparing planner'),
          error: (error, _) => ErrorState(
            title: 'Could not load attendance',
            message: error.toString(),
            onRetry: () => ref.invalidate(attendanceEngineProvider),
          ),
          data: (values) {
            final available = values
                .where((item) => item.metrics.hasClasses)
                .toList(growable: false);
            if (available.isEmpty) {
              return const EmptyState(
                icon: Icons.calculate_outlined,
                title: 'Nothing to plan yet',
                message: 'Mark at least one class to start a what-if plan.',
              );
            }
            final selected =
                available
                    .where((item) => item.subject.id == _subjectId)
                    .firstOrNull ??
                available.first;
            final plan = AttendancePlannerService.project(
              current: selected.metrics,
              plannedPresent: _plannedPresent,
              plannedAbsent: _plannedAbsent,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  'Explore future classes without changing real attendance.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<int>(
                  key: ValueKey(selected.subject.id),
                  initialValue: selected.subject.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  items: [
                    for (final item in available)
                      DropdownMenuItem(
                        value: item.subject.id,
                        child: Text(
                          item.subject.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _subjectId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _ProjectionCard(plan: plan),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        _CountControl(
                          label: 'Classes attended',
                          icon: Icons.check_circle_outline_rounded,
                          value: _plannedPresent,
                          onChanged: (value) =>
                              setState(() => _plannedPresent = value),
                        ),
                        const Divider(height: AppSpacing.lg),
                        _CountControl(
                          label: 'Classes missed',
                          icon: Icons.cancel_outlined,
                          value: _plannedAbsent,
                          onChanged: (value) =>
                              setState(() => _plannedAbsent = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _OutcomeCard(plan: plan),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _plannedPresent = 1;
                    _plannedAbsent = 0;
                  }),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset plan'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.plan});

  final AttendancePlan plan;

  @override
  Widget build(BuildContext context) {
    final current = plan.current.attendancePercentage ?? 0;
    final projected = plan.projected.attendancePercentage ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _PercentageRing(label: 'Current', value: current),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: _PercentageRing(label: 'Projected', value: projected),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientProgressBar(
              value: projected / 100,
              semanticLabel:
                  'Projected attendance ${projected.toStringAsFixed(1)} percent',
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentageRing extends StatelessWidget {
  const _PercentageRing({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      GradientProgressRing(
        value: value / 100,
        size: 86,
        semanticLabel: '$label attendance ${value.toStringAsFixed(1)}%',
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${value.toStringAsFixed(1)}%',
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(label, style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}

class _CountControl extends StatelessWidget {
  const _CountControl({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      IconButton.outlined(
        tooltip: 'Decrease $label',
        onPressed: value == 0 ? null : () => onChanged(value - 1),
        icon: const Icon(Icons.remove_rounded),
      ),
      Semantics(
        liveRegion: true,
        label: '$label: $value',
        child: SizedBox(
          width: 44,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ),
      IconButton.filledTonal(
        key: ValueKey('planner_increase_$label'),
        tooltip: 'Increase $label',
        onPressed: value >= 50 ? null : () => onChanged(value + 1),
        icon: const Icon(Icons.add_rounded),
      ),
    ],
  );
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.plan});

  final AttendancePlan plan;

  @override
  Widget build(BuildContext context) {
    final projected = plan.projected;
    final change = plan.percentagePointChange;
    final atTarget = projected.isAtOrAboveTarget;
    final message = switch (projected.standing) {
      AttendanceStanding.noClasses => 'Add classes to see a projection.',
      AttendanceStanding.atOrAboveTarget =>
        'You remain at or above ${formatTarget(projected.target)}. ${projected.safeBunks == 0 ? 'The next missed class would be risky.' : 'You could still miss ${projected.safeBunks} ${projected.safeBunks == 1 ? 'class' : 'classes'}.'}',
      AttendanceStanding.belowTarget =>
        'You would need ${projected.classesRequired} consecutive attended ${projected.classesRequired == 1 ? 'class' : 'classes'} to reach ${formatTarget(projected.target)}.',
      AttendanceStanding.unreachable =>
        'A 100% target cannot be recovered after an absence.',
    };
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Card(
        color: atTarget
            ? colors.primaryContainer.withValues(alpha: .35)
            : colors.errorContainer.withValues(alpha: .30),
        child: ListTile(
          minTileHeight: 76,
          leading: Icon(
            atTarget ? Icons.trending_up_rounded : Icons.warning_amber_rounded,
            color: atTarget ? colors.primary : colors.error,
          ),
          title: Text(
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} percentage points',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(message),
        ),
      ),
    );
  }
}
