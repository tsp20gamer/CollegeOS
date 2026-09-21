import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notifications/domain/reminder_option.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderPicker extends StatelessWidget {
  const ReminderPicker({
    required this.eventTime,
    required this.reminderAt,
    required this.onChanged,
    super.key,
  });

  final DateTime? eventTime;
  final DateTime? reminderAt;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final option = eventTime == null
        ? (reminderAt == null ? ReminderOption.off : ReminderOption.custom)
        : inferReminderOption(reminderAt, eventTime!);
    return DropdownButtonFormField<ReminderOption>(
      key: ValueKey(
        'reminder-${eventTime?.toIso8601String()}-'
        '${reminderAt?.toIso8601String()}',
      ),
      initialValue: option,
      decoration: InputDecoration(
        labelText: 'Reminder',
        prefixIcon: const Icon(Icons.notifications_outlined),
        helperText: reminderAt == null
            ? 'Off'
            : DateFormat('d MMM, h:mm a').format(reminderAt!),
      ),
      items: [
        for (final value in ReminderOption.values)
          if (eventTime != null ||
              value == ReminderOption.off ||
              value == ReminderOption.custom)
            DropdownMenuItem(value: value, child: Text(value.label)),
      ],
      onChanged: (value) async {
        if (value == null) return;
        if (value == ReminderOption.custom) {
          final custom = await _pickCustom(context);
          if (custom != null) onChanged(custom);
          return;
        }
        if (value == ReminderOption.off) {
          onChanged(null);
          return;
        }
        onChanged(calculateReminderTime(option: value, eventTime: eventTime!));
      },
    );
  }

  Future<DateTime?> _pickCustom(BuildContext context) async {
    final initial =
        reminderAt ?? eventTime ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class ReminderPermissionNotice extends StatelessWidget {
  const ReminderPermissionNotice({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(
      'Android notification permission will be requested when you save your first reminder.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
