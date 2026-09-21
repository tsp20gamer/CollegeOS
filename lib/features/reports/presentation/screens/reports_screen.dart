import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/effects.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_forecast.dart';
import 'package:college_os/features/attendance/domain/attendance_insights.dart';
import 'package:college_os/features/reports/application/attendance_analytics_providers.dart';
import 'package:college_os/features/reports/domain/attendance_report.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _AnalyticsScope { month, semester, allTime }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _AnalyticsScope _scope = _AnalyticsScope.month;
  DateTime _reference = DateUtils.dateOnly(DateTime.now());
  int? _semesterId;

  @override
  Widget build(BuildContext context) {
    final semesters = ref.watch(semestersProvider);
    final bundles = ref.watch(allSemesterAttendanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Analytics')),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: semesters.when(
          loading: () => const LoadingState(label: 'Loading semesters'),
          error: (error, _) => ErrorState(
            title: 'Could not load analytics',
            message: error.toString(),
          ),
          data: (semesterRows) {
            if (semesterRows.isEmpty) {
              return const EmptyState(
                icon: Icons.analytics_outlined,
                title: 'No semesters yet',
                message: 'Create a semester before viewing analytics.',
              );
            }
            return bundles.when(
              loading: () => const LoadingState(label: 'Calculating analytics'),
              error: (error, _) => ErrorState(
                title: 'Could not calculate attendance',
                message: error.toString(),
                onRetry: () => ref.invalidate(allSemesterAttendanceProvider),
              ),
              data: (values) => values.isEmpty
                  ? const LoadingState(label: 'Calculating analytics')
                  : _content(values),
            );
          },
        ),
      ),
    );
  }

  Widget _content(List<SemesterAttendanceBundle> source) {
    final bundles = [...source]
      ..sort((a, b) => a.semester.startDate.compareTo(b.semester.startDate));
    final selected =
        bundles.where((item) => item.semester.id == _semesterId).firstOrNull ??
        bundles.where((item) => item.semester.isActive).firstOrNull ??
        bundles.last;
    final now = DateTime.now();
    final report = _reportForScope(bundles, selected, now);
    final previous = _previousReport(bundles, selected, now);
    final trend = _trendForScope(bundles, selected, now);
    final streaks = AttendanceInsightsService.calculate(
      snapshot: selected.snapshot,
      semester: selected.semester,
      asOf: now,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppLayout.floatingDockContentInset + AppSpacing.lg,
      ),
      children: [
        SegmentedButton<_AnalyticsScope>(
          key: const Key('analytics_scope'),
          segments: const [
            ButtonSegment(value: _AnalyticsScope.month, label: Text('Month')),
            ButtonSegment(
              value: _AnalyticsScope.semester,
              label: Text('Semester'),
            ),
            ButtonSegment(
              value: _AnalyticsScope.allTime,
              label: Text('All Time'),
            ),
          ],
          selected: {_scope},
          showSelectedIcon: false,
          onSelectionChanged: (value) => setState(() => _scope = value.single),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_scope != _AnalyticsScope.allTime) ...[
          DropdownButtonFormField<int>(
            key: ValueKey(selected.semester.id),
            initialValue: selected.semester.id,
            decoration: const InputDecoration(
              labelText: 'Semester',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: [
              for (final bundle in bundles)
                DropdownMenuItem(
                  value: bundle.semester.id,
                  child: Text(bundle.semester.name),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              final semester = bundles
                  .firstWhere((item) => item.semester.id == value)
                  .semester;
              setState(() {
                _semesterId = value;
                _reference = _dateInsideSemester(now, semester);
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _PeriodNavigator(
          scope: _scope,
          report: report,
          semester: selected.semester,
          semesterCount: bundles.length,
          onPrevious: _scope == _AnalyticsScope.month
              ? () => _moveMonth(-1)
              : null,
          onNext: _scope == _AnalyticsScope.month ? () => _moveMonth(1) : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _AnalyticsSummary(report: report, previous: previous),
        const SizedBox(height: AppSpacing.md),
        _AttendanceTrend(points: trend),
        const SizedBox(height: AppSpacing.md),
        _InsightsCard(report: report),
        const SizedBox(height: AppSpacing.md),
        _StreakInsightsCard(
          insights: streaks,
          semesterName: selected.semester.name,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Subject performance',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${report.rows.length} subjects',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (report.rows.isEmpty)
          const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No subjects in this period',
            message: 'Subject analytics will appear after subjects are added.',
          )
        else
          for (final row in _orderedRows(report.rows)) ...[
            _SubjectAnalyticsCard(
              row: row,
              showSemester: _scope == _AnalyticsScope.allTime,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  AttendanceReportData _reportForScope(
    List<SemesterAttendanceBundle> bundles,
    SemesterAttendanceBundle selected,
    DateTime now,
  ) => switch (_scope) {
    _AnalyticsScope.month => _build(
      selected,
      AttendanceReportService.monthContaining(_reference),
      now,
    ),
    _AnalyticsScope.semester => _build(selected, (
      start: selected.semester.startDate,
      end: selected.semester.endDate,
    ), now),
    _AnalyticsScope.allTime => AttendanceReportService.combine([
      for (final bundle in bundles)
        _build(bundle, (
          start: bundle.semester.startDate,
          end: bundle.semester.endDate,
        ), now),
    ]),
  };

  AttendanceReportData? _previousReport(
    List<SemesterAttendanceBundle> bundles,
    SemesterAttendanceBundle selected,
    DateTime now,
  ) => switch (_scope) {
    _AnalyticsScope.month => _build(
      selected,
      AttendanceReportService.monthContaining(
        DateTime(_reference.year, _reference.month - 1),
      ),
      now,
    ),
    _AnalyticsScope.semester => switch (bundles.indexOf(selected)) {
      > 0 => _build(bundles[bundles.indexOf(selected) - 1], (
        start: bundles[bundles.indexOf(selected) - 1].semester.startDate,
        end: bundles[bundles.indexOf(selected) - 1].semester.endDate,
      ), now),
      _ => null,
    },
    _AnalyticsScope.allTime => null,
  };

  List<_TrendPoint> _trendForScope(
    List<SemesterAttendanceBundle> bundles,
    SemesterAttendanceBundle selected,
    DateTime now,
  ) {
    if (_scope == _AnalyticsScope.allTime) {
      return [
        for (final bundle in bundles)
          _TrendPoint(
            label: 'S${bundle.semester.semesterNumber}',
            report: _build(bundle, (
              start: bundle.semester.startDate,
              end: bundle.semester.endDate,
            ), now),
          ),
      ];
    }
    if (_scope == _AnalyticsScope.semester) {
      final result = <_TrendPoint>[];
      var month = DateTime(
        selected.semester.startDate.year,
        selected.semester.startDate.month,
      );
      final last = DateTime(
        selected.semester.endDate.year,
        selected.semester.endDate.month,
      );
      while (!month.isAfter(last)) {
        result.add(
          _TrendPoint(
            label: DateFormat.MMM().format(month),
            report: _build(
              selected,
              AttendanceReportService.monthContaining(month),
              now,
            ),
          ),
        );
        month = DateTime(month.year, month.month + 1);
      }
      return result;
    }
    final month = AttendanceReportService.monthContaining(_reference);
    final result = <_TrendPoint>[];
    var start = month.start;
    var week = 1;
    while (!start.isAfter(month.end)) {
      final end = start.add(const Duration(days: 6));
      result.add(
        _TrendPoint(
          label: 'W$week',
          report: _build(selected, (
            start: start,
            end: end.isAfter(month.end) ? month.end : end,
          ), now),
        ),
      );
      start = start.add(const Duration(days: 7));
      week++;
    }
    return result;
  }

  AttendanceReportData _build(
    SemesterAttendanceBundle bundle,
    ({DateTime start, DateTime end}) range,
    DateTime asOf,
  ) => AttendanceReportService.build(
    snapshot: bundle.snapshot,
    semester: bundle.semester,
    startDate: range.start,
    endDate: range.end,
    asOf: asOf,
  );

  void _moveMonth(int direction) => setState(() {
    _reference = DateTime(_reference.year, _reference.month + direction);
  });
}

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.scope,
    required this.report,
    required this.semester,
    required this.semesterCount,
    required this.onPrevious,
    required this.onNext,
  });

  final _AnalyticsScope scope;
  final AttendanceReportData report;
  final Semester semester;
  final int semesterCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final label = switch (scope) {
      _AnalyticsScope.month => DateFormat.yMMMM().format(report.startDate),
      _AnalyticsScope.semester =>
        '${DateFormat.MMMd().format(semester.startDate)} – ${DateFormat.yMMMd().format(semester.endDate)}',
      _AnalyticsScope.allTime =>
        '$semesterCount ${semesterCount == 1 ? 'semester' : 'semesters'} · ${DateFormat.yMMMd().format(report.startDate)} – ${DateFormat.yMMMd().format(report.endDate)}',
    };
    return Row(
      children: [
        if (onPrevious != null)
          IconButton(
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (onNext != null)
          IconButton(
            tooltip: 'Next month',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
      ],
    );
  }
}

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({required this.report, required this.previous});

  final AttendanceReportData report;
  final AttendanceReportData? previous;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = report.percentage;
    final previousPercentage = previous?.percentage;
    final difference = percentage == null || previousPercentage == null
        ? null
        : percentage - previousPercentage;
    return Card(
      key: const Key('analytics_summary_card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final ringSize = constraints.maxWidth < 310 ? 112.0 : 120.0;
                return Row(
                  children: [
                    GradientProgressRing(
                      key: const Key('analytics_overall_ring'),
                      value: (percentage ?? 0) / 100,
                      size: ringSize,
                      strokeWidth: 11,
                      semanticLabel: percentage == null
                          ? 'No overall attendance percentage'
                          : '${percentage.toStringAsFixed(1)}% overall attendance',
                      child: Text(
                        percentage == null
                            ? '—'
                            : '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w900,
                              shadows: AppGlows.text(strength: .9),
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  shadows: AppGlows.text(strength: .40),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${report.held} held classes',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          if (difference != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _ComparisonBadge(difference: difference),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _CompactMetric(
                    value: report.present,
                    label: 'Present',
                    icon: Icons.check_circle_outline_rounded,
                    color: Theme.of(
                      context,
                    ).extension<AppSemanticColors>()!.success,
                  ),
                ),
                Expanded(
                  child: _CompactMetric(
                    value: report.absent,
                    label: 'Absent',
                    icon: Icons.cancel_outlined,
                    color: colors.error,
                  ),
                ),
                Expanded(
                  child: _CompactMetric(
                    value: report.unmarked,
                    label: 'Unmarked',
                    icon: Icons.pending_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${report.cancelled} cancelled  •  ${report.rows.length} subjects',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.difference});

  final double difference;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final positive = difference >= 0;
    final color = positive
        ? Theme.of(context).extension<AppSemanticColors>()!.success
        : colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${positive ? '+' : ''}${difference.toStringAsFixed(1)} pts vs previous',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $label',
    child: Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

final class _TrendPoint {
  const _TrendPoint({required this.label, required this.report});
  final String label;
  final AttendanceReportData report;
}

class _AttendanceTrend extends StatelessWidget {
  const _AttendanceTrend({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('analytics_trend_card'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 144,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final point in points) _TrendBar(point: point),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.point});

  final _TrendPoint point;

  @override
  Widget build(BuildContext context) {
    final percentage = point.report.percentage;
    final normalized = ((percentage ?? 0) / 100).clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      key: Key('analytics_trend_bar_${point.label}'),
      width: 58,
      child: Column(
        children: [
          Text(
            percentage == null ? '—' : '${percentage.round()}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: percentage == null ? null : AppColors.blue,
              fontWeight: FontWeight.w800,
              shadows: percentage == null ? null : AppGlows.text(strength: .45),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppDurations.medium,
                curve: AppCurves.standard,
                width: 36,
                height: percentage == null ? 8 : 16 + (68 * normalized),
                decoration: BoxDecoration(
                  gradient: percentage == null ? null : AppGradients.primary,
                  color: percentage == null
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: percentage == null
                      ? null
                      : AppGlows.primary(strength: .62),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            point.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.report});

  final AttendanceReportData report;

  @override
  Widget build(BuildContext context) {
    final heldRows = report.rows.where((row) => row.held > 0).toList();
    if (heldRows.isEmpty) {
      return const EmptyState(
        icon: Icons.insights_outlined,
        title: 'No attendance insights yet',
        message: 'Mark classes to unlock performance insights.',
      );
    }
    heldRows.sort((a, b) => a.percentage!.compareTo(b.percentage!));
    final lowest = heldRows.first;
    final best = heldRows.last;
    final atRisk = heldRows.where((row) {
      final metrics = AttendanceCalculator.calculate(
        presentCount: row.present,
        absentCount: row.absent,
        cancelledCount: row.cancelled,
        target: row.target,
      );
      return AttendanceForecastService.calculate(metrics).needsAttention;
    }).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick insights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            _InsightRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Strongest',
              value:
                  '${best.subjectName} · ${best.percentage!.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: AppSpacing.xs),
            _InsightRow(
              icon: Icons.trending_down_rounded,
              label: 'Needs attention',
              value:
                  '${lowest.subjectName} · ${lowest.percentage!.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: AppSpacing.xs),
            _InsightRow(
              icon: Icons.monitor_heart_outlined,
              label: 'At risk',
              value: '$atRisk ${atRisk == 1 ? 'subject' : 'subjects'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakInsightsCard extends StatelessWidget {
  const _StreakInsightsCard({
    required this.insights,
    required this.semesterName,
  });

  final AttendanceStreakInsights insights;
  final String semesterName;

  @override
  Widget build(BuildContext context) {
    if (!insights.hasData) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label:
          'Attendance streaks for $semesterName. Current present streak ${insights.currentPresentStreak}. Longest present streak ${insights.longestPresentStreak}. Perfect attendance days ${insights.perfectDays}.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Streaks • $semesterName',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _CompactMetric(
                      value: insights.currentPresentStreak,
                      label: 'Current streak',
                      icon: Icons.local_fire_department_outlined,
                      color: colors.primary,
                    ),
                  ),
                  Expanded(
                    child: _CompactMetric(
                      value: insights.longestPresentStreak,
                      label: 'Longest streak',
                      icon: Icons.emoji_events_outlined,
                      color: colors.secondary,
                    ),
                  ),
                  Expanded(
                    child: _CompactMetric(
                      value: insights.perfectDays,
                      label: 'Perfect days',
                      icon: Icons.calendar_month_outlined,
                      color: colors.tertiary,
                    ),
                  ),
                ],
              ),
              if (insights.bestSubjectName != null) ...[
                const Divider(height: AppSpacing.lg),
                _InsightRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Best streak',
                  value:
                      '${insights.bestSubjectName} · ${insights.bestSubjectStreak} classes',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SubjectAnalyticsCard extends StatelessWidget {
  const _SubjectAnalyticsCard({required this.row, required this.showSemester});

  final SubjectAttendanceReportRow row;
  final bool showSemester;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final percentage = row.percentage;
    final below = percentage != null && percentage < row.target * 100;
    final statusColor = below ? colors.error : semantic.success;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
                        row.subjectName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          if (row.shortCode.isNotEmpty) row.shortCode,
                          if (showSemester) row.semesterName,
                          'Target ${(row.target * 100).toStringAsFixed(0)}%',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  percentage == null
                      ? '—'
                      : '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: percentage == null
                        ? colors.onSurfaceVariant
                        : statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GradientProgressBar(
              value: (percentage ?? 0) / 100,
              semanticLabel: '${row.subjectName} attendance',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${row.present} present  •  ${row.absent} absent',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (row.unmarked > 0)
                  Text(
                    '${row.unmarked} unmarked',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<SubjectAttendanceReportRow> _orderedRows(
  List<SubjectAttendanceReportRow> rows,
) => [...rows]
  ..sort((a, b) {
    if (a.percentage == null && b.percentage == null) {
      return a.subjectName.compareTo(b.subjectName);
    }
    if (a.percentage == null) return 1;
    if (b.percentage == null) return -1;
    return a.percentage!.compareTo(b.percentage!);
  });

DateTime _dateInsideSemester(DateTime value, Semester semester) {
  final date = DateUtils.dateOnly(value);
  if (date.isBefore(semester.startDate)) return semester.startDate;
  if (date.isAfter(semester.endDate)) return semester.endDate;
  return date;
}
