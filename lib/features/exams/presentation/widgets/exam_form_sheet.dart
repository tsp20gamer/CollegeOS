import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/exams/application/exam_mark_providers.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/notifications/presentation/reminder_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ExamFormSheet extends ConsumerStatefulWidget {
  const ExamFormSheet({
    required this.semesterId,
    required this.subjects,
    this.exam,
    super.key,
  });

  final int semesterId;
  final List<Subject> subjects;
  final Exam? exam;

  @override
  ConsumerState<ExamFormSheet> createState() => _ExamFormSheetState();
}

class _ExamFormSheetState extends ConsumerState<ExamFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _room;
  late final TextEditingController _syllabus;
  late final TextEditingController _maximum;
  late final TextEditingController _obtained;
  late int _subjectId;
  late DateTime _date;
  int? _startTime;
  int? _endTime;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    final exam = widget.exam;
    _subjectId = exam?.subjectId ?? widget.subjects.first.id;
    _date = exam?.examDate ?? DateTime.now();
    _startTime = exam?.startTime;
    _endTime = exam?.endTime;
    _reminderAt = exam?.reminderAt?.toLocal();
    _name = TextEditingController(text: exam?.name ?? '');
    _type = TextEditingController(text: exam?.examType ?? '');
    _room = TextEditingController(text: exam?.room ?? '');
    _syllabus = TextEditingController(text: exam?.syllabus ?? '');
    _maximum = TextEditingController(text: _number(exam?.maxMarks));
    _obtained = TextEditingController(text: _number(exam?.obtainedMarks));
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _room.dispose();
    _syllabus.dispose();
    _maximum.dispose();
    _obtained.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(examCommandProvider);
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
                  widget.exam == null ? 'Add exam' : 'Edit exam',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<int>(
                  key: const Key('exam_subject_field'),
                  initialValue: _subjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  items: [
                    for (final subject in widget.subjects)
                      DropdownMenuItem(
                        value: subject.id,
                        child: Text(subject.name),
                      ),
                  ],
                  onChanged: command.isLoading
                      ? null
                      : (value) => setState(() => _subjectId = value!),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('exam_name_field'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Exam name',
                    prefixIcon: Icon(Icons.quiz_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('exam_type_field'),
                  controller: _type,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Exam type',
                    hintText: 'Midterm, practical, viva…',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                _PickerTile(
                  key: const Key('exam_date_field'),
                  icon: Icons.event_rounded,
                  label: 'Date',
                  value: DateFormat.yMMMMd().format(_date),
                  onTap: _pickDate,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        key: const Key('exam_start_field'),
                        icon: Icons.schedule_rounded,
                        label: 'Start',
                        value: _startTime == null
                            ? 'Optional'
                            : _time(context, _startTime!),
                        onTap: () => _pickTime(start: true),
                        onClear: _startTime == null
                            ? null
                            : () => setState(() => _startTime = null),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PickerTile(
                        key: const Key('exam_end_field'),
                        icon: Icons.schedule_rounded,
                        label: 'End',
                        value: _endTime == null
                            ? 'Optional'
                            : _time(context, _endTime!),
                        onTap: () => _pickTime(start: false),
                        onClear: _endTime == null
                            ? null
                            : () => setState(() => _endTime = null),
                      ),
                    ),
                  ],
                ),
                if (_startTime != null &&
                    _endTime != null &&
                    _endTime! <= _startTime!) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'End time must be after start time.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                ReminderPicker(
                  key: const Key('exam_reminder_field'),
                  eventTime: _examEventTime,
                  reminderAt: _reminderAt,
                  onChanged: (value) => setState(() => _reminderAt = value),
                ),
                if (_reminderAt != null) const ReminderPermissionNotice(),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('exam_room_field'),
                  controller: _room,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('exam_syllabus_field'),
                  controller: _syllabus,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Syllabus',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.subject_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('exam_max_marks_field'),
                        controller: _maximum,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalFormatter],
                        decoration: const InputDecoration(
                          labelText: 'Maximum marks',
                        ),
                        validator: _positiveOptional,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        key: const Key('exam_obtained_marks_field'),
                        controller: _obtained,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalFormatter],
                        decoration: const InputDecoration(
                          labelText: 'Obtained marks',
                        ),
                        validator: _obtainedValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  key: const Key('save_exam_button'),
                  onPressed: command.isLoading ? null : _save,
                  icon: command.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    widget.exam == null ? 'Create exam' : 'Save changes',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _pickTime({required bool start}) async {
    final minutes = start ? (_startTime ?? 9 * 60) : (_endTime ?? 10 * 60);
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (selected == null || !mounted) return;
    setState(() {
      final value = selected.hour * 60 + selected.minute;
      if (start) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime != null && _endTime != null && _endTime! <= _startTime!) {
      return;
    }
    if (_reminderAt != null && !_reminderAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future reminder time.')),
      );
      return;
    }
    final existing = widget.exam;
    final draft = (
      semesterId: widget.semesterId,
      subjectId: _subjectId,
      name: _name.text,
      examType: _type.text,
      examDate: _date,
      startTime: _startTime,
      endTime: _endTime,
      room: _room.text,
      syllabus: _syllabus.text,
      maxMarks: _parse(_maximum.text),
      obtainedMarks: _parse(_obtained.text),
      reminderAt: _reminderAt?.toUtc(),
    );
    final controller = ref.read(examCommandProvider.notifier);
    final success = existing == null
        ? await controller.create(draft)
        : await controller.updateExam((
            id: existing.id,
            semesterId: draft.semesterId,
            subjectId: draft.subjectId,
            name: draft.name,
            examType: draft.examType,
            examDate: draft.examDate,
            startTime: draft.startTime,
            endTime: draft.endTime,
            room: draft.room,
            syllabus: draft.syllabus,
            maxMarks: draft.maxMarks,
            obtainedMarks: draft.obtainedMarks,
            reminderAt: draft.reminderAt,
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
              'Exam saved, but Android could not schedule the reminder. Open Settings → Notifications to send a test.',
            ),
          ),
        );
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this exam.')),
      );
    }
  }

  String? _obtainedValidator(String? value) {
    final obtained = _parse(value ?? '');
    if (value != null && value.trim().isNotEmpty && obtained == null) {
      return 'Enter valid marks';
    }
    if (obtained != null && obtained < 0) return 'Cannot be negative';
    final maximum = _parse(_maximum.text);
    if (obtained != null && maximum != null && obtained > maximum) {
      return 'Above maximum';
    }
    return null;
  }

  DateTime get _examEventTime => DateTime(
    _date.year,
    _date.month,
    _date.day,
    (_startTime ?? 9 * 60) ~/ 60,
    (_startTime ?? 9 * 60) % 60,
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
    trailing: onClear == null
        ? const Icon(Icons.chevron_right_rounded)
        : IconButton(
            onPressed: onClear,
            tooltip: 'Clear $label',
            icon: const Icon(Icons.close_rounded),
          ),
    onTap: onTap,
  );
}

final _decimalFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d{0,2}'),
);

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;

String? _positiveOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final number = double.tryParse(value);
  if (number == null || number <= 0) return 'Must be greater than zero';
  return null;
}

double? _parse(String value) =>
    value.trim().isEmpty ? null : double.tryParse(value.trim());

String _number(double? value) => value == null
    ? ''
    : value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String _time(BuildContext context, int minutes) => MaterialLocalizations.of(
  context,
).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
