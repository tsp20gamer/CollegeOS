import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_planner.dart';
import 'package:college_os/features/attendance/presentation/widgets/attendance_summary_widgets.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// How the planner explores a what-if: abstract class counts for one subject, or
/// real dates the student plans to miss.
enum _PlannerMode { counts, skipDays }

class AttendancePlannerScreen extends ConsumerStatefulWidget {
  const AttendancePlannerScreen({super.key});

  @override
  ConsumerState<AttendancePlannerScreen> createState() =>
      _AttendancePlannerScreenState();
}

class _AttendancePlannerScreenState
    extends ConsumerState<AttendancePlannerScreen> {
  _PlannerMode _mode = _PlannerMode.counts;
  int? _subjectId;
  int _plannedPresent = 1;
  int _plannedAbsent = 0;
  final List<DateTime> _skipDates = [];

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(attendanceSubjectsProvider);
    // Only the skip-days mode reads the timetable, so the class-counts mode
    // never subscribes to it.
    final skipDays = _mode == _PlannerMode.skipDays;
    final AsyncValue<Semester?> semester = skipDays
        ? ref.watch(activeSemesterProvider)
        : const AsyncData(null);
    final AsyncValue<AttendanceEngineSnapshot?> snapshot = skipDays
        ? ref.watch(attendanceEngineProvider)
        : const AsyncData(null);
    final overallTarget = !skipDays
        ? .75
        : ref.watch(collegeSettingsProvider).value?.defaultAttendanceTarget ??
              .75;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Planner')),
      body: SafeArea(
        bottom: false,
        child: subjects.when(
          loading: () => const LoadingState(label: 'Preparing planner'),
          error: (error, _) => ErrorState(
            title: 'Could not load attendance',
            message: error.toString(),
            onRetry: () => ref.invalidate(attendanceEngineProvider),
          ),
          data: (values) {
            if (skipDays && (semester.isLoading || snapshot.isLoading)) {
              return const LoadingState(label: 'Loading your timetable');
            }
            if (skipDays && semester.hasError) {
              return ErrorState(
                title: 'Could not load semester',
                message: semester.error.toString(),
                onRetry: () => ref.invalidate(activeSemesterProvider),
              );
            }
            if (skipDays && snapshot.hasError) {
              return ErrorState(
                title: 'Could not load attendance',
                message: snapshot.error.toString(),
                onRetry: () => ref.invalidate(attendanceEngineProvider),
              );
            }
            final activeSemester = semester.value;
            final engineSnapshot = snapshot.value;
            final skipPlan =
                skipDays &&
                    _skipDates.isNotEmpty &&
                    activeSemester != null &&
                    engineSnapshot != null
                ? AttendancePlannerService.planSkipDays(
                    snapshot: engineSnapshot,
                    semester: activeSemester,
                    dates: _skipDates,
                    subjectResults: values,
                    overallTarget: overallTarget,
                  )
                : null;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppLayout.scaffoldBottomPadding(context),
              ),
              children: [
                Text(
                  _mode == _PlannerMode.counts
                      ? 'Explore one subject\u2019s future classes without changing real attendance.'
                      : 'Choose the days you plan to miss and see what they cost you.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<_PlannerMode>(
                  key: const Key('planner_mode_toggle'),
                  segments: const <ButtonSegment<_PlannerMode>>[
                    ButtonSegment(
                      value: _PlannerMode.counts,
                      icon: Icon(Icons.calculate_outlined),
                      label: Text('Class counts'),
                    ),
                    ButtonSegment(
                      value: _PlannerMode.skipDays,
                      icon: Icon(Icons.event_busy_outlined),
                      label: Text('Skip days'),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _mode = value.single),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (skipDays)
                  ..._skipMode(plan: skipPlan, semester: activeSemester)
                else
                  ..._countsMode(values),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Class counts ─────────────────────────────────────────────────────────

  List<Widget> _countsMode(List<SubjectAttendanceResult> values) {
    final available = values
        .where((item) => item.metrics.hasClasses)
        .toList(growable: false);
    if (available.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.calculate_outlined,
          title: 'Nothing to plan yet',
          message: 'Mark at least one class to start a what-if plan.',
        ),
      ];
    }
    final selected =
        available.where((item) => item.subject.id == _subjectId).firstOrNull ??
        available.first;
    final plan = AttendancePlannerService.project(
      current: selected.metrics,
      plannedPresent: _plannedPresent,
      plannedAbsent: _plannedAbsent,
    );
    return [
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
              child: Text(item.subject.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => setState(() => _subjectId = value),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        'Counts in classes for this subject only.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
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
                onChanged: (value) => setState(() => _plannedPresent = value),
              ),
              const Divider(height: AppSpacing.lg),
              _CountControl(
                label: 'Classes missed',
                icon: Icons.cancel_outlined,
                value: _plannedAbsent,
                onChanged: (value) => setState(() => _plannedAbsent = value),
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
    ];
  }

  // ─── Skip days ────────────────────────────────────────────────────────────

  List<Widget> _skipMode({
    required SkipDayPlan? plan,
    required Semester? semester,
  }) {
    if (semester == null) {
      return const [
        EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'No active semester',
          message: 'Set an active semester in Settings to plan days off.',
        ),
      ];
    }
    return [
      FilledButton.icon(
        key: const Key('planner_add_absent_day'),
        onPressed: () => _pickSkipDay(semester),
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(
          _skipDates.isEmpty ? 'Add a day I will be absent' : 'Add another day',
        ),
      ),
      if (_skipDates.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final date in _skipDates)
              InputChip(
                key: ValueKey('planner_skip_day_${_dayKey(date)}'),
                label: Text(DateFormat('EEE, d MMM').format(date)),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
                onDeleted: () => setState(
                  () =>
                      _skipDates.removeWhere((value) => _sameDate(value, date)),
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      if (plan == null)
        const _PlannerNotice(
          icon: Icons.touch_app_outlined,
          text:
              'Add the days you will miss to see how many classes they cost and where your attendance lands.',
        )
      else ...[
        _SkipImpactCard(plan: plan),
        const SizedBox(height: AppSpacing.md),
        _SkipDayBreakdownCard(plan: plan),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          key: const Key('planner_clear_days'),
          onPressed: () => setState(_skipDates.clear),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Clear days'),
        ),
      ],
    ];
  }

  Future<void> _pickSkipDay(Semester semester) async {
    final start = _dateOnly(semester.startDate);
    final end = _dateOnly(semester.endDate);
    final today = _dateOnly(DateTime.now());
    final initial = today.isBefore(start)
        ? start
        : today.isAfter(end)
        ? end
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: start,
      lastDate: end,
    );
    if (picked == null || !mounted) return;
    final date = _dateOnly(picked);
    setState(() {
      if (_skipDates.any((value) => _sameDate(value, date))) {
        _skipDates.removeWhere((value) => _sameDate(value, date));
      } else {
        _skipDates
          ..add(date)
          ..sort();
      }
    });
  }
}

// ─── Skip day impact ────────────────────────────────────────────────────────

class _SkipImpactCard extends StatelessWidget {
  const _SkipImpactCard({required this.plan});

  final SkipDayPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final overallCurrent = plan.overallCurrent.attendancePercentage ?? 0;
    final overallProjected = plan.overallProjected.attendancePercentage ?? 0;
    final message = _summaryMessage(plan);
    return Semantics(
      liveRegion: true,
      label: message,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.event_busy_outlined, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Attendance after these absences',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PercentageRing(
                      label: 'Overall now',
                      value: overallCurrent,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: _PercentageRing(
                      label: 'After',
                      value: overallProjected,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              GradientProgressBar(
                value: overallProjected / 100,
                semanticLabel:
                    'Overall attendance after planned absences ${overallProjected.toStringAsFixed(1)} percent',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${plan.skippedClassCount} ${plan.skippedClassCount == 1 ? 'class' : 'classes'} missed  \u2022  '
                '${plan.overallPercentagePointChange.toStringAsFixed(1)} pp overall  \u2022  '
                '${plan.overallCurrent.presentCount} of ${plan.overallCurrent.heldClasses} attended so far',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Divider(height: AppSpacing.lg),
              Text(
                'Subject by subject',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (plan.subjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: _PlannerNotice(
                    icon: Icons.info_outline_rounded,
                    text: 'No unmarked classes fall on these days yet.',
                  ),
                )
              else ...[
                for (final impact in plan.subjects)
                  _SkipSubjectRow(impact: impact),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Other subjects are unaffected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _summaryMessage(SkipDayPlan plan) {
  if (!plan.changesAnything) {
    return 'No unmarked classes fall on these days, so your attendance does not change yet.';
  }
  final classes = plan.skippedClassCount;
  final days = plan.contributingDayCount;
  final projected = plan.overallProjected;
  final target = formatTarget(projected.target);
  final standing = projected.isAtOrAboveTarget
      ? 'You would stay at or above $target.'
      : 'You would fall below $target.';
  return 'Missing $classes ${classes == 1 ? 'class' : 'classes'} over '
      '$days ${days == 1 ? 'day' : 'days'} leaves overall attendance at '
      '${formatAttendancePercentage(projected.attendancePercentage)}. '
      '$standing';
}

class _SkipSubjectRow extends StatelessWidget {
  const _SkipSubjectRow({required this.impact});

  final SubjectSkipImpact impact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;
    final current = impact.current;
    final projected = impact.projected;
    final change = impact.percentagePointChange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  impact.subject.shortCode.isEmpty
                      ? impact.subject.name
                      : impact.subject.shortCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${impact.skippedClasses} missed  \u2022  '
                  '${current.presentCount} of ${current.heldClasses} \u2192 '
                  '${projected.presentCount} of ${projected.heldClasses} attended',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatAttendancePercentage(projected.attendancePercentage),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: projected.isAtOrAboveTarget
                      ? semantic.success
                      : colors.error,
                ),
              ),
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} pp',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Skip day breakdown ─────────────────────────────────────────────────────

class _SkipDayBreakdownCard extends StatelessWidget {
  const _SkipDayBreakdownCard({required this.plan});

  final SkipDayPlan plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Classes on your chosen days',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            for (final day in plan.days) ...[
              const SizedBox(height: AppSpacing.xs),
              _SkipDayTile(day: day),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkipDayTile extends StatelessWidget {
  const _SkipDayTile({required this.day});

  final PlannedSkipDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = day.skippableCount == 1 ? 'class' : 'classes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM').format(day.date),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${day.skippableCount} $label',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (day.isOutsideSemester)
          const _PlannerNotice(
            icon: Icons.block_rounded,
            text:
                'This date is outside the active semester, so it costs you nothing.',
          )
        else if (day.isExcluded)
          _PlannerNotice(
            icon: Icons.beach_access_outlined,
            text: day.state == AttendanceDayState.holiday
                ? 'Marked as a holiday \u2014 no classes are counted.'
                : 'College is closed on this date \u2014 no classes are counted.',
          )
        else if (!day.contributes)
          _PlannerNotice(
            icon: Icons.info_outline_rounded,
            text: day.alreadyMarkedCount > 0
                ? 'All ${day.alreadyMarkedCount} classes on this date are already marked.'
                : 'No classes are scheduled for this date.',
          )
        else ...[
          for (final session in day.skippableSessions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxs),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      _formatMinutes(context, session.startTime),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      session.subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (session.subject.shortCode.isNotEmpty)
                    Text(
                      session.subject.shortCode,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          if (day.alreadyMarkedCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '${day.alreadyMarkedCount} already-marked '
                '${day.alreadyMarkedCount == 1 ? 'class' : 'classes'} on this date stay unchanged.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _PlannerNotice extends StatelessWidget {
  const _PlannerNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(text)),
    ],
  );
}

// ─── Class counts widgets ───────────────────────────────────────────────────

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

String _formatMinutes(BuildContext context, int value) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: value ~/ 60, minute: value % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

String _dayKey(DateTime date) =>
    '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
