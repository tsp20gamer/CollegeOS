import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_calculator.dart';
import 'package:college_os/features/attendance/domain/attendance_engine.dart';
import 'package:college_os/features/attendance/presentation/widgets/attendance_summary_widgets.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SubjectAttendanceScreen extends ConsumerWidget {
  const SubjectAttendanceScreen({required this.subjectId, super.key});

  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(subjectAttendanceProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('Subject attendance')),
      body: SafeArea(
        top: false,
        child: value.when(
          loading: () => const LoadingState(label: 'Loading attendance'),
          error: (error, _) => ErrorState(
            title: 'Could not load attendance',
            message: error.toString(),
          ),
          data: (result) => result == null
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Subject not found',
                  message: 'This subject is not in the active semester.',
                )
              : _Body(result: result),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.result});

  final SubjectAttendanceResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = result.metrics;
    final events =
        <_HistoryEvent>[
          for (final record in result.history) _HistoryEvent.record(record),
          for (final override in result.excludedDays)
            _HistoryEvent.excluded(override),
        ]..sort((a, b) {
          final date = b.date.compareTo(a.date);
          if (date != 0) return date;
          return b.startTime.compareTo(a.startTime);
        });
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppLayout.scaffoldBottomPadding(context),
      ),
      children: [
        _Header(result: result),
        const SizedBox(height: AppSpacing.md),
        _Statistics(metrics: metrics),
        const SizedBox(height: AppSpacing.md),
        _Guidance(metrics: metrics),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Attendance history',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Holidays and college-closed days are excluded from these totals.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (events.isEmpty)
          const EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'No marked classes yet',
            message: 'Mark scheduled classes from Calendar or Classes view.',
          )
        else
          for (final event in events) ...[
            if (event.record case final record?)
              _HistoryTile(
                record: record,
                onTap: () => _editRecord(context, ref, result, record),
              )
            else
              _ExcludedHistoryTile(dayOverride: event.override!),
            const SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }
}

final class _HistoryEvent {
  const _HistoryEvent.record(ExplicitClassAttendance value)
    : record = value,
      override = null;

  const _HistoryEvent.excluded(DayOverride value)
    : record = null,
      override = value;

  final ExplicitClassAttendance? record;
  final DayOverride? override;

  DateTime get date => record?.date ?? override!.date;
  int get startTime => record?.startTime ?? -1;
}

class _ExcludedHistoryTile extends StatelessWidget {
  const _ExcludedHistoryTile({required this.dayOverride});

  final DayOverride dayOverride;

  @override
  Widget build(BuildContext context) {
    final holiday = dayOverride.type == CalendarDayOverrideType.holiday;
    final label = holiday ? 'Holiday / no class' : 'College closed / no class';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            holiday ? Icons.beach_access_outlined : Icons.event_busy_outlined,
          ),
        ),
        title: Text('${DateFormat.MMMd().format(dayOverride.date)} — $label'),
        subtitle: dayOverride.note.isEmpty ? null : Text(dayOverride.note),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.result});

  final SubjectAttendanceResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          AttendanceProgressRing(metrics: result.metrics, size: 88),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.subject.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Target ${formatTarget(result.metrics.target)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
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

class _Statistics extends StatelessWidget {
  const _Statistics({required this.metrics});

  final AttendanceMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colors = Theme.of(context).colorScheme;
    final entries = [
      ('Present', metrics.presentCount, semantic.success),
      ('Absent', metrics.absentCount, colors.error),
      ('Held', metrics.heldClasses, colors.primary),
      ('Cancelled', metrics.cancelledCount, colors.onSurfaceVariant),
      ('Target', '${(metrics.target * 100).round()}%', colors.primary),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in entries)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 102),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.$2}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: entry.$3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(entry.$1),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance({required this.metrics});

  final AttendanceMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final color = attendanceStatusColor(context, metrics);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        leading: Icon(
          metrics.isAtOrAboveTarget
              ? Icons.safety_check_rounded
              : Icons.trending_up_rounded,
          color: color,
        ),
        title: Text(
          metrics.isAtOrAboveTarget ? 'Safe bunks' : 'Classes required',
        ),
        subtitle: Text(attendanceGuidance(metrics)),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.onTap});

  final ExplicitClassAttendance record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final visual = switch (record.status) {
      ClassAttendanceStatus.present => (
        Icons.check_rounded,
        'Present',
        semantic.success,
      ),
      ClassAttendanceStatus.absent => (
        Icons.close_rounded,
        'Absent',
        colors.error,
      ),
      ClassAttendanceStatus.cancelled => (
        Icons.remove_rounded,
        'Cancelled',
        colors.onSurfaceVariant,
      ),
      ClassAttendanceStatus.unmarked => (
        Icons.circle_outlined,
        'Unmarked',
        colors.onSurfaceVariant,
      ),
    };
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: visual.$3.withValues(alpha: 0.12),
          foregroundColor: visual.$3,
          child: Icon(visual.$1),
        ),
        title: Text('${DateFormat.MMMd().format(record.date)} — ${visual.$2}'),
        subtitle: Text(
          '${_formatMinutes(context, record.startTime)}'
          '${record.note.isEmpty ? '' : ' • ${record.note}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

Future<void> _editRecord(
  BuildContext context,
  WidgetRef ref,
  SubjectAttendanceResult result,
  ExplicitClassAttendance record,
) async {
  var selected = record.status;
  final noteController = TextEditingController(text: record.note);
  final action = await showModalBottomSheet<_EditAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit class attendance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${DateFormat.yMMMMd().format(record.date)} • ${_formatMinutes(context, record.startTime)}',
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<ClassAttendanceStatus>(
              segments: const [
                ButtonSegment(
                  value: ClassAttendanceStatus.present,
                  label: Text('Present'),
                  icon: Icon(Icons.check_rounded),
                ),
                ButtonSegment(
                  value: ClassAttendanceStatus.absent,
                  label: Text('Absent'),
                  icon: Icon(Icons.close_rounded),
                ),
                ButtonSegment(
                  value: ClassAttendanceStatus.cancelled,
                  label: Text('Cancelled'),
                  icon: Icon(Icons.remove_rounded),
                ),
              ],
              selected: {selected},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => selected = value.single),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: noteController,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.pop(context, _EditAction.save),
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _EditAction.unmark),
              child: const Text('Return to Unmarked'),
            ),
          ],
        ),
      ),
    ),
  );
  final note = noteController.text;
  noteController.dispose();
  if (action == null || !context.mounted) return;
  final controller = ref.read(attendanceCommandProvider.notifier);
  final ok = action == _EditAction.unmark
      ? await controller.clearSession(record.id)
      : await controller.markSession(
          ProjectedClassSession(
            attendanceId: record.id,
            timetableEntryId: record.timetableEntryId,
            date: record.date,
            subject: result.subject,
            startTime: record.startTime,
            endTime: record.endTime,
            status: record.status,
            note: record.note,
            manuallyModified: true,
          ),
          record.semesterId,
          selected,
          note: note,
        );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Attendance updated.' : 'Could not update attendance.',
      ),
    ),
  );
}

enum _EditAction { save, unmark }

String _formatMinutes(BuildContext context, int value) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: value ~/ 60, minute: value % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
