import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/calendar/application/academic_calendar_providers.dart';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/calendar/domain/academic_calendar_repository.dart';
import 'package:college_os/features/calendar/domain/academic_calendar_impact.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AcademicCalendarScreen extends ConsumerWidget {
  const AcademicCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semester = ref.watch(activeSemesterProvider).value;
    final events = ref.watch(activeSemesterCalendarEventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Calendar')),
      floatingActionButton: semester == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('add_calendar_event'),
              onPressed: () => _showEditor(context, semester),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add date'),
            ),
      body: SafeArea(
        child: events.when(
          loading: () => const LoadingState(label: 'Loading calendar'),
          error: (error, _) => ErrorState(
            title: 'Could not load academic calendar',
            message: error.toString(),
            onRetry: () => ref.invalidate(activeSemesterCalendarEventsProvider),
          ),
          data: (items) {
            if (semester == null) {
              return const EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'No active semester',
                message: 'Activate a semester before adding academic dates.',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl * 2,
              ),
              children: [
                Text(
                  semester.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${DateFormat.yMMMd().format(semester.startDate)} - ${DateFormat.yMMMd().format(semester.endDate)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const _CalendarExplanation(),
                const SizedBox(height: AppSpacing.lg),
                if (items.isEmpty)
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No academic dates yet',
                    message:
                        'Add holidays, college closures, exam periods, or important events.',
                    action: FilledButton.icon(
                      onPressed: () => _showEditor(context, semester),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add first date'),
                    ),
                  )
                else
                  for (final event in items) ...[
                    _CalendarEventCard(
                      event: event,
                      onEdit: () =>
                          _showEditor(context, semester, event: event),
                      onDelete: () => _delete(context, ref, event),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    Semester semester, {
    AcademicCalendarEvent? event,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _CalendarEventEditor(semester: semester, event: event),
  );

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AcademicCalendarEvent event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${event.title}?'),
        content: Text(
          event.type == AcademicCalendarEventType.holiday ||
                  event.type == AcademicCalendarEventType.collegeClosed
              ? 'Classes in this range will return to their previous marked or unmarked state. Existing attendance records are not deleted.'
              : 'This removes the calendar entry only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await ref
        .read(academicCalendarCommandProvider.notifier)
        .deleteEvent(event.id);
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not delete the calendar entry.')),
    );
  }
}

class _CalendarExplanation extends StatelessWidget {
  const _CalendarExplanation();

  @override
  Widget build(BuildContext context) => Card(
    child: const ListTile(
      leading: Icon(Icons.info_outline_rounded),
      title: Text('Attendance stays class-based'),
      subtitle: Text(
        'Holiday and college-closed ranges exclude scheduled classes. Exam periods and events are informational and do not alter attendance.',
      ),
    ),
  );
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final AcademicCalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = _eventVisual(context, event.type);
    final dates = _sameDate(event.startDate, event.endDate)
        ? DateFormat.yMMMd().format(event.startDate)
        : '${DateFormat.MMMd().format(event.startDate)} - ${DateFormat.yMMMd().format(event.endDate)}';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: visual.color.withValues(alpha: 0.14),
          foregroundColor: visual.color,
          child: Icon(visual.icon),
        ),
        title: Text(event.title),
        subtitle: Text(
          [
            visual.label,
            dates,
            event.note,
          ].where((item) => item.isNotEmpty).join(' • '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _CalendarEventEditor extends ConsumerStatefulWidget {
  const _CalendarEventEditor({required this.semester, this.event});

  final Semester semester;
  final AcademicCalendarEvent? event;

  @override
  ConsumerState<_CalendarEventEditor> createState() =>
      _CalendarEventEditorState();
}

class _CalendarEventEditorState extends ConsumerState<_CalendarEventEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late AcademicCalendarEventType _type;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _title = TextEditingController(text: event?.title ?? '');
    _note = TextEditingController(text: event?.note ?? '');
    _type = event?.type ?? AcademicCalendarEventType.event;
    _start = event?.startDate ?? _initialDate(widget.semester);
    _end = event?.endDate ?? _start;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(academicCalendarCommandProvider).isLoading;
    final snapshot = ref.watch(attendanceEngineProvider).value;
    final excludesClasses =
        _type == AcademicCalendarEventType.holiday ||
        _type == AcademicCalendarEventType.collegeClosed;
    final impact = snapshot == null
        ? null
        : AcademicCalendarImpactService.calculate(
            snapshot: snapshot,
            semester: widget.semester,
            startDate: _start,
            endDate: _end,
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.event == null
                    ? 'Add academic date'
                    : 'Edit academic date',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quick presets',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final preset in _calendarPresets)
                    ActionChip(
                      avatar: Icon(preset.icon, size: 18),
                      label: Text(preset.label),
                      onPressed: () => _applyPreset(preset),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AcademicCalendarEventType>(
                key: ValueKey(_type),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final type in AcademicCalendarEventType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(_eventVisual(context, type).label),
                    ),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('calendar_event_title'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Starts',
                      date: _start,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DateButton(
                      label: 'Ends',
                      date: _end,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              if (excludesClasses && impact != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${impact.scheduledClasses} scheduled ${impact.scheduledClasses == 1 ? 'class' : 'classes'} across ${impact.classDays} class ${impact.classDays == 1 ? 'day' : 'days'} will be hidden and excluded automatically. Existing marks stay preserved.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: const Key('save_calendar_event'),
                onPressed: busy ? null : _save,
                child: Text(widget.event == null ? 'Add date' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: widget.semester.startDate,
      lastDate: widget.semester.endDate,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date.')),
      );
      return;
    }
    final old = widget.event;
    final controller = ref.read(academicCalendarCommandProvider.notifier);
    final success = old == null
        ? await controller.create((
            semesterId: widget.semester.id,
            title: _title.text.trim(),
            type: _type,
            startDate: _start,
            endDate: _end,
            note: _note.text.trim(),
          ))
        : await controller.updateEvent((
            id: old.id,
            semesterId: old.semesterId,
            title: _title.text.trim(),
            type: _type,
            startDate: _start,
            endDate: _end,
            note: _note.text.trim(),
            createdAt: old.createdAt,
            updatedAt: old.updatedAt,
          ));
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the calendar entry.')),
      );
    }
  }

  void _applyPreset(_CalendarPreset preset) {
    setState(() {
      _type = preset.type;
      if (_title.text.trim().isEmpty) _title.text = preset.defaultTitle;
    });
  }
}

typedef _CalendarPreset = ({
  String label,
  String defaultTitle,
  IconData icon,
  AcademicCalendarEventType type,
});

const _calendarPresets = <_CalendarPreset>[
  (
    label: 'Holiday',
    defaultTitle: 'College holiday',
    icon: Icons.beach_access_outlined,
    type: AcademicCalendarEventType.holiday,
  ),
  (
    label: 'Vacation',
    defaultTitle: 'Vacation',
    icon: Icons.luggage_outlined,
    type: AcademicCalendarEventType.holiday,
  ),
  (
    label: 'Study leave',
    defaultTitle: 'Study leave',
    icon: Icons.auto_stories_outlined,
    type: AcademicCalendarEventType.holiday,
  ),
  (
    label: 'Exam period',
    defaultTitle: 'Exam period',
    icon: Icons.assignment_outlined,
    type: AcademicCalendarEventType.examPeriod,
  ),
];

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    child: Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(DateFormat.MMMd().format(date)),
      ],
    ),
  );
}

({IconData icon, Color color, String label}) _eventVisual(
  BuildContext context,
  AcademicCalendarEventType type,
) {
  final colors = Theme.of(context).colorScheme;
  final semantic = Theme.of(context).extension<AppSemanticColors>()!;
  return switch (type) {
    AcademicCalendarEventType.event => (
      icon: Icons.event_note_rounded,
      color: colors.primary,
      label: 'Event',
    ),
    AcademicCalendarEventType.examPeriod => (
      icon: Icons.assignment_rounded,
      color: semantic.warning,
      label: 'Exam period',
    ),
    AcademicCalendarEventType.holiday => (
      icon: Icons.beach_access_rounded,
      color: semantic.info,
      label: 'Holiday',
    ),
    AcademicCalendarEventType.collegeClosed => (
      icon: Icons.event_busy_rounded,
      color: colors.error,
      label: 'College closed',
    ),
  };
}

DateTime _initialDate(Semester semester) {
  final today = DateUtils.dateOnly(DateTime.now());
  if (today.isBefore(semester.startDate)) return semester.startDate;
  if (today.isAfter(semester.endDate)) return semester.endDate;
  return today;
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
