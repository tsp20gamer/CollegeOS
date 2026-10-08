import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimetableEntryFormSheet extends ConsumerStatefulWidget {
  const TimetableEntryFormSheet({
    required this.semesterId,
    required this.subjects,
    required this.allEntries,
    required this.initialWeekday,
    required this.semesterStart,
    required this.semesterEnd,
    this.entry,
    this.duplicateSource,
    this.oneDayDate,
    super.key,
  });

  final int semesterId;
  final List<Subject> subjects;
  final List<TimetableEntry> allEntries;
  final int initialWeekday;
  final DateTime semesterStart;
  final DateTime semesterEnd;
  final TimetableEntry? entry;
  final TimetableEntry? duplicateSource;
  final DateTime? oneDayDate;

  @override
  ConsumerState<TimetableEntryFormSheet> createState() =>
      _TimetableEntryFormSheetState();
}

class _TimetableEntryFormSheetState
    extends ConsumerState<TimetableEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomController;
  late final TextEditingController _noteController;
  late int _subjectId;
  late int _weekday;
  late int _startTime;
  late int _endTime;
  late DateTime _effectiveFrom;
  int? _reminderMinutesBefore;

  bool get _isEditing => widget.entry != null;
  bool get _isOneDay => widget.oneDayDate != null;

  @override
  void initState() {
    super.initState();
    final source = widget.entry ?? widget.duplicateSource;
    _subjectId = source?.subjectId ?? widget.subjects.first.id;
    _weekday = widget.oneDayDate?.weekday ?? widget.initialWeekday;
    _startTime = source?.startTime ?? 9 * 60;
    _endTime = source?.endTime ?? 10 * 60;
    final today = DateUtils.dateOnly(DateTime.now());
    _effectiveFrom = today.isBefore(widget.semesterStart)
        ? widget.semesterStart
        : today.isAfter(widget.semesterEnd)
        ? widget.semesterEnd
        : today;
    final subject = widget.subjects.firstWhere((item) => item.id == _subjectId);
    _roomController = TextEditingController(
      text: source?.room.isNotEmpty == true ? source!.room : subject.room,
    );
    _noteController = TextEditingController(text: source?.note ?? '');
    _reminderMinutesBefore = source?.reminderMinutesBefore;
  }

  @override
  void dispose() {
    _roomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(timetableCommandProvider);
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
                  _isEditing
                      ? 'Edit class'
                      : _isOneDay
                      ? 'Add extra class'
                      : widget.duplicateSource != null
                      ? 'Duplicate class'
                      : 'Add class',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<int>(
                  key: const Key('timetable_subject_field'),
                  initialValue: _subjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.menu_book_rounded),
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
                      : (value) {
                          if (value == null) return;
                          final oldSubject = widget.subjects.firstWhere(
                            (item) => item.id == _subjectId,
                          );
                          final newSubject = widget.subjects.firstWhere(
                            (item) => item.id == value,
                          );
                          setState(() => _subjectId = value);
                          if (_roomController.text.trim().isEmpty ||
                              _roomController.text.trim() == oldSubject.room) {
                            _roomController.text = newSubject.room;
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isOneDay)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Exception date',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(widget.oneDayDate!),
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    key: const Key('timetable_day_field'),
                    initialValue: _weekday,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      prefixIcon: Icon(Icons.today_rounded),
                    ),
                    items: [
                      for (final day in timetableWeekdays)
                        DropdownMenuItem(
                          value: day,
                          child: Text(timetableDayNames[day]!),
                        ),
                    ],
                    onChanged: command.isLoading
                        ? null
                        : (value) => setState(() => _weekday = value!),
                  ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        key: const Key('timetable_start_field'),
                        label: 'Start time',
                        minutes: _startTime,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TimeField(
                        key: const Key('timetable_end_field'),
                        label: 'End time',
                        minutes: _endTime,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                if (_endTime <= _startTime) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'End time must be after start time.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('timetable_room_field'),
                  controller: _roomController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Room',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ClassReminderPreset>(
                  key: const Key('timetable_reminder_field'),
                  initialValue: inferClassReminderPreset(_reminderMinutesBefore),
                  decoration: InputDecoration(
                    labelText: 'Reminder',
                    prefixIcon: const Icon(
                      Icons.notifications_active_outlined,
                    ),
                    helperText: _reminderHelper(),
                    helperMaxLines: 2,
                  ),
                  items: [
                    for (final preset in ClassReminderPreset.values)
                      DropdownMenuItem(
                        value: preset,
                        child: Text(preset.label),
                      ),
                  ],
                  onChanged: command.isLoading ? null : _onReminderChanged,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_repeat_rounded),
                    title: const Text('Apply schedule change from'),
                    subtitle: Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(_effectiveFrom),
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: command.isLoading ? null : _pickEffectiveDate,
                  ),
                  Text(
                    'Earlier timetable history and marked attendance stay unchanged.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('timetable_note_field'),
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const Key('save_timetable_entry_button'),
                  onPressed: command.isLoading ? null : _save,
                  icon: command.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isEditing ? 'Save changes' : 'Save class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final minutes = isStart ? _startTime : _endTime;
    final displayMinutes = minutes == 1440 ? 0 : minutes;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: displayMinutes ~/ 60,
        minute: displayMinutes % 60,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final selected = result.hour * 60 + result.minute;
      if (isStart) {
        final duration = _endTime - _startTime;
        _startTime = selected;
        if (duration > 0 && selected + duration <= 1440) {
          _endTime = selected + duration;
        }
      } else {
        _endTime = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _endTime <= _startTime) return;
    final overlaps = TimetableOverlapService.findOverlaps(
      entries: widget.allEntries,
      weekday: _weekday,
      startTime: _startTime,
      endTime: _endTime,
      excludingId: widget.entry?.id,
    );
    if (overlaps.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Schedule overlap'),
          content: Text(
            'This class overlaps ${overlaps.length == 1 ? 'another class' : '${overlaps.length} other classes'}. '
            'CollegeOS will keep both if you continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final room = _roomController.text;
    final note = _noteController.text;
    final existing = widget.entry;
    final controller = ref.read(timetableCommandProvider.notifier);
    final draft = (
      semesterId: widget.semesterId,
      subjectId: _subjectId,
      weekday: _weekday,
      startTime: _startTime,
      endTime: _endTime,
      room: room,
      note: note,
      reminderMinutesBefore: _reminderMinutesBefore,
    );
    final success = existing == null
        ? _isOneDay
              ? await controller.createOneDay(draft, widget.oneDayDate!)
              : await controller.create(draft)
        : await controller.updateEntry((
            id: existing.id,
            semesterId: existing.semesterId,
            subjectId: _subjectId,
            weekday: _weekday,
            startTime: _startTime,
            endTime: _endTime,
            room: room,
            note: note,
            reminderMinutesBefore: _reminderMinutesBefore,
          ), effectiveFrom: _effectiveFrom);
    if (!mounted) return;
    if (success) {
      if (controller.reminderPermissionDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Class saved, but Android notifications are not enabled.',
            ),
          ),
        );
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this class.')),
      );
    }
  }

  /// Lead time in words, resolved against this class's own start time.
  String _reminderHelper() {
    final minutes = _reminderMinutesBefore;
    if (minutes == null) return 'No reminder for this class';
    final displayMinutes = _startTime == 1440 ? 0 : _startTime;
    final start = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(
        hour: displayMinutes ~/ 60,
        minute: displayMinutes % 60,
      ),
    );
    return '${formatClassReminderLead(minutes)} a $start class';
  }

  Future<void> _onReminderChanged(ClassReminderPreset? preset) async {
    if (preset == null) return;
    if (preset == ClassReminderPreset.off) {
      setState(() => _reminderMinutesBefore = null);
      return;
    }
    if (preset != ClassReminderPreset.custom) {
      setState(() => _reminderMinutesBefore = preset.minutesBefore);
      return;
    }
    final custom = await _pickCustomLead();
    if (custom == null || !mounted) return;
    setState(() => _reminderMinutesBefore = custom);
  }

  /// The custom time setter: any lead time in hours and minutes before class.
  Future<int?> _pickCustomLead() async {
    final initial = _reminderMinutesBefore ?? 15;
    var hours = initial ~/ 60;
    var minutes = initial % 60;
    // The stored value is always selectable, so opening Custom can never round
    // an existing reminder away.
    final hourOptions = <int>{
      for (var value = 0; value <= 12; value++) value,
      hours,
    }.toList()..sort();
    final minuteOptions = <int>{
      for (var value = 0; value < 60; value += 5) value,
      minutes,
    }.toList()..sort();
    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final total = hours * 60 + minutes;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Custom reminder',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose how long before the class CollegeOS should remind you.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: const Key('timetable_reminder_hours_field'),
                          initialValue: hours,
                          decoration: const InputDecoration(
                            labelText: 'Hours',
                          ),
                          items: [
                            for (final value in hourOptions)
                              DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => hours = value ?? hours),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: const Key('timetable_reminder_minutes_field'),
                          initialValue: minutes,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                          ),
                          items: [
                            for (final value in minuteOptions)
                              DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                          ],
                          onChanged: (value) =>
                              setSheetState(() => minutes = value ?? minutes),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Reminds you ${formatClassReminderLead(hours * 60 + minutes)}.',
                    key: const Key('timetable_reminder_preview'),
                    style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                      color: Theme.of(sheetContext).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    key: const Key('save_custom_reminder_button'),
                    onPressed: () => Navigator.pop(sheetContext, total),
                    child: const Text('Set reminder'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickEffectiveDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: widget.semesterStart,
      lastDate: widget.semesterEnd,
      helpText: 'Apply timetable change from',
    );
    if (value != null && mounted) setState(() => _effectiveFrom = value);
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onTap,
    super.key,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayMinutes = minutes == 1440 ? 0 : minutes;
    final time = TimeOfDay(
      hour: displayMinutes ~/ 60,
      minute: displayMinutes % 60,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(MaterialLocalizations.of(context).formatTimeOfDay(time)),
      ),
    );
  }
}
