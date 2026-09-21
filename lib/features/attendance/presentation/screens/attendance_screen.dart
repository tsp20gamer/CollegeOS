import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/domain/attendance_forecast.dart';
import 'package:college_os/features/attendance/presentation/widgets/attendance_summary_widgets.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _AttendanceMode { calendar, classes }

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  int? _initializedSemesterId;
  _AttendanceMode _mode = _AttendanceMode.calendar;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final snapshot = ref.watch(attendanceEngineProvider);
    final subjectResults = ref.watch(attendanceSubjectsProvider);
    final pendingAttendance = ref.watch(pendingAttendanceProvider);
    return AppScaffold(
      title: 'Attendance',
      subtitle: 'One timetable, two synchronized views.',
      actions: [
        IconButton(
          key: const Key('open_attendance_planner'),
          tooltip: 'Attendance planner',
          onPressed: () => context.push(RoutePaths.attendancePlanner),
          icon: const Icon(Icons.calculate_outlined),
        ),
        Tooltip(
          message: 'Attendance analytics',
          child: TextButton.icon(
            key: const Key('open_attendance_analytics'),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: .55),
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .20),
              ),
            ),
            onPressed: () => context.push(RoutePaths.attendanceAnalytics),
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text(
              'Analytics',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
      child: semester.when(
        loading: () => const LoadingState(label: 'Loading semester'),
        error: (error, _) => ErrorState(
          title: 'Could not load semester',
          message: error.toString(),
          onRetry: () => ref.invalidate(activeSemesterProvider),
        ),
        data: (value) {
          if (value == null) {
            return const _MessageCard(
              icon: Icons.calendar_today_outlined,
              title: 'No active semester',
              message: 'Set an active semester in Settings to use attendance.',
            );
          }
          return snapshot.when(
            loading: () => const LoadingState(label: 'Building attendance'),
            error: (error, _) => ErrorState(
              title: 'Could not load attendance',
              message: error.toString(),
              onRetry: () => ref.invalidate(attendanceEngineProvider),
            ),
            data: (data) => data == null
                ? const SizedBox.shrink()
                : _content(
                    value,
                    data,
                    subjectResults.value ?? const [],
                    pendingAttendance.value ?? 0,
                  ),
          );
        },
      ),
    );
  }

  Widget _content(
    Semester semester,
    AttendanceEngineSnapshot snapshot,
    List<SubjectAttendanceResult> subjects,
    int pending,
  ) {
    if (_initializedSemesterId != semester.id) {
      _initializedSemesterId = semester.id;
      if (_selectedDate.isBefore(semester.startDate) ||
          _selectedDate.isAfter(semester.endDate)) {
        _selectedDate = _selectedDate.isBefore(semester.startDate)
            ? _dateOnly(semester.startDate)
            : _dateOnly(semester.endDate);
        _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
      }
    }
    final day = AttendanceScheduleEngine.day(
      snapshot: snapshot,
      semester: semester,
      date: _selectedDate,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_AttendanceMode>(
          key: const Key('attendance_mode_toggle'),
          segments: const <ButtonSegment<_AttendanceMode>>[
            ButtonSegment(
              value: _AttendanceMode.calendar,
              icon: Icon(Icons.calendar_month_rounded),
              label: Text('Day View'),
            ),
            ButtonSegment(
              value: _AttendanceMode.classes,
              icon: Icon(Icons.view_agenda_outlined),
              label: Text('Subject View'),
            ),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (value) => setState(() => _mode = value.single),
        ),
        if (pending > 0) ...[
          const SizedBox(height: AppSpacing.md),
          _PendingCard(
            count: pending,
            onReview: () => context.push(RoutePaths.pendingAttendance),
          ),
        ],
        if (subjects.any((item) => item.metrics.hasClasses)) ...[
          const SizedBox(height: AppSpacing.md),
          _RiskForecastCard(subjects: subjects),
        ],
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: _mode == _AttendanceMode.calendar
              ? _CalendarMode(
                  key: const ValueKey('calendar'),
                  visibleMonth: _visibleMonth,
                  selectedDate: _selectedDate,
                  snapshot: snapshot,
                  semester: semester,
                  onMonthChanged: (month) =>
                      setState(() => _visibleMonth = month),
                  onDateSelected: (date) =>
                      setState(() => _selectedDate = date),
                  day: day,
                  onMarkDay: (status) => _markWholeDay(day, semester, status),
                  onHoliday: () => _toggleHoliday(day, semester),
                  onSession: (session, status) =>
                      _markSession(session, semester, status),
                )
              : _ClassesMode(
                  key: const ValueKey('classes'),
                  day: day,
                  semester: semester,
                  subjects: subjects,
                  onDateChanged: _changeDate,
                  onPickDate: () => _pickDate(semester),
                  onMarkDay: (status) => _markWholeDay(day, semester, status),
                  onSession: (session, status) =>
                      _markSession(session, semester, status),
                ),
        ),
      ],
    );
  }

  void _changeDate(int offset) {
    final date = _selectedDate.add(Duration(days: offset));
    setState(() {
      _selectedDate = date;
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  Future<void> _pickDate(Semester semester) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: semester.startDate.subtract(const Duration(days: 365)),
      lastDate: semester.endDate.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = _dateOnly(picked);
      _visibleMonth = DateTime(picked.year, picked.month);
    });
  }

  Future<void> _markWholeDay(
    AttendanceDay day,
    Semester semester,
    ClassAttendanceStatus status,
  ) async {
    if (!day.isInsideSemester || day.sessions.isEmpty || day.override != null) {
      return;
    }
    final ok = await ref
        .read(attendanceCommandProvider.notifier)
        .markWholeDay(day, semester.id, status);
    if (!mounted) return;
    if (!ok) _showResult('Could not update day.');
  }

  Future<void> _markSession(
    ProjectedClassSession session,
    Semester semester,
    ClassAttendanceStatus status,
  ) async {
    final ok = await ref
        .read(attendanceCommandProvider.notifier)
        .markSession(session, semester.id, status, note: session.note);
    if (!mounted) return;
    if (!ok) _showResult('Could not update attendance.');
  }

  Future<void> _toggleHoliday(AttendanceDay day, Semester semester) async {
    if (!day.isInsideSemester) return;
    final isHoliday = day.state == AttendanceDayState.holiday;
    final ok = isHoliday
        ? await ref
              .read(attendanceCommandProvider.notifier)
              .undoHoliday(semester.id, day.date)
        : await ref
              .read(attendanceCommandProvider.notifier)
              .markHoliday(semester.id, day.date);
    if (!mounted) return;
    _showResult(
      ok
          ? (isHoliday
                ? 'Holiday removed. Earlier class marks were restored.'
                : 'Day marked as holiday. Its classes are excluded.')
          : 'Could not update holiday.',
    );
  }

  void _showResult(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RiskForecastCard extends StatelessWidget {
  const _RiskForecastCard({required this.subjects});

  final List<SubjectAttendanceResult> subjects;

  @override
  Widget build(BuildContext context) {
    final ordered = AttendanceForecastService.attentionFirst(
      subjects.where((item) => item.metrics.hasClasses),
      (item) => item.metrics,
    );
    final attention = ordered
        .where(
          (item) =>
              AttendanceForecastService.calculate(item.metrics).needsAttention,
        )
        .take(3)
        .toList(growable: false);
    if (attention.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer.withValues(alpha: .28),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: colors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Attendance forecast',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in attention) ...[
              _ForecastRow(item: item),
              if (item != attention.last) const Divider(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.item});

  final SubjectAttendanceResult item;

  @override
  Widget build(BuildContext context) {
    final forecast = AttendanceForecastService.calculate(item.metrics);
    final attend = forecast.afterAttendingNext.attendancePercentage!;
    final miss = forecast.afterMissingNext.attendancePercentage!;
    final message = forecast.riskLevel == AttendanceRiskLevel.fragile
        ? 'One more absence drops this below ${formatTarget(item.metrics.target)}.'
        : attendanceGuidance(item.metrics);
    return InkWell(
      onTap: () => context.push(
        RoutePaths.attendanceSubject.replaceFirst(
          ':subjectId',
          '${item.subject.id}',
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subject.shortCode.isEmpty
                        ? item.subject.name
                        : item.subject.shortCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Attend ${attend.toStringAsFixed(1)}%\nMiss ${miss.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarMode extends StatelessWidget {
  const _CalendarMode({
    required this.visibleMonth,
    required this.selectedDate,
    required this.snapshot,
    required this.semester,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.day,
    required this.onMarkDay,
    required this.onHoliday,
    required this.onSession,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final AttendanceEngineSnapshot snapshot;
  final Semester semester;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final AttendanceDay day;
  final ValueChanged<ClassAttendanceStatus> onMarkDay;
  final VoidCallback onHoliday;
  final void Function(ProjectedClassSession, ClassAttendanceStatus) onSession;

  @override
  Widget build(BuildContext context) {
    final days = AttendanceScheduleEngine.month(
      snapshot: snapshot,
      semester: semester,
      month: visibleMonth,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: _MonthCalendar(
            key: ValueKey('${visibleMonth.year}-${visibleMonth.month}'),
            month: visibleMonth,
            days: days,
            selectedDate: selectedDate,
            onPrevious: () => onMonthChanged(
              DateTime(visibleMonth.year, visibleMonth.month - 1),
            ),
            onNext: () => onMonthChanged(
              DateTime(visibleMonth.year, visibleMonth.month + 1),
            ),
            onSelected: onDateSelected,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DayPanel(
          day: day,
          onMarkDay: onMarkDay,
          onHoliday: onHoliday,
          onSession: onSession,
          showHolidayAction: true,
        ),
        const SizedBox(height: AppSpacing.md),
        const _CalendarLegend(),
      ],
    );
  }
}

class _ClassesMode extends StatelessWidget {
  const _ClassesMode({
    required this.day,
    required this.semester,
    required this.subjects,
    required this.onDateChanged,
    required this.onPickDate,
    required this.onMarkDay,
    required this.onSession,
    super.key,
  });

  final AttendanceDay day;
  final Semester semester;
  final List<SubjectAttendanceResult> subjects;
  final ValueChanged<int> onDateChanged;
  final VoidCallback onPickDate;
  final ValueChanged<ClassAttendanceStatus> onMarkDay;
  final void Function(ProjectedClassSession, ClassAttendanceStatus) onSession;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateNavigator(
          date: day.date,
          onPrevious: () => onDateChanged(-1),
          onNext: () => onDateChanged(1),
          onPick: onPickDate,
        ),
        const SizedBox(height: AppSpacing.md),
        _DayPanel(
          day: day,
          onMarkDay: onMarkDay,
          onHoliday: () {},
          onSession: onSession,
          showHolidayAction: false,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Subject attendance',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (subjects.isEmpty)
          const _MessageCard(
            icon: Icons.menu_book_outlined,
            title: 'No subjects yet',
            message: 'Create subjects and add them to your weekly timetable.',
          )
        else
          for (final subject in subjects) ...[
            AttendanceSubjectCard(
              view: subject,
              onTap: () => context.push(
                RoutePaths.attendanceSubject.replaceFirst(
                  ':subjectId',
                  '${subject.subject.id}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.days,
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSelected,
    super.key,
  });

  final DateTime month;
  final List<AttendanceDay> days;
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final leading = DateTime(month.year, month.month).weekday - 1;
    final itemCount = ((leading + days.length + 6) ~/ 7) * 7;
    return PremiumSurface(
      key: const Key('attendance_month_calendar'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevious,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNext,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              for (final label in [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: AppLayout.compactCalendarDayExtent,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final dayIndex = index - leading;
              if (dayIndex < 0 || dayIndex >= days.length) {
                return const SizedBox.shrink();
              }
              final day = days[dayIndex];
              return _CalendarDayCell(
                day: day,
                selected: _sameDate(day.date, selectedDate),
                onTap: () => onSelected(day.date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final AttendanceDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _dayVisual(context, day.state);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '${DateFormat.yMMMMd().format(day.date)}, ${visual.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : null,
            border: selected ? Border.all(color: colors.primary) : null,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.date.day}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Icon(visual.icon, size: 13, color: visual.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.day,
    required this.onMarkDay,
    required this.onHoliday,
    required this.onSession,
    required this.showHolidayAction,
  });

  final AttendanceDay day;
  final ValueChanged<ClassAttendanceStatus> onMarkDay;
  final VoidCallback onHoliday;
  final void Function(ProjectedClassSession, ClassAttendanceStatus) onSession;
  final bool showHolidayAction;

  @override
  Widget build(BuildContext context) {
    final visual = _dayVisual(context, day.state);
    final isExcluded =
        day.state == AttendanceDayState.holiday ||
        day.state == AttendanceDayState.collegeClosed;
    return PremiumSurface(
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
                      DateFormat('EEEE, d MMMM').format(day.date),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      visual.label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: visual.color),
                    ),
                  ],
                ),
              ),
              Icon(visual.icon, color: visual.color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!day.isInsideSemester)
            const _InlineNotice(
              icon: Icons.info_outline_rounded,
              text: 'This date is outside the active semester.',
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _DayActionButton(
                    key: const Key('mark_all_present'),
                    label: showHolidayAction
                        ? 'Present Day'
                        : 'Mark All Present',
                    icon: Icons.check_circle_outline_rounded,
                    tone: _DayActionTone.present,
                    onTap: day.sessions.isEmpty || isExcluded
                        ? null
                        : () => onMarkDay(ClassAttendanceStatus.present),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _DayActionButton(
                    key: const Key('mark_all_absent'),
                    label: showHolidayAction ? 'Absent Day' : 'Mark All Absent',
                    icon: Icons.cancel_outlined,
                    tone: _DayActionTone.absent,
                    onTap: day.sessions.isEmpty || isExcluded
                        ? null
                        : () => onMarkDay(ClassAttendanceStatus.absent),
                  ),
                ),
                if (showHolidayAction) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _DayActionButton(
                      key: const Key('toggle_holiday'),
                      label: day.state == AttendanceDayState.holiday
                          ? 'Undo Holiday'
                          : 'Holiday',
                      icon: day.state == AttendanceDayState.holiday
                          ? Icons.undo_rounded
                          : Icons.beach_access_outlined,
                      tone: _DayActionTone.holiday,
                      onTap: onHoliday,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Scheduled classes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isExcluded)
              const _InlineNotice(
                icon: Icons.event_busy_outlined,
                text:
                    'Scheduled classes are excluded. Earlier marks are preserved and return if the holiday is undone.',
              )
            else if (day.sessions.isEmpty)
              const _InlineNotice(
                icon: Icons.free_breakfast_outlined,
                text: 'No classes are scheduled for this date.',
              )
            else
              for (final session in day.sessions) ...[
                _ClassAttendanceTile(
                  session: session,
                  onStatus: (status) => onSession(session, status),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ],
      ),
    );
  }
}

enum _DayActionTone { present, absent, holiday }

class _DayActionButton extends StatelessWidget {
  const _DayActionButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final _DayActionTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final foreground = switch (tone) {
      _DayActionTone.present => semantic.success,
      _DayActionTone.absent => colors.error,
      _DayActionTone.holiday => semantic.warning,
    };
    final background = switch (tone) {
      _DayActionTone.present => semantic.successContainer,
      _DayActionTone.absent => colors.errorContainer,
      _DayActionTone.holiday => semantic.warningContainer,
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: onTap == null
            ? colors.surfaceContainerHigh.withValues(alpha: .5)
            : background.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: onTap == null ? colors.outline : foreground,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onTap == null ? colors.outline : foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassAttendanceTile extends StatelessWidget {
  const _ClassAttendanceTile({required this.session, required this.onStatus});

  final ProjectedClassSession session;
  final ValueChanged<ClassAttendanceStatus> onStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
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
                    Text(
                      session.subject.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      [
                        session.subject.shortCode,
                        session.subject.room,
                      ].where((value) => value.trim().isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              _StatusChip(
                label: 'Present',
                icon: Icons.check_rounded,
                selected: session.status == ClassAttendanceStatus.present,
                onSelected: () => onStatus(ClassAttendanceStatus.present),
              ),
              _StatusChip(
                label: 'Absent',
                icon: Icons.close_rounded,
                selected: session.status == ClassAttendanceStatus.absent,
                onSelected: () => onStatus(ClassAttendanceStatus.absent),
              ),
              _StatusChip(
                label: 'Cancelled',
                icon: Icons.remove_rounded,
                selected: session.status == ClassAttendanceStatus.cancelled,
                onSelected: () => onStatus(ClassAttendanceStatus.cancelled),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    selected: selected,
    showCheckmark: false,
    avatar: Icon(icon, size: 17),
    label: Text(label),
    onSelected: (_) => onSelected(),
  );
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Previous day',
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat('EEEE, d MMM').format(date)),
        ),
      ),
      IconButton(
        tooltip: 'Next day',
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.count, required this.onReview});

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Card(
      color: semantic.warningContainer,
      child: ListTile(
        leading: Icon(Icons.pending_actions_rounded, color: semantic.warning),
        title: Text(
          '$count ${count == 1 ? 'class needs' : 'classes need'} attendance',
        ),
        subtitle: const Text('Unmarked classes are never treated as absent.'),
        trailing: TextButton(onPressed: onReview, child: const Text('Review')),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    const states = [
      AttendanceDayState.present,
      AttendanceDayState.partial,
      AttendanceDayState.absent,
      AttendanceDayState.partiallyMarked,
      AttendanceDayState.unmarked,
      AttendanceDayState.holiday,
      AttendanceDayState.noClasses,
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final state in states)
          Builder(
            builder: (context) {
              final value = _dayVisual(context, state);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(value.icon, size: 16, color: value.color),
                  const SizedBox(width: 4),
                  Text(
                    value.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});

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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

({IconData icon, Color color, String label}) _dayVisual(
  BuildContext context,
  AttendanceDayState state,
) {
  final colors = Theme.of(context).colorScheme;
  final semantic = Theme.of(context).extension<AppSemanticColors>()!;
  return switch (state) {
    AttendanceDayState.present => (
      icon: Icons.check_circle_rounded,
      color: semantic.success,
      label: 'Present day',
    ),
    AttendanceDayState.absent => (
      icon: Icons.cancel_rounded,
      color: colors.error,
      label: 'Absent day',
    ),
    AttendanceDayState.partial => (
      icon: Icons.error_rounded,
      color: semantic.warning,
      label: 'Partial attendance',
    ),
    AttendanceDayState.partiallyMarked => (
      icon: Icons.timelapse_rounded,
      color: semantic.warning,
      label: 'Partially marked',
    ),
    AttendanceDayState.holiday => (
      icon: Icons.beach_access_rounded,
      color: semantic.info,
      label: 'Holiday',
    ),
    AttendanceDayState.collegeClosed => (
      icon: Icons.event_busy_rounded,
      color: semantic.info,
      label: 'College closed',
    ),
    AttendanceDayState.unmarked => (
      icon: Icons.circle_outlined,
      color: colors.onSurfaceVariant,
      label: 'Unmarked',
    ),
    AttendanceDayState.noClasses => (
      icon: Icons.remove_rounded,
      color: colors.outline,
      label: 'No classes',
    ),
    AttendanceDayState.outsideSemester => (
      icon: Icons.block_rounded,
      color: colors.outline,
      label: 'Outside semester',
    ),
  };
}

String _formatMinutes(BuildContext context, int value) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: value ~/ 60, minute: value % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
