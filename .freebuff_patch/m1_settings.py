from pathlib import Path

p = Path('lib/features/settings/presentation/screens/settings_screen.dart')
s = p.read_text(encoding='utf-8')
before = len(s)

# 1. Remove the temporary-diagnostics banner and the whole diagnostics card block.
start = s.index(
    "                  const SizedBox(height: AppSpacing.md),\n"
    "                  Container(\n"
    "                    padding: const EdgeInsets.all(AppSpacing.sm),\n"
    "                    decoration: BoxDecoration(\n"
    "                      color: Theme.of(\n"
    "                        context,\n"
    "                      ).colorScheme.secondaryContainer.withValues(alpha: .45),\n"
)
tail = (
    "                  const SizedBox(height: AppSpacing.md),\n"
    "                  FilledButton.icon(\n"
    "                    key: const Key('send_test_notification'),"
)
end = s.index(tail, start)
assert end > start
s = s[:start] + s[end:]

# 2. Remove the diagnostics card and its row widgets.
card_start = s.index("class _NotificationDiagnosticsCard extends StatelessWidget {")
next_class = s.index("class _AccessibilityStatusRow extends StatelessWidget {")
assert card_start < next_class
s = s[:card_start] + s[next_class:]

# 3. Drop the diagnostics invalidation left in the test-notification action.
stale = "\n                            ref.invalidate(notificationDiagnosticsProvider);"
assert s.count(stale) == 1, s.count(stale)
s = s.replace(stale, "")

# 4. The import only existed for the diagnostics model.
stale_import = (
    "import 'package:college_os/core/services/notifications/notification_models.dart';\n"
)
assert s.count(stale_import) == 1
s = s.replace(stale_import, "")

# 5. Copy stays honest about what is actually scheduled.
old_subtitle = (
    "                            current.notificationsEnabled\n"
    "                                ? 'On \u2022 Tap to send a test notification'\n"
    "                                : 'Off \u2022 Task and exam reminders are paused',"
)
new_subtitle = (
    "                            current.notificationsEnabled\n"
    "                                ? 'On \u2022 Tap to send a test notification'\n"
    "                                : 'Off \u2022 Task, exam and class reminders are paused',"
)
assert s.count(old_subtitle) == 1
s = s.replace(old_subtitle, new_subtitle)

old_note = (
    "                  Text(\n"
    "                    'Task, exam, and pending-attendance reminders stay on this device. "
    "Attendance reminders arrive 15 minutes after the last class, skip holidays, and refresh "
    "when you use CollegeOS. Only the next eligible day is scheduled. Precise alarm access "
    "improves delivery while the phone is idle.',\n"
)
new_note = (
    "                  Text(\n"
    "                    'Task, exam, class and pending-attendance reminders stay on this device. "
    "A class reminder is projected for its next occurrence and skips holidays, closures and "
    "cancelled classes. Attendance reminders arrive 15 minutes after the last class, and only "
    "the next eligible day is scheduled. Reminders refresh when you use CollegeOS, and precise "
    "alarm access improves delivery while the phone is idle.',\n"
)
assert s.count(old_note) == 1
s = s.replace(old_note, new_note)

assert 'notificationDiagnosticsProvider' not in s
assert 'NotificationDiagnostics' not in s
p.write_text(s, encoding='utf-8')
print('settings_screen.dart', before, '->', len(s))
