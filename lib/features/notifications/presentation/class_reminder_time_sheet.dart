import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';
import 'package:flutter/material.dart';

/// Asks for a class reminder lead time, in hours and minutes before the class.
///
/// One picker backs both a single class's reminder in the timetable form and the
/// class-notifier default in Settings, so the range, the preview and the widget
/// keys stay identical wherever a lead time is chosen. Returns the chosen lead
/// time in minutes, or `null` when the sheet is dismissed.
Future<int?> showClassReminderTimeSheet(
  BuildContext context, {
  required int initialMinutesBefore,
  String keyPrefix = 'timetable_reminder',
  String title = 'Custom reminder',
  String description =
      'Choose how long before the class CollegeOS should remind you.',
  String confirmLabel = 'Set reminder',
}) {
  final initial = initialMinutesBefore.clamp(
    minClassReminderLeadMinutes,
    maxClassReminderLeadMinutes,
  );
  final hours = initial ~/ 60;
  final minutes = initial % 60;
  // The stored value is always selectable, so opening the picker can never
  // round an existing reminder away.
  final hourOptions = <int>{
    for (var value = 0; value <= 12; value++) value,
    hours,
  }.toList()..sort();
  final minuteOptions = <int>{
    for (var value = 0; value < 60; value += 5) value,
    minutes,
  }.toList()..sort();
  var selectedHours = hours;
  var selectedMinutes = minutes;
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final total = selectedHours * 60 + selectedMinutes;
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
                  title,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: Key('${keyPrefix}_hours_field'),
                        initialValue: selectedHours,
                        decoration: const InputDecoration(labelText: 'Hours'),
                        items: [
                          for (final value in hourOptions)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) => setSheetState(
                          () => selectedHours = value ?? selectedHours,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: Key('${keyPrefix}_minutes_field'),
                        initialValue: selectedMinutes,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                        items: [
                          for (final value in minuteOptions)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) => setSheetState(
                          () => selectedMinutes = value ?? selectedMinutes,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Reminds you ${formatClassReminderLead(total)}.',
                  key: Key('${keyPrefix}_preview'),
                  style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: Key('${keyPrefix}_save_button'),
                  onPressed: () => Navigator.pop(sheetContext, total),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
