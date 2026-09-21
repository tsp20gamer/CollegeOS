import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/notifications/presentation/reminder_picker.dart';
import 'package:college_os/features/tasks/application/task_providers.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({
    required this.semesterId,
    required this.subjects,
    this.task,
    super.key,
  });

  final int semesterId;
  final List<Subject> subjects;
  final CollegeTask? task;

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late CollegeTaskType _type;
  late TaskPriority _priority;
  int? _subjectId;
  DateTime? _dueDate;
  int? _dueTime;
  DateTime? _reminderAt;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _type = task?.type ?? CollegeTaskType.general;
    _priority = task?.priority ?? TaskPriority.medium;
    _subjectId = task?.subjectId;
    _dueDate = task?.dueDate;
    _dueTime = task?.dueTime;
    _reminderAt = task?.reminderAt?.toLocal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(taskCommandProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Edit task' : 'Add task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('task_title_field'),
                  controller: _titleController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.task_alt_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task title'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('task_description_field'),
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<CollegeTaskType>(
                  key: const Key('task_type_field'),
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final type in CollegeTaskType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                  ],
                  onChanged: command.isLoading
                      ? null
                      : (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<int?>(
                  key: const Key('task_subject_field'),
                  initialValue: _subjectId,
                  decoration: InputDecoration(
                    labelText: _type == CollegeTaskType.assignment
                        ? 'Subject'
                        : 'Subject (optional)',
                    prefixIcon: const Icon(Icons.menu_book_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No subject'),
                    ),
                    for (final subject in widget.subjects)
                      DropdownMenuItem<int?>(
                        value: subject.id,
                        child: Text(subject.name),
                      ),
                  ],
                  onChanged: command.isLoading
                      ? null
                      : (value) => setState(() => _subjectId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Priority', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<TaskPriority>(
                  key: const Key('task_priority_field'),
                  segments: const [
                    ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                    ButtonSegment(
                      value: TaskPriority.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(
                      value: TaskPriority.high,
                      label: Text('High'),
                    ),
                  ],
                  selected: {_priority},
                  showSelectedIcon: false,
                  onSelectionChanged: command.isLoading
                      ? null
                      : (value) => setState(() => _priority = value.single),
                ),
                const SizedBox(height: AppSpacing.md),
                _PickerTile(
                  key: const Key('task_due_date_field'),
                  icon: Icons.event_rounded,
                  label: 'Due date',
                  value: _dueDate == null
                      ? 'No deadline'
                      : DateFormat.yMMMMd().format(_dueDate!),
                  onTap: _pickDueDate,
                  onClear: _dueDate == null
                      ? null
                      : () => setState(() {
                          _dueDate = null;
                          _dueTime = null;
                        }),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PickerTile(
                  key: const Key('task_due_time_field'),
                  icon: Icons.schedule_rounded,
                  label: 'Due time',
                  value: _dueTime == null
                      ? 'No specific time'
                      : _formatMinutes(context, _dueTime!),
                  enabled: _dueDate != null,
                  onTap: _pickDueTime,
                  onClear: _dueTime == null
                      ? null
                      : () => setState(() => _dueTime = null),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReminderPicker(
                  key: const Key('task_reminder_field'),
                  eventTime: _taskEventTime,
                  reminderAt: _reminderAt,
                  onChanged: (value) => setState(() => _reminderAt = value),
                ),
                if (_reminderAt != null) const ReminderPermissionNotice(),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  key: const Key('save_task_button'),
                  onPressed: command.isLoading ? null : _save,
                  icon: command.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isEditing ? 'Save changes' : 'Create task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) setState(() => _dueDate = selected);
  }

  Future<void> _pickDueTime() async {
    if (_dueDate == null) return;
    final current = _dueTime ?? 17 * 60;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (selected != null && mounted) {
      setState(() => _dueTime = selected.hour * 60 + selected.minute);
    }
  }

  DateTime? get _taskEventTime => _dueDate == null
      ? null
      : DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          (_dueTime ?? 9 * 60) ~/ 60,
          (_dueTime ?? 9 * 60) % 60,
        );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == CollegeTaskType.assignment && _subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a subject for this assignment.')),
      );
      return;
    }
    if (_reminderAt != null && !_reminderAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future reminder time.')),
      );
      return;
    }
    final controller = ref.read(taskCommandProvider.notifier);
    final existing = widget.task;
    final success = existing == null
        ? await controller.create((
            semesterId: widget.semesterId,
            subjectId: _subjectId,
            title: _titleController.text,
            description: _descriptionController.text,
            type: _type,
            priority: _priority,
            dueDate: _dueDate,
            dueTime: _dueTime,
            reminderAt: _reminderAt?.toUtc(),
          ))
        : await controller.updateTask((
            id: existing.id,
            semesterId: existing.semesterId,
            subjectId: _subjectId,
            title: _titleController.text,
            description: _descriptionController.text,
            type: _type,
            priority: _priority,
            dueDate: _dueDate,
            dueTime: _dueTime,
            reminderAt: _reminderAt?.toUtc(),
            isCompleted: existing.isCompleted,
            completedAt: existing.completedAt,
            createdAt: existing.createdAt,
            updatedAt: existing.updatedAt,
          ));
    if (!mounted) return;
    if (success) {
      final denied = controller.reminderPermissionDenied;
      if (denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reminder saved, but Android notifications are not enabled.',
            ),
          ),
        );
      } else if (controller.reminderSchedulingFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Task saved, but Android could not schedule the reminder. Open Settings → Notifications to send a test.',
            ),
          ),
        );
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this task.')),
      );
    }
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(enabled ? value : 'Choose a due date first'),
    trailing: onClear == null
        ? const Icon(Icons.chevron_right_rounded)
        : IconButton(
            tooltip: 'Clear $label',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
    onTap: enabled ? onTap : null,
  );
}

String _typeLabel(CollegeTaskType type) => switch (type) {
  CollegeTaskType.general => 'General',
  CollegeTaskType.assignment => 'Assignment',
  CollegeTaskType.study => 'Study',
};

String _formatMinutes(BuildContext context, int minutes) =>
    MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
