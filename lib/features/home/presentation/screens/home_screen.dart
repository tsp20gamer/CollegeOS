import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/presentation/widgets/weekly_attendance_card.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_forecast.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/home/application/home_providers.dart';
import 'package:college_os/features/home/domain/home_dashboard_service.dart';
import 'package:college_os/features/notes/presentation/widgets/note_editor_sheet.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:college_os/shared/widgets/status_badge.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:college_os/shared/widgets/section_header.dart';
import 'package:college_os/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // One release check per launch, after the first frame so the dashboard is
    // painted first. The check is silent unless a newer build exists, so it can
    // never turn opening the app into a wall of dialogs — and it needs no
    // network to leave the rest of the screen working.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      UpdateService.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(localMinuteProvider).value ?? DateTime.now();
    final settings = ref.watch(collegeSettingsProvider);
    final semester = ref.watch(activeSemesterProvider);
    final next = ref.watch(nextClassProvider);
    final todayAttendance = ref.watch(attendanceDayProvider(now));
    final attendance = ref.watch(attendanceSubjectsProvider);
    final pending = ref.watch(pendingAttendanceProvider);
    final tasks = ref.watch(homeTasksProvider);
    final exams = ref.watch(homeExamsProvider);
    final subjects = ref.watch(activeSemesterSubjectsProvider);
    final features = Theme.of(context).extension<FeatureColors>()!;

    return AppScaffold(
      title: _greeting(now, settings.value?.studentName),
      subtitle: DateFormat('EEEE, d MMMM').format(now),
      showSearchAction: true,
      showSettingsAction: true,
      child: Column(
        key: const Key('home_dashboard_ready'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (semester.isLoading)
            const LoadingState(label: 'Loading your dashboard')
          else if (semester.hasError)
            ErrorState(
              title: 'Could not load your dashboard',
              message: semester.error.toString(),
            )
          else if (semester.value == null)
            const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No active semester',
              message: 'Make a semester active to build your daily dashboard.',
            )
          else ...[
            // The day's main event, on the roomiest surface of the page. Its
            // own status badge says what it is, so no section header competes
            // with it.
            _AsyncSection<NextClassResult>(
              value: next,
              loadingLabel: 'Finding your next class',
              builder: (result) => _NextClassCard(
                result: result,
                now: now,
                attendanceDay: todayAttendance.value,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: "Today's classes",
              icon: Icons.view_agenda_outlined,
              accent: features.timetable.accent,
              action: TextButton(
                onPressed: () => context.go(RoutePaths.timetable),
                child: const Text('Full timetable'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TodaySchedule(
              day: todayAttendance,
              semesterId: semester.value!.id,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
              title: 'Quick actions',
              icon: Icons.bolt_rounded,
              variant: SectionHeaderVariant.secondary,
            ),
            const SizedBox(height: AppSpacing.xs),
            const _QuickActions(),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
              title: 'Upcoming',
              icon: Icons.upcoming_rounded,
              variant: SectionHeaderVariant.secondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            _UpcomingSection(
              tasks: tasks,
              exams: exams,
              subjects: subjects.value ?? const [],
              today: now,
            ),
            // Supporting detail: the numbers behind the day, kept one step
            // quieter than the schedule the student acts on.
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Overall attendance',
              icon: Icons.insights_rounded,
              accent: features.attendance.accent,
              variant: SectionHeaderVariant.secondary,
              action: TextButton(
                onPressed: () => context.go(RoutePaths.attendance),
                child: const Text('View details'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _AsyncSection<List<SubjectAttendanceResult>>(
              value: attendance,
              loadingLabel: 'Calculating attendance',
              builder: (items) => _AttendanceOverview(
                subjects: items,
                pending: pending.value ?? 0,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const WeeklyAttendanceCard(),
          ],
        ],
      ),
    );
  }
}

String _greeting(DateTime now, String? studentName) {
  final greeting = now.hour < 12
      ? 'Good morning'
      : now.hour < 17
      ? 'Good afternoon'
      : 'Good evening';
  final name = studentName?.trim() ?? '';
  return name.isEmpty ? greeting : '$greeting, $name';
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({
    required this.value,
    required this.loadingLabel,
    required this.builder,
  });

  final AsyncValue<T> value;
  final String loadingLabel;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => LoadingState(label: loadingLabel),
    error: (error, _) => ErrorState(
      title: 'This section is unavailable',
      message: error.toString(),
    ),
    data: (data) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(key: ValueKey(data.hashCode), child: builder(data)),
    ),
  );
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({
    required this.result,
    required this.now,
    required this.attendanceDay,
  });

  final NextClassResult result;
  final DateTime now;
  final AttendanceDay? attendanceDay;

  @override
  Widget build(BuildContext context) {
    final excluded =
        attendanceDay?.state == AttendanceDayState.holiday ||
        attendanceDay?.state == AttendanceDayState.collegeClosed;
    if (excluded) {
      final holiday = attendanceDay!.state == AttendanceDayState.holiday;
      return PremiumSurface(
        color: _heroLift(context),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              holiday ? Icons.beach_access_rounded : Icons.event_busy_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holiday ? 'Holiday' : 'College closed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    attendanceDay!.override?.note.isNotEmpty == true
                        ? attendanceDay!.override!.note
                        : 'No classes or attendance are scheduled today.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final current = result.currentClass;
    final next = result.nextClass;
    final item = current ?? (result.nextIsToday ? next : null);
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    if (item == null) {
      final finished = next != null;
      return PremiumSurface(
        color: _heroLift(context),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              finished
                  ? Icons.free_breakfast_rounded
                  : Icons.event_available_rounded,
              color: finished ? semantic.success : colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finished ? 'All done for today' : 'No upcoming classes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _nextUpMessage(context, result, now),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final entry = item.entry;
    final room = entry.room.isNotEmpty ? entry.room : item.subject.room;
    return PremiumSurface(
      // The hero earns its prominence from a roomier surface a step above the
      // cards around it — not from a gradient, border or glow.
      color: _heroLift(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: StatusBadge(
                  label: current != null ? 'HAPPENING NOW' : 'UP NEXT',
                  icon: current != null
                      ? Icons.play_circle_rounded
                      : Icons.schedule_rounded,
                  foreground: current != null
                      ? semantic.success
                      : colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '${_time(context, entry.startTime)}–${_time(context, entry.endTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.subject.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (room.isNotEmpty) room,
              if (item.subject.professor.isNotEmpty) item.subject.professor,
            ].join('  •  '),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: const Text('Add note'),
                onPressed: () => NoteEditorSheet.show(
                  context,
                  subjectId: item.subject.id,
                  semesterId: item.subject.semesterId,
                  subjectName: item.subject.name,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.notes_rounded, size: 18),
                label: const Text('View notes'),
                onPressed: () => context.push(
                  RoutePaths.subjectNotes.replaceFirst(
                    ':subjectId',
                    '${item.subject.id}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodaySchedule extends ConsumerWidget {
  const _TodaySchedule({required this.day, required this.semesterId});

  final AsyncValue<AttendanceDay?> day;
  final int semesterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (day.isLoading) {
      return const LoadingState(label: "Loading today's classes");
    }
    if (day.hasError) {
      return ErrorState(
        title: "Could not load today's classes",
        message: '${day.error}',
      );
    }
    final value = day.value;
    if (value == null || value.sessions.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_rounded,
        title: 'No classes today',
        message:
            'Your day is clear. The weekly timetable is still one tap away.',
      );
    }
    final theme = Theme.of(context);
    return PremiumSurface(
      // The whole day lives in one surface: classes are rows under a single
      // heading, separated by a hairline instead of each owning a card.
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xxs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${value.sessions.length} '
                    '${value.sessions.length == 1 ? 'class' : 'classes'} '
                    'today',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // A short label keeps the action beside the count on a compact
                // phone; the tooltip carries the full wording.
                Tooltip(
                  message: 'Mark all present',
                  child: TextButton.icon(
                    key: const Key('home_mark_all_present'),
                    onPressed: value.override == null
                        ? () => ref
                              .read(attendanceCommandProvider.notifier)
                              .markWholeDay(
                                value,
                                semesterId,
                                ClassAttendanceStatus.present,
                              )
                        : null,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Mark all'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var index = 0; index < value.sessions.length; index++) ...[
            _TodayClassRow(
              session: value.sessions[index],
              semesterId: semesterId,
            ),
            if (index != value.sessions.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }
}

/// One class in today's single surface.
///
/// Time, subject and room carry the hierarchy through spacing and weight; the
/// row has no card, no colour rail and no shadow of its own.
class _TodayClassRow extends ConsumerWidget {
  const _TodayClassRow({required this.session, required this.semesterId});

  final ProjectedClassSession session;
  final int semesterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final meta = [
      if (session.subject.room.trim().isNotEmpty) session.subject.room,
      if (session.subject.professor.trim().isNotEmpty)
        session.subject.professor,
    ].join('  •  ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _time(context, session.startTime),
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _time(context, session.endTime),
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _AttendanceStatusMenu(
            status: session.status,
            onSelected: (status) => ref
                .read(attendanceCommandProvider.notifier)
                .markSession(session, semesterId, status),
          ),
        ],
      ),
    );
  }
}

/// The row's attendance control: a compact status pill that opens the marking
/// menu, so the state of the class is readable at a glance instead of hidden
/// behind an icon.
class _AttendanceStatusMenu extends StatelessWidget {
  const _AttendanceStatusMenu({required this.status, required this.onSelected});

  final ClassAttendanceStatus status;
  final ValueChanged<ClassAttendanceStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;
    final (icon, color, label) = switch (status) {
      ClassAttendanceStatus.present => (
        Icons.check_rounded,
        semantic.success,
        'Present',
      ),
      ClassAttendanceStatus.absent => (
        Icons.close_rounded,
        colors.error,
        'Absent',
      ),
      ClassAttendanceStatus.cancelled => (
        Icons.remove_rounded,
        colors.onSurfaceVariant,
        'Cancelled',
      ),
      ClassAttendanceStatus.unmarked => (
        Icons.circle_outlined,
        colors.onSurfaceVariant,
        'Unmarked',
      ),
    };
    return PopupMenuButton<ClassAttendanceStatus>(
      tooltip: 'Mark this class',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ClassAttendanceStatus.present,
          child: Text('✓ Present'),
        ),
        PopupMenuItem(
          value: ClassAttendanceStatus.absent,
          child: Text('✕ Absent'),
        ),
        PopupMenuItem(
          value: ClassAttendanceStatus.cancelled,
          child: Text('– Cancelled'),
        ),
      ],
      child: Semantics(
        key: Key('home_attendance_${status.name}'),
        button: true,
        label: '$label. Tap to change.',
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 108),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceOverview extends StatelessWidget {
  const _AttendanceOverview({required this.subjects, required this.pending});

  final List<SubjectAttendanceResult> subjects;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final held = subjects.fold<int>(
      0,
      (sum, item) => sum + item.metrics.heldClasses,
    );
    final present = subjects.fold<int>(
      0,
      (sum, item) => sum + item.metrics.presentCount,
    );
    final atRisk =
        AttendanceForecastService.attentionFirst(
              subjects,
              (item) => item.metrics,
            )
            .where(
              (item) => AttendanceForecastService.calculate(
                item.metrics,
              ).needsAttention,
            )
            .toList(growable: false);
    if (held == 0) {
      return const EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'No attendance data yet',
        message:
            'Mark scheduled classes from the attendance Calendar or Classes view.',
      );
    }
    final absent = held - present;
    final percentage = present / held * 100;
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    // Green when every subject is on target, red when one is already below,
    // amber when the risk is only one missed class away.
    final standingColor = atRisk.isEmpty
        ? semantic.success
        : atRisk.any(
            (item) => switch (AttendanceForecastService.calculate(
              item.metrics,
            ).riskLevel) {
              AttendanceRiskLevel.belowTarget ||
              AttendanceRiskLevel.unreachable => true,
              _ => false,
            },
          )
        ? colors.error
        : semantic.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      GradientProgressRing(
                        value: percentage / 100,
                        size: 82,
                        color: standingColor,
                        semanticLabel:
                            '${percentage.toStringAsFixed(1)}% overall attendance',
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: standingColor,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall attendance',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              atRisk.isEmpty
                                  ? 'Safe attendance'
                                  : 'Needs attention',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: standingColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _Metric(value: '$held', label: 'Classes held'),
                      const SizedBox(height: AppSpacing.sm),
                      _Metric(value: '$pending', label: 'Unmarked'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GradientProgressBar(
              value: (percentage / 100).clamp(0, 1),
              color: standingColor,
              semanticLabel: 'Overall attendance',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              atRisk.isEmpty
                  ? '$present present and $absent absent classes. Every subject is on target.'
                  : _riskSummary(atRisk),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String _riskSummary(List<SubjectAttendanceResult> values) {
  final fragile = values.where(
    (item) =>
        AttendanceForecastService.calculate(item.metrics).riskLevel ==
        AttendanceRiskLevel.fragile,
  );
  final below = values.where((item) {
    final risk = AttendanceForecastService.calculate(item.metrics).riskLevel;
    return risk == AttendanceRiskLevel.belowTarget ||
        risk == AttendanceRiskLevel.unreachable;
  });
  String names(Iterable<SubjectAttendanceResult> items) => items
      .map(
        (item) => item.subject.shortCode.isEmpty
            ? item.subject.name
            : item.subject.shortCode,
      )
      .join(', ');
  final parts = <String>[
    if (below.isNotEmpty) '${names(below)} below target',
    if (fragile.isNotEmpty) '${names(fragile)} could fall below after one miss',
  ];
  return '${parts.join('. ')}.';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({
    required this.tasks,
    required this.exams,
    required this.subjects,
    required this.today,
  });

  final AsyncValue<List<CollegeTask>> tasks;
  final AsyncValue<List<Exam>> exams;
  final List<Subject> subjects;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    if (tasks.isLoading || exams.isLoading) {
      return const LoadingState(label: 'Loading upcoming work');
    }
    if (tasks.hasError || exams.hasError) {
      return ErrorState(
        title: 'Could not load upcoming work',
        message: '${tasks.error ?? exams.error}',
      );
    }
    final nearestTasks = HomeDashboardService.nearestTasks(
      tasks: tasks.value!,
      today: today,
    );
    final nearestExams = HomeDashboardService.nearestExams(
      exams: exams.value!,
      today: today,
    );
    if (nearestTasks.isEmpty && nearestExams.isEmpty) {
      return const PremiumSurface(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Nothing upcoming yet. Tasks, assignments, and exams will appear here from the local database.',
              ),
            ),
          ],
        ),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final subjectById = {for (final subject in subjects) subject.id: subject};
    // One quiet list rather than a stack of cards: each row is an icon tile,
    // a title and a single line of when-and-what.
    final rows = <({IconData icon, String title, String subtitle})>[
      for (final task in nearestTasks)
        (
          icon: task.type == CollegeTaskType.assignment
              ? Icons.assignment_outlined
              : Icons.task_alt_rounded,
          title: task.title,
          subtitle: task.dueDate == null
              ? _upcomingTaskPrefix(task, subjectById)
              : '${_upcomingTaskPrefix(task, subjectById)}  •  ${_dateLabel(task.dueDate!, today)}${task.dueTime == null ? '' : ' at ${_time(context, task.dueTime!)}'}',
        ),
      for (final exam in nearestExams)
        (
          icon: Icons.quiz_outlined,
          title: exam.name,
          subtitle:
              '${subjectById[exam.subjectId]?.shortCode ?? exam.examType}  •  ${_dateLabel(exam.examDate, today)}',
        ),
    ];
    return PremiumSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            ListTile(
              dense: true,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(rows[index].icon, size: 18, color: colors.primary),
              ),
              title: Text(
                rows[index].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                rows[index].subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (index != rows.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }
}

/// The day's shortcuts as compact controls, not as a grid of cards.
///
/// Every action keeps its destination and its existing behaviour; only the
/// weight changes, so the schedule above stays the thing the eye lands on.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Add Attendance', Icons.fact_check_outlined, RoutePaths.attendance),
      ('Add Task', Icons.add_task_rounded, RoutePaths.tasks),
      ('Add Subject', Icons.menu_book_outlined, RoutePaths.subjects),
      (
        'View Timetable',
        Icons.calendar_view_week_rounded,
        RoutePaths.timetable,
      ),
    ];
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final action in actions)
          _QuickActionChip(
            label: action.$1,
            icon: action.$2,
            onTap: () => action.$3 == RoutePaths.subjects
                ? context.push(action.$3)
                : action.$3 == RoutePaths.tasks
                ? context.go('${action.$3}?new=true')
                : context.go(action.$3),
          ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _time(BuildContext context, int minutes) {
  final value = minutes == 1440 ? 0 : minutes;
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: value ~/ 60, minute: value % 60));
}

/// Lifts the hero surface one step above the cards around it in dark mode.
///
/// Light mode already separates white cards from the #F8F9FA page, so the hero
/// keeps the default surface colour there.
Color? _heroLift(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainerHigh
      : null;
}

/// The line under the end-of-day state, written the way a student would say
/// it: "tomorrow" only when it really is tomorrow, otherwise the weekday.
String _nextUpMessage(
  BuildContext context,
  NextClassResult result,
  DateTime now,
) {
  final next = result.nextClass;
  if (next == null) {
    return 'Nothing is scheduled ahead. Add classes to your timetable to see your next one here.';
  }
  final days = result.daysUntilNext ?? 0;
  final when = days <= 1
      ? 'tomorrow'
      : 'on ${DateFormat('EEEE').format(now.add(Duration(days: days)))}';
  return 'Next up: ${next.subject.name} $when at '
      '${_time(context, next.entry.startTime)}';
}

String _dateLabel(DateTime date, DateTime today) {
  final day = DateTime(date.year, date.month, date.day);
  final base = DateTime(today.year, today.month, today.day);
  final difference = day.difference(base).inDays;
  if (difference < 0) return 'Overdue ${DateFormat.MMMd().format(day)}';
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  return DateFormat.MMMd().format(day);
}

String _upcomingTaskPrefix(CollegeTask task, Map<int, Subject> subjects) {
  final type = switch (task.type) {
    CollegeTaskType.general => 'General',
    CollegeTaskType.assignment => 'Assignment',
    CollegeTaskType.study => 'Study',
  };
  final subject = subjects[task.subjectId];
  if (task.type != CollegeTaskType.assignment || subject == null) return type;
  return '$type • ${subject.shortCode.isEmpty ? subject.name : subject.shortCode}';
}
