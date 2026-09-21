import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/presentation/widgets/timetable_entry_form_sheet.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TimetableExceptionsScreen extends ConsumerStatefulWidget {
  const TimetableExceptionsScreen({super.key});

  @override
  ConsumerState<TimetableExceptionsScreen> createState() =>
      _TimetableExceptionsScreenState();
}

class _TimetableExceptionsScreenState
    extends ConsumerState<TimetableExceptionsScreen> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = DateUtils.dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final subjects = ref.watch(activeSemesterSubjectsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('One-day Changes')),
      body: SafeArea(
        child: semester.when(
          loading: () => const LoadingState(label: 'Loading timetable'),
          error: (error, _) => ErrorState(
            title: 'Could not load semester',
            message: error.toString(),
          ),
          data: (value) {
            if (value == null) {
              return const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No active semester',
                message: 'Activate a semester before adding exceptions.',
              );
            }
            if (_date.isBefore(value.startDate) ||
                _date.isAfter(value.endDate)) {
              _date = DateUtils.dateOnly(
                _date.isBefore(value.startDate)
                    ? value.startDate
                    : value.endDate,
              );
            }
            final day = ref.watch(attendanceDayProvider(_date));
            final entries = ref.watch(timetableEntriesOnProvider(_date));
            final activeSubjects =
                subjects.value
                    ?.where((subject) => !subject.isArchived)
                    .toList(growable: false) ??
                const <Subject>[];
            return day.when(
              loading: () => const LoadingState(label: 'Loading this day'),
              error: (error, _) => ErrorState(
                title: 'Could not load this date',
                message: error.toString(),
              ),
              data: (attendanceDay) => _content(
                semesterStart: value.startDate,
                semesterEnd: value.endDate,
                semesterId: value.id,
                day: attendanceDay,
                subjects: activeSubjects,
                entries: entries.value ?? const <TimetableEntry>[],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _content({
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required int semesterId,
    required AttendanceDay? day,
    required List<Subject> subjects,
    required List<TimetableEntry> entries,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _DateNavigator(
          date: _date,
          canGoBack: _date.isAfter(DateUtils.dateOnly(semesterStart)),
          canGoForward: _date.isBefore(DateUtils.dateOnly(semesterEnd)),
          onBack: () =>
              setState(() => _date = _date.subtract(const Duration(days: 1))),
          onForward: () =>
              setState(() => _date = _date.add(const Duration(days: 1))),
          onPick: () => _pickDate(semesterStart, semesterEnd),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Changes apply only to this date'),
            subtitle: Text(
              'Cancel a scheduled class or add an extra class without changing the repeating weekly timetable.',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('add_timetable_exception_button'),
          onPressed: subjects.isEmpty
              ? null
              : () => _showExtraClassForm(
                  semesterId: semesterId,
                  semesterStart: semesterStart,
                  semesterEnd: semesterEnd,
                  subjects: subjects,
                  entries: entries,
                ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add extra class'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Classes on ${DateFormat('d MMMM').format(_date)}',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (day == null || day.sessions.isEmpty)
          EmptyState(
            icon: day?.state == AttendanceDayState.holiday
                ? Icons.beach_access_outlined
                : Icons.event_available_outlined,
            title: day?.state == AttendanceDayState.holiday
                ? 'Holiday'
                : 'No classes on this date',
            message: day?.state == AttendanceDayState.holiday
                ? 'Holiday dates do not show or count scheduled classes.'
                : 'Add an extra class if your college schedules one.',
          )
        else
          for (final session in day.sessions) ...[
            _ExceptionClassCard(
              session: session,
              onToggleCancelled: () => _toggleCancelled(session, semesterId),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Future<void> _showExtraClassForm({
    required int semesterId,
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required List<Subject> subjects,
    required List<TimetableEntry> entries,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => TimetableEntryFormSheet(
      semesterId: semesterId,
      subjects: subjects,
      allEntries: entries,
      initialWeekday: _date.weekday,
      semesterStart: semesterStart,
      semesterEnd: semesterEnd,
      oneDayDate: _date,
    ),
  );

  Future<void> _toggleCancelled(
    ProjectedClassSession session,
    int semesterId,
  ) async {
    final isCancelled = session.status == ClassAttendanceStatus.cancelled;
    if (!isCancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cancel this class for the day?'),
          content: Text(
            '${session.subject.name} on ${DateFormat('d MMMM').format(_date)} will be excluded from attendance. The weekly timetable is unchanged.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep class'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancel class'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final command = ref.read(attendanceCommandProvider.notifier);
    final success = isCancelled && session.attendanceId != null
        ? await command.clearSession(session.attendanceId!)
        : await command.markSession(
            session,
            semesterId,
            ClassAttendanceStatus.cancelled,
            note: 'One-day timetable exception',
          );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? isCancelled
                    ? 'Class restored for this date.'
                    : 'Class cancelled for this date.'
              : 'Could not update this class.',
        ),
      ),
    );
  }

  Future<void> _pickDate(DateTime start, DateTime end) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: start,
      lastDate: end,
      helpText: 'Choose exception date',
    );
    if (picked != null && mounted) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onPick,
  });

  final DateTime date;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.outlined(
        tooltip: 'Previous date',
        onPressed: canGoBack ? onBack : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            DateFormat('EEE, d MMM yyyy').format(date),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      IconButton.outlined(
        tooltip: 'Next date',
        onPressed: canGoForward ? onForward : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

class _ExceptionClassCard extends StatelessWidget {
  const _ExceptionClassCard({
    required this.session,
    required this.onToggleCancelled,
  });

  final ProjectedClassSession session;
  final VoidCallback onToggleCancelled;

  @override
  Widget build(BuildContext context) {
    final cancelled = session.status == ClassAttendanceStatus.cancelled;
    return Semantics(
      container: true,
      label:
          '${session.subject.name}, ${_time(context, session.startTime)} to ${_time(context, session.endTime)}, ${cancelled
              ? 'cancelled'
              : session.isOneDayException
              ? 'extra class'
              : 'scheduled class'}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  _time(context, session.startTime),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
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
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      cancelled
                          ? 'Cancelled for this date'
                          : session.isOneDayException
                          ? 'Extra class • One day only'
                          : 'Weekly class',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: onToggleCancelled,
                child: Text(cancelled ? 'Restore' : 'Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _time(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
