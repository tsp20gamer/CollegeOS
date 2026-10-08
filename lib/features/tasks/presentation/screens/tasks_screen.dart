import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/tasks/application/task_providers.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:college_os/features/tasks/domain/task_service.dart';
import 'package:college_os/features/tasks/presentation/widgets/task_form_sheet.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({this.openCreate = false, this.focusTaskId, super.key});

  final bool openCreate;
  final int? focusTaskId;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;
  bool _initialCreateShown = false;
  bool _focusedTaskShown = false;

  @override
  void didUpdateWidget(covariant TasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusTaskId != widget.focusTaskId) {
      _focusedTaskShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final tasksAsync = ref.watch(semesterTasksProvider);
    final subjects =
        subjectsAsync.value
            ?.where((subject) => !subject.isArchived)
            .toList(growable: false) ??
        const <Subject>[];
    final focusedTask = tasksAsync.value
        ?.where((task) => task.id == widget.focusTaskId)
        .firstOrNull;
    if (focusedTask != null &&
        !_focusedTaskShown &&
        semester.value != null &&
        !subjectsAsync.isLoading) {
      _focusedTaskShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTaskForm(
          semesterId: semester.value!.id,
          subjects: subjects,
          task: focusedTask,
        );
      });
    }
    if (widget.openCreate &&
        !_initialCreateShown &&
        semester.value != null &&
        !subjectsAsync.isLoading) {
      _initialCreateShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTaskForm(semesterId: semester.value!.id, subjects: subjects);
      });
    }
    return AppScaffold(
      title: 'Tasks',
      subtitle:
          semester.value?.name ?? 'Assignments and personal work, together.',
      showSearchAction: true,
      showSettingsAction: true,
      actions: [
        IconButton.filledTonal(
          key: const Key('add_task_button'),
          tooltip: 'Add task',
          onPressed: semester.value == null
              ? null
              : () => _showTaskForm(
                  semesterId: semester.value!.id,
                  subjects: subjects,
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
              message: 'Make a semester active before creating tasks.',
            );
          }
          if (tasksAsync.isLoading || subjectsAsync.isLoading) {
            return const LoadingState(label: 'Loading tasks');
          }
          if (tasksAsync.hasError || subjectsAsync.hasError) {
            return ErrorState(
              title: 'Could not load tasks',
              message: '${tasksAsync.error ?? subjectsAsync.error}',
            );
          }
          return _buildTasks(
            semesterId: activeSemester.id,
            tasks: tasksAsync.value!,
            subjects: subjects,
          );
        },
      ),
    );
  }

  Widget _buildTasks({
    required int semesterId,
    required List<CollegeTask> tasks,
    required List<Subject> subjects,
  }) {
    final now = DateTime.now();
    final visible = TaskService.filterAndSort(
      tasks: tasks,
      filter: _filter,
      now: now,
    );
    final bySubject = {for (final subject in subjects) subject.id: subject};
    final openTasks = tasks.where((task) => !task.isCompleted).toList();
    final overdue = openTasks
        .where(
          (task) => TaskService.dueState(task, now) == TaskDueState.overdue,
        )
        .length;
    final dueToday = openTasks
        .where((task) => TaskService.dueState(task, now) == TaskDueState.today)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TaskSummary(
          open: openTasks.length,
          dueToday: dueToday,
          overdue: overdue,
        ),
        const SizedBox(height: AppSpacing.md),
        // Compact filter chips: one row of controls instead of a segmented
        // control that competes with the list underneath it.
        Wrap(
          key: const Key('task_filter'),
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final filter in TaskFilter.values)
              FilterChip(
                key: Key('task_filter_${filter.name}'),
                selected: _filter == filter,
                showCheckmark: false,
                avatar: Icon(_filterIcon(filter), size: 17),
                label: Text(_filterLabel(filter)),
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                _filterTitle(_filter),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${visible.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          EmptyState(
            icon: _filter == TaskFilter.completed
                ? Icons.check_circle_outline_rounded
                : Icons.task_alt_rounded,
            title: _emptyTitle(_filter),
            message: _emptyMessage(_filter),
            action: _filter == TaskFilter.completed
                ? null
                : FilledButton.icon(
                    onPressed: () => _showTaskForm(
                      semesterId: semesterId,
                      subjects: subjects,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add task'),
                  ),
          )
        else
          AnimatedSwitcher(
            duration: AppDurations.fast,
            switchInCurve: AppCurves.standard,
            switchOutCurve: AppCurves.standard,
            child: PremiumSurface(
              key: ValueKey(
                '${_filter.name}-${visible.map((t) => '${t.id}:${t.isCompleted}').join(',')}',
              ),
              // One list surface: tasks are rows under a single heading rather
              // than a stack of separate cards.
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < visible.length; index++) ...[
                    _TaskRow(
                      task: visible[index],
                      subject: bySubject[visible[index].subjectId],
                      now: now,
                      onEdit: () => _showTaskForm(
                        semesterId: semesterId,
                        subjects: subjects,
                        task: visible[index],
                      ),
                      onToggle: () => _toggle(visible[index]),
                      onDelete: () => _delete(visible[index]),
                    ),
                    if (index != visible.length - 1)
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showTaskForm({
    required int semesterId,
    required List<Subject> subjects,
    CollegeTask? task,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) =>
        TaskFormSheet(semesterId: semesterId, subjects: subjects, task: task),
  );

  Future<void> _toggle(CollegeTask task) async {
    final success = await ref
        .read(taskCommandProvider.notifier)
        .setCompleted(task, completed: !task.isCompleted);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not update this task.')),
    );
  }

  Future<void> _delete(CollegeTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete “${task.title}”? This cannot be undone.'),
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
    final success = await ref
        .read(taskCommandProvider.notifier)
        .deleteTask(task.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Task deleted' : 'Could not delete task'),
      ),
    );
  }
}

/// One task in the shared list surface.
///
/// Completion is a rounded square rather than a circular radio glyph, the row
/// keeps the task's type, subject, deadline, reminder and priority, and the row
/// carries no card, border or shadow of its own.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.subject,
    required this.now,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final CollegeTask task;
  final Subject? subject;
  final DateTime now;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = TaskService.dueState(task, now);
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final stateColor = switch (state) {
      TaskDueState.overdue => colors.error,
      TaskDueState.today => semantic.warning,
      TaskDueState.upcoming => colors.primary,
      TaskDueState.noDeadline ||
      TaskDueState.completed => colors.onSurfaceVariant,
    };
    final theme = Theme.of(context);
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.xxs,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TaskCheckbox(
              key: Key('task_toggle_${task.id}'),
              completed: task.isCompleted,
              onTap: onToggle,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? colors.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                      _PriorityIndicator(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  // Plain meta text instead of a tinted subject chip, so a
                  // row never introduces a colour the system did not set.
                  Text(
                    task.type == CollegeTaskType.assignment && subject != null
                        ? 'Assignment • ${subject!.shortCode.isEmpty ? subject!.name : subject!.shortCode}'
                        : _typeLabel(task.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, size: 17, color: stateColor),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          _deadlineLabel(context, task, state),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: stateColor,
                                fontWeight: state == TaskDueState.overdue
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                        ),
                      ),
                      if (task.reminderAt != null)
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<_TaskAction>(
              tooltip: 'Task actions',
              onSelected: (action) => switch (action) {
                _TaskAction.edit => onEdit(),
                _TaskAction.toggle => onToggle(),
                _TaskAction.delete => onDelete(),
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _TaskAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: _TaskAction.toggle,
                  child: Text(
                    task.isCompleted ? 'Mark incomplete' : 'Complete',
                  ),
                ),
                const PopupMenuItem(
                  value: _TaskAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded-square completion control.
///
/// An open task shows a quiet neutral square and a completed one a solid
/// success square with a check, instead of the circular glyph that read like a
/// radio button.
class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    required this.completed,
    required this.onTap,
    super.key,
  });

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = theme.extension<AppSemanticColors>()!;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      toggled: completed,
      label: completed
          ? 'Completed. Tap to mark incomplete.'
          : 'Not completed. Tap to complete.',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppDurations.fast,
            curve: AppCurves.standard,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: completed
                  ? semantic.success
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({
    required this.open,
    required this.dueToday,
    required this.overdue,
  });

  final int open;
  final int dueToday;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            _SummaryMetric(label: 'Open', value: open, color: colors.primary),
            const SizedBox(height: 44, child: VerticalDivider()),
            _SummaryMetric(
              label: 'Due today',
              value: dueToday,
              color: semantic.warning,
            ),
            const SizedBox(height: 44, child: VerticalDivider()),
            _SummaryMetric(
              label: 'Overdue',
              value: overdue,
              color: colors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: '$value $label',
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _PriorityIndicator extends StatelessWidget {
  const _PriorityIndicator({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final colors = Theme.of(context).colorScheme;
    final color = switch (priority) {
      TaskPriority.low => colors.onSurfaceVariant,
      TaskPriority.medium => semantic.warning,
      TaskPriority.high => colors.error,
    };
    return Tooltip(
      message: '${_priorityLabel(priority)} priority',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 16, color: color),
          const SizedBox(width: 2),
          Text(
            _priorityLabel(priority),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

enum _TaskAction { edit, toggle, delete }

String _filterLabel(TaskFilter filter) => switch (filter) {
  TaskFilter.all => 'All',
  TaskFilter.today => 'Today',
  TaskFilter.upcoming => 'Upcoming',
  TaskFilter.completed => 'Completed',
};

IconData _filterIcon(TaskFilter filter) => switch (filter) {
  TaskFilter.all => Icons.inbox_outlined,
  TaskFilter.today => Icons.today_outlined,
  TaskFilter.upcoming => Icons.upcoming_outlined,
  TaskFilter.completed => Icons.check_circle_outline_rounded,
};

String _filterTitle(TaskFilter filter) => switch (filter) {
  TaskFilter.all => 'Active tasks',
  TaskFilter.today => 'Due today',
  TaskFilter.upcoming => 'Coming up',
  TaskFilter.completed => 'Completed',
};

String _emptyTitle(TaskFilter filter) => switch (filter) {
  TaskFilter.all => 'No active tasks',
  TaskFilter.today => 'Nothing due today',
  TaskFilter.upcoming => 'Nothing upcoming',
  TaskFilter.completed => 'No completed tasks',
};

String _emptyMessage(TaskFilter filter) => switch (filter) {
  TaskFilter.all => 'Capture assignments, study goals, and personal work here.',
  TaskFilter.today => 'Your schedule is clear for today.',
  TaskFilter.upcoming => 'Future deadlines will appear here.',
  TaskFilter.completed => 'Completed work will stay available here.',
};

String _typeLabel(CollegeTaskType type) => switch (type) {
  CollegeTaskType.general => 'General',
  CollegeTaskType.assignment => 'Assignment',
  CollegeTaskType.study => 'Study',
};

String _priorityLabel(TaskPriority priority) => switch (priority) {
  TaskPriority.low => 'Low',
  TaskPriority.medium => 'Medium',
  TaskPriority.high => 'High',
};

String _deadlineLabel(
  BuildContext context,
  CollegeTask task,
  TaskDueState state,
) {
  final date = task.dueDate;
  if (date == null) return 'No deadline';
  final time = task.dueTime == null
      ? ''
      : ' at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: task.dueTime! ~/ 60, minute: task.dueTime! % 60))}';
  return switch (state) {
    TaskDueState.overdue => 'Overdue • ${DateFormat.MMMd().format(date)}$time',
    TaskDueState.today => 'Due today$time',
    TaskDueState.upcoming => 'Due ${DateFormat.MMMd().format(date)}$time',
    TaskDueState.completed => 'Completed • ${DateFormat.MMMd().format(date)}',
    TaskDueState.noDeadline => 'No deadline',
  };
}
