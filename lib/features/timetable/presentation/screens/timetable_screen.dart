import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/effects.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notes/presentation/widgets/note_editor_sheet.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:college_os/features/timetable/presentation/widgets/timetable_entry_form_sheet.dart';
import 'package:college_os/features/timetable/presentation/widgets/timetable_import_sheet.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  late int _selectedWeekday;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selectedWeekday = timetableWeekdays.contains(today)
        ? today
        : DateTime.monday;
  }

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final entriesAsync = ref.watch(timetableEntriesProvider);
    final scheduleAsync = ref.watch(timetableScheduleProvider);
    final nextAsync = ref.watch(nextClassProvider);
    final defaultAttendanceTarget =
        ref.watch(collegeSettingsProvider).value?.defaultAttendanceTarget ??
        .75;
    final activeSubjects =
        subjectsAsync.value
            ?.where((subject) => !subject.isArchived)
            .toList(growable: false) ??
        const <Subject>[];
    final entries = entriesAsync.value ?? const <TimetableEntry>[];

    return AppScaffold(
      title: 'Timetable',
      subtitle: semester.value?.name ?? 'A practical view of your week.',
      showSettingsAction: true,
      actions: [
        IconButton(
          key: const Key('import_timetable_button'),
          tooltip: 'Import timetable CSV',
          onPressed: semester.value == null
              ? null
              : () => showTimetableImportSheet(
                  context,
                  semester: semester.value!,
                  subjects: activeSubjects,
                  entries: entries,
                  defaultAttendanceTarget: defaultAttendanceTarget,
                ),
          icon: const Icon(Icons.upload_file_outlined),
        ),
        IconButton(
          key: const Key('timetable_exceptions_button'),
          tooltip: 'One-day changes',
          onPressed: semester.value == null
              ? null
              : () => context.push(RoutePaths.timetableExceptions),
          icon: const Icon(Icons.event_repeat_outlined),
        ),
        IconButton.filledTonal(
          key: const Key('add_timetable_entry_button'),
          tooltip: 'Add class',
          onPressed: semester.value == null || activeSubjects.isEmpty
              ? null
              : () => _showEntryForm(
                  semesterId: semester.value!.id,
                  semesterStart: semester.value!.startDate,
                  semesterEnd: semester.value!.endDate,
                  subjects: activeSubjects,
                  entries: entries,
                  initialWeekday: _selectedWeekday,
                ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: semester.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          title: 'Could not load the semester',
          message: error.toString(),
        ),
        data: (activeSemester) {
          if (activeSemester == null) {
            return const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No active semester',
              message: 'Make a semester active before building a timetable.',
            );
          }
          if (subjectsAsync.isLoading || entriesAsync.isLoading) {
            return const LoadingState(label: 'Loading timetable');
          }
          if (subjectsAsync.hasError || entriesAsync.hasError) {
            return ErrorState(
              title: 'Could not load timetable',
              message: '${subjectsAsync.error ?? entriesAsync.error}',
            );
          }
          if (activeSubjects.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Add a subject first',
              message:
                  'Classes are linked to subjects in your active semester.',
              action: FilledButton.icon(
                onPressed: () => context.push(RoutePaths.subjects),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Manage subjects'),
              ),
            );
          }
          return scheduleAsync.when(
            loading: () => const LoadingState(label: 'Loading timetable'),
            error: (error, _) => ErrorState(
              title: 'Could not load timetable',
              message: error.toString(),
            ),
            data: (schedule) => _buildSchedule(
              activeSemester,
              activeSubjects,
              entries,
              schedule,
              nextAsync.value ??
                  NextClassService.calculate(
                    schedule: schedule,
                    now: DateTime.now(),
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSchedule(
    Semester semester,
    List<Subject> subjects,
    List<TimetableEntry> entries,
    List<ScheduledClass> schedule,
    NextClassResult next,
  ) {
    final semesterId = semester.id;
    final selected =
        schedule
            .where((item) => item.entry.weekday == _selectedWeekday)
            .toList(growable: false)
          ..sort((a, b) => a.entry.startTime.compareTo(b.entry.startTime));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DaySelector(
          selected: _selectedWeekday,
          schedule: schedule,
          onSelected: (day) => setState(() => _selectedWeekday = day),
        ),
        if (schedule.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _NextClassCard(result: next),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                timetableDayNames[_selectedWeekday]!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${selected.length} ${selected.length == 1 ? 'class' : 'classes'}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (selected.isEmpty)
          EmptyState(
            icon: Icons.event_available_rounded,
            title: 'No classes on ${timetableDayNames[_selectedWeekday]}',
            message:
                'This day is clear. Add a class whenever your schedule changes.',
            action: FilledButton.icon(
              onPressed: () => _showEntryForm(
                semesterId: semesterId,
                semesterStart: semester.startDate,
                semesterEnd: semester.endDate,
                subjects: subjects,
                entries: entries,
                initialWeekday: _selectedWeekday,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add class'),
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < selected.length; index++) ...[
                _ClassCard(
                  scheduledClass: selected[index],
                  isCurrent: next.currentClasses.any(
                    (item) => item.entry.id == selected[index].entry.id,
                  ),
                  onEdit: () => _showEntryForm(
                    semesterId: semesterId,
                    semesterStart: semester.startDate,
                    semesterEnd: semester.endDate,
                    subjects: subjects,
                    entries: entries,
                    initialWeekday: selected[index].entry.weekday,
                    entry: selected[index].entry,
                  ),
                  onDuplicate: () => _duplicateEntry(
                    semesterId: semesterId,
                    semesterStart: semester.startDate,
                    semesterEnd: semester.endDate,
                    subjects: subjects,
                    entries: entries,
                    source: selected[index].entry,
                  ),
                  onDelete: () => _deleteEntry(selected[index], semester),
                ),
                if (index != selected.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }

  Future<void> _showEntryForm({
    required int semesterId,
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required List<Subject> subjects,
    required List<TimetableEntry> entries,
    required int initialWeekday,
    TimetableEntry? entry,
    TimetableEntry? duplicateSource,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => TimetableEntryFormSheet(
      semesterId: semesterId,
      semesterStart: semesterStart,
      semesterEnd: semesterEnd,
      subjects: subjects,
      allEntries: entries,
      initialWeekday: initialWeekday,
      entry: entry,
      duplicateSource: duplicateSource,
    ),
  );

  Future<void> _duplicateEntry({
    required int semesterId,
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required List<Subject> subjects,
    required List<TimetableEntry> entries,
    required TimetableEntry source,
  }) async {
    final day = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Duplicate to another day'),
        children: [
          for (final weekday in timetableWeekdays)
            if (weekday != source.weekday)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, weekday),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(timetableDayNames[weekday]!),
                ),
              ),
        ],
      ),
    );
    if (day == null || !mounted) return;
    await _showEntryForm(
      semesterId: semesterId,
      semesterStart: semesterStart,
      semesterEnd: semesterEnd,
      subjects: subjects,
      entries: entries,
      initialWeekday: day,
      duplicateSource: source,
    );
  }

  Future<void> _deleteEntry(ScheduledClass item, Semester semester) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text(
          'Remove ${item.subject.name} from ${timetableDayNames[item.entry.weekday]}? '
          'Existing attendance records are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final effectiveFrom = today.isBefore(semester.startDate)
        ? semester.startDate
        : today.isAfter(semester.endDate)
        ? semester.endDate
        : today;
    final success = await ref
        .read(timetableCommandProvider.notifier)
        .deleteEntry(item.entry.id, effectiveFrom: effectiveFrom);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Class deleted' : 'Could not delete class'),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selected,
    required this.schedule,
    required this.onSelected,
  });

  final int selected;
  final List<ScheduledClass> schedule;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now().weekday;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      label: 'Timetable days',
      child: Row(
        children: [
          for (final day in timetableWeekdays)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  key: Key('timetable_day_$day'),
                  onTap: () => onSelected(day),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: reduceMotion ? Duration.zero : AppDurations.fast,
                    curve: AppCurves.standard,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected == day
                          ? colors.primaryContainer
                          : colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: day == today
                          ? Border.all(color: colors.primary)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          timetableDayShortNames[day]!,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: selected == day
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${schedule.where((item) => item.entry.weekday == day).length}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: selected == day
                                    ? colors.onPrimaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.result});

  final NextClassResult result;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final current = result.currentClass;
    final next = result.nextClass;
    final ScheduledClass? item = current ?? next;
    if (item == null) return const SizedBox.shrink();
    final title = current != null
        ? result.currentClasses.length > 1
              ? '${result.currentClasses.length} classes in progress'
              : 'In progress now'
        : result.nextIsToday
        ? 'Next class today'
        : result.daysUntilNext == 1
        ? 'First class tomorrow'
        : 'Next scheduled class';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.infoContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: semantic.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.near_me_rounded, color: semantic.onInfoContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: semantic.onInfoContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${item.subject.name}  •  ${_formatTime(context, item.entry.startTime)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: semantic.onInfoContainer,
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

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.scheduledClass,
    required this.isCurrent,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ScheduledClass scheduledClass;
  final bool isCurrent;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final item = scheduledClass;
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final room = item.entry.room.isNotEmpty
        ? item.entry.room
        : item.subject.room;
    final accent = Color(item.subject.displayColor);
    return Card(
      color: isCurrent ? colors.primaryContainer.withValues(alpha: .32) : null,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xxs,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                key: Key('timetable_subject_accent_${item.entry.id}'),
                width: 4,
                height: 58,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppGlows.subjectAccent(
                    accent,
                    brightness: Theme.of(context).brightness,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(context, item.entry.startTime),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _formatTime(context, item.entry.endTime),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.subject.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isCurrent)
                          StatusBadge(
                            label: 'NOW',
                            icon: Icons.play_arrow_rounded,
                            foreground: semantic.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        if (item.subject.shortCode.isNotEmpty)
                          item.subject.shortCode,
                        if (room.isNotEmpty) room,
                        if (item.subject.professor.isNotEmpty)
                          item.subject.professor,
                      ].join('  •  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ClassAction>(
                tooltip: 'Class actions',
                onSelected: (action) => switch (action) {
                  _ClassAction.edit => onEdit(),
                  _ClassAction.addNote => NoteEditorSheet.show(
                    context,
                    subjectId: item.subject.id,
                    semesterId: item.subject.semesterId,
                    subjectName: item.subject.name,
                  ),
                  _ClassAction.viewNotes => context.push(
                    RoutePaths.subjectNotes.replaceFirst(
                      ':subjectId',
                      '${item.subject.id}',
                    ),
                  ),
                  _ClassAction.duplicate => onDuplicate(),
                  _ClassAction.delete => onDelete(),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ClassAction.viewNotes,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notes_rounded),
                      title: Text('View notes'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ClassAction.addNote,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_note_rounded),
                      title: Text('Add note'),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _ClassAction.edit,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit class'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ClassAction.duplicate,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.copy_rounded),
                      title: Text('Duplicate to another day'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ClassAction.delete,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete class'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ClassAction { edit, addNote, viewNotes, duplicate, delete }

String _formatTime(BuildContext context, int minutes) {
  final safeMinutes = minutes == 1440 ? 0 : minutes;
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: safeMinutes ~/ 60, minute: safeMinutes % 60),
  );
}
