import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/effects.dart';
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
import 'package:college_os/shared/widgets/status_badge.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return AppScaffold(
      title: _greeting(now, settings.value?.studentName),
      subtitle: DateFormat('EEEE, d MMMM').format(now),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdentityHeader(
            collegeName: settings.value?.collegeName ?? 'CollegeOS',
            semesterName: semester.value?.name,
          ),
          const SizedBox(height: AppSpacing.lg),
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
            _SectionTitle(title: 'Next class', icon: Icons.near_me_rounded),
            const SizedBox(height: AppSpacing.sm),
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
            _SectionTitle(
              title: "Today's classes",
              icon: Icons.view_agenda_outlined,
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
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(
              title: 'Overall attendance',
              icon: Icons.insights_rounded,
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
            const SizedBox(height: AppSpacing.xl),
            const WeeklyAttendanceCard(),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle(
              title: 'Upcoming',
              icon: Icons.upcoming_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _UpcomingSection(
              tasks: tasks,
              exams: exams,
              subjects: subjects.value ?? const [],
              today: now,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle(
              title: 'Quick actions',
              icon: Icons.bolt_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _QuickActions(),
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

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({
    required this.collegeName,
    required this.semesterName,
  });

  final String collegeName;
  final String? semesterName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.48),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF07163A),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Image.asset(
              'assets/branding/collegeos_icon_foreground.png',
              semanticLabel: 'CollegeOS logo',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collegeName.isEmpty ? 'CollegeOS' : collegeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  semesterName ?? 'Your day, calmly organized.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (semesterName != null)
                  Text(
                    'Your day, calmly organized.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon, this.action});

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            shadows: AppGlows.text(strength: .30),
          ),
        ),
      ),
      ?action,
    ],
  );
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
      return Card(
        child: Padding(
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
                      style: Theme.of(context).textTheme.titleMedium,
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
        ),
      );
    }
    final current = result.currentClass;
    final next = result.nextClass;
    final item = current ?? (result.nextIsToday ? next : null);
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    if (item == null) {
      final futureMessage = next == null
          ? 'Your timetable has no upcoming classes.'
          : 'Next: ${next.subject.name} on ${_relativeDay(result.daysUntilNext!)}.';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.free_breakfast_rounded, color: semantic.success),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No more classes today',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      futureMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final entry = item.entry;
    final room = entry.room.isNotEmpty ? entry.room : item.subject.room;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.subtle(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: current != null
              ? semantic.success.withValues(alpha: .40)
              : AppColors.violet.withValues(alpha: .30),
        ),
        boxShadow: AppGlows.primary(strength: current != null ? .90 : .58),
      ),
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
                  background: colors.surface.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_time(context, entry.startTime)}–${_time(context, entry.endTime)}',
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
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
          Row(
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
              const SizedBox(width: AppSpacing.sm),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${value.sessions.length} classes today',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
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
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark all present'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < value.sessions.length; index++) ...[
          _TodayClassCard(
            session: value.sessions[index],
            semesterId: semesterId,
          ),
          if (index != value.sessions.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TodayClassCard extends ConsumerWidget {
  const _TodayClassCard({required this.session, required this.semesterId});

  final ProjectedClassSession session;
  final int semesterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(session.subject.displayColor),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subject.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${_time(context, session.startTime)}–${_time(context, session.endTime)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<ClassAttendanceStatus>(
                  tooltip: 'Mark ${session.subject.name}',
                  onSelected: (status) => ref
                      .read(attendanceCommandProvider.notifier)
                      .markSession(session, semesterId, status),
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
                  child: _AttendanceStateIcon(status: session.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceStateIcon extends StatelessWidget {
  const _AttendanceStateIcon({required this.status});

  final ClassAttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final value = switch (status) {
      ClassAttendanceStatus.present => (
        Icons.check_circle_rounded,
        semantic.success,
        'Present',
      ),
      ClassAttendanceStatus.absent => (
        Icons.cancel_rounded,
        colors.error,
        'Absent',
      ),
      ClassAttendanceStatus.cancelled => (
        Icons.remove_circle_outline_rounded,
        colors.onSurfaceVariant,
        'Cancelled',
      ),
      ClassAttendanceStatus.unmarked => (
        Icons.circle_outlined,
        colors.onSurfaceVariant,
        'Unmarked',
      ),
    };
    return Semantics(
      key: Key('home_attendance_${status.name}'),
      button: true,
      label: '${value.$3}. Tap to change.',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(value.$1, color: value.$2),
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
                        semanticLabel:
                            '${percentage.toStringAsFixed(1)}% overall attendance',
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                shadows: AppGlows.text(strength: .82),
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
                                  ?.copyWith(
                                    color: atRisk.isEmpty
                                        ? semantic.success
                                        : colors.error,
                                  ),
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
      return const Card(
        child: Padding(
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
        ),
      );
    }
    final subjectById = {for (final subject in subjects) subject.id: subject};
    return Card(
      child: Column(
        children: [
          for (final task in nearestTasks)
            ListTile(
              leading: Icon(
                task.type == CollegeTaskType.assignment
                    ? Icons.assignment_outlined
                    : Icons.task_alt_rounded,
              ),
              title: Text(task.title),
              subtitle: Text(
                task.dueDate == null
                    ? _upcomingTaskPrefix(task, subjectById)
                    : '${_upcomingTaskPrefix(task, subjectById)}  •  ${_dateLabel(task.dueDate!, today)}${task.dueTime == null ? '' : ' at ${_time(context, task.dueTime!)}'}',
              ),
            ),
          for (final exam in nearestExams)
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: Text(exam.name),
              subtitle: Text(
                '${subjectById[exam.subjectId]?.shortCode ?? exam.examType}  •  ${_dateLabel(exam.examDate, today)}',
              ),
            ),
        ],
      ),
    );
  }
}

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: Card(
                  child: InkWell(
                    onTap: () => action.$3 == RoutePaths.subjects
                        ? context.push(action.$3)
                        : action.$3 == RoutePaths.tasks
                        ? context.go('${action.$3}?new=true')
                        : context.go(action.$3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            action.$2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            action.$1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String _time(BuildContext context, int minutes) {
  final value = minutes == 1440 ? 0 : minutes;
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: value ~/ 60, minute: value % 60));
}

String _relativeDay(int daysAhead) => switch (daysAhead) {
  1 => 'tomorrow',
  final days => 'in $days days',
};

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
