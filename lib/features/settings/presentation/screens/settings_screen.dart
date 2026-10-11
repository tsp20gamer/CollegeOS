import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';
import 'package:college_os/features/notifications/presentation/class_reminder_time_sheet.dart';
import 'package:college_os/features/home_widget/application/home_widget_providers.dart';
import 'package:college_os/features/home_widget/data/college_home_widget_service.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(collegeSettingsProvider);
    final semesters = ref.watch(semestersProvider);
    final appVersion = ref.watch(appVersionProvider);
    final busy =
        ref.watch(settingsDataControllerProvider).isLoading ||
        ref.watch(backupControllerProvider).isLoading;
    final value = settings.value;
    // The active semester's classes, which "Apply to all classes" would rewrite.
    final classes = ref.watch(timetableEntriesProvider).value ?? const [];
    final notificationOperation = ref.watch(
      notificationPermissionControllerProvider,
    );
    final activeSemester = semesters.value
        ?.where((semester) => semester.isActive)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              key: const Key('settings_list'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppLayout.scaffoldBottomPadding(context),
              ),
              children: [
                _CollegeProfileCard(
                  settings: value,
                  semester: activeSemester,
                  onTap: () => context.push(RoutePaths.collegeInformation),
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Academics',
                  children: [
                    _SettingsTile(
                      key: const Key('semester_management_tile'),
                      icon: Icons.calendar_month_outlined,
                      title: 'Semester & Academic Year',
                      subtitle: activeSemester == null
                          ? 'Create or select your current semester'
                          : '${activeSemester.name} • ${activeSemester.academicYear} • ${_shortDate(activeSemester.startDate)}–${_shortDate(activeSemester.endDate)}',
                      onTap: () => context.push(RoutePaths.semesters),
                    ),
                    _SettingsTile(
                      key: const Key('subjects_tile'),
                      icon: Icons.menu_book_outlined,
                      title: 'Subjects',
                      subtitle: 'Add, edit, archive, and restore subjects',
                      onTap: () => context.push(RoutePaths.subjects),
                    ),
                    _SettingsTile(
                      key: const Key('exams_marks_tile'),
                      icon: Icons.workspace_premium_outlined,
                      title: 'Exams & Marks',
                      subtitle: 'Manage exams and subject performance',
                      onTap: () => context.push(RoutePaths.examsMarks),
                    ),
                  ],
                ),
                _Section(
                  title: 'Preferences',
                  children: [
                    _SettingsTile(
                      key: const Key('default_attendance_target_tile'),
                      icon: Icons.track_changes_rounded,
                      title: 'Default Attendance Target',
                      subtitle: value == null
                          ? 'Loading…'
                          : '${(value.defaultAttendanceTarget * 100).toStringAsFixed(0)}% • Used for every subject',
                      trailing: value == null
                          ? null
                          : Text(
                              '${(value.defaultAttendanceTarget * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                      onTap: value == null
                          ? null
                          : () => _editTarget(
                              context,
                              ref,
                              value.defaultAttendanceTarget,
                            ),
                    ),
                    _SettingsTile(
                      key: const Key('theme_settings_tile'),
                      icon: Icons.contrast_rounded,
                      title: 'Theme',
                      subtitle: _themeLabel(value?.themeMode),
                      onTap: value == null
                          ? null
                          : () => _chooseTheme(context, ref, value.themeMode),
                    ),
                    _SettingsTile(
                      key: const Key('accessibility_settings_tile'),
                      icon: Icons.accessibility_new_rounded,
                      title: 'Accessibility',
                      subtitle:
                          'Text size, contrast, motion and screen readers',
                      onTap: () => _showAccessibility(context),
                    ),
                    settings.when(
                      data: (current) {
                        final operation = ref.watch(
                          notificationPermissionControllerProvider,
                        );
                        return ListTile(
                          key: const Key('notification_settings_tile'),
                          dense: true,
                          minTileHeight: 62,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          leading: const _SettingsIcon(
                            Icons.notifications_outlined,
                          ),
                          title: const Text(
                            'Notifications',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            current.notificationsEnabled
                                ? 'On • Tap to send a test notification'
                                : 'Off • Task, exam and class reminders are paused',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showNotificationTools(context),
                          trailing: Switch.adaptive(
                            key: const Key('notifications_enabled_switch'),
                            value: current.notificationsEnabled,
                            onChanged: operation.isLoading
                                ? null
                                : (enabled) =>
                                      _setNotifications(context, ref, enabled),
                          ),
                        );
                      },
                      loading: () => const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Notifications'),
                      ),
                      error: (_, _) => const ListTile(
                        leading: Icon(Icons.error_outline_rounded),
                        title: Text('Notifications unavailable'),
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Tools & Data',
                  children: [
                    _SettingsTile(
                      key: const Key('import_backup_tile'),
                      icon: Icons.settings_backup_restore_rounded,
                      title: 'Data & Backup',
                      subtitle: value?.automaticLocalBackup == false
                          ? 'Export, import and local recovery • Auto backup off'
                          : 'Export, import and local recovery • Auto backup on',
                      onTap: () => context.push(RoutePaths.dataBackup),
                    ),
                    _SettingsTile(
                      key: const Key('attendance_reports_tile'),
                      icon: Icons.analytics_outlined,
                      title: 'Attendance Analytics',
                      subtitle:
                          'Month, semester, all-time, and subject insights',
                      onTap: () => context.push(RoutePaths.reports),
                    ),
                    _SettingsTile(
                      key: const Key('offline_help_tile'),
                      icon: Icons.help_outline_rounded,
                      title: 'Help',
                      subtitle: 'Offline guides for setup and daily use',
                      onTap: () => context.push(RoutePaths.help),
                    ),
                    _AppInfoTile(
                      appVersion: appVersion,
                      onTap: () => _showAppInfo(context, appVersion.value),
                    ),
                  ],
                ),
                _Section(
                  title: 'Class notifier',
                  children: [
                    if (value == null)
                      const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Class reminders'),
                      )
                    else ...[
                      ListTile(
                        key: const Key('class_notifier_tile'),
                        dense: true,
                        minTileHeight: 62,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        leading: const _SettingsIcon(Icons.alarm_on_rounded),
                        title: const Text(
                          'Class reminders',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          value.classRemindersEnabled
                              ? 'On • ${formatClassReminderLead(value.classReminderMinutesBefore)} every class'
                              : 'Off • Your timetable classes stay silent',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Switch.adaptive(
                          key: const Key('class_notifier_switch'),
                          value: value.classRemindersEnabled,
                          onChanged: (enabled) =>
                              _setClassNotifier(context, ref, enabled),
                        ),
                      ),
                      _SettingsTile(
                        key: const Key('class_reminder_time_tile'),
                        icon: Icons.schedule_rounded,
                        title: 'Reminder time',
                        subtitle: value.classRemindersEnabled
                            ? 'Reminds you ${formatClassReminderLead(value.classReminderMinutesBefore)}'
                            : 'Used whenever class reminders are on',
                        trailing: Text(
                          formatClassReminderLead(
                            value.classReminderMinutesBefore,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () => _editClassReminderTime(
                          context,
                          ref,
                          value.classReminderMinutesBefore,
                        ),
                      ),
                      _SettingsTile(
                        key: const Key('class_notifier_apply_all_tile'),
                        icon: Icons.playlist_add_check_rounded,
                        title: 'Apply to all classes',
                        subtitle: classes.isEmpty
                            ? 'Add classes to your timetable first'
                            : 'Use this time for ${classes.length} ${classes.length == 1 ? 'class' : 'classes'} in ${activeSemester?.name ?? 'this semester'}',
                        onTap: classes.isEmpty
                            ? null
                            : () => _applyReminderToAllClasses(
                                context,
                                ref,
                                minutesBefore: value.classReminderMinutesBefore,
                              ),
                      ),
                      if (!value.notificationsEnabled)
                        ListTile(
                          key: const Key(
                            'class_notifier_notifications_off_notice',
                          ),
                          dense: true,
                          minTileHeight: 62,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          leading: const _SettingsIcon(
                            Icons.info_outline_rounded,
                          ),
                          title: const Text(
                            'Notifications are off',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Class reminders stay paused until notifications are on.',
                          ),
                          trailing: TextButton(
                            key: const Key(
                              'class_notifier_turn_on_notifications',
                            ),
                            onPressed: notificationOperation.isLoading
                                ? null
                                : () => _setNotifications(context, ref, true),
                            child: const Text('Turn on'),
                          ),
                        ),
                    ],
                  ],
                ),
                _AdvancedSettings(
                  busy: busy,
                  onAcademicCalendar: () =>
                      context.push(RoutePaths.academicCalendar),
                  onAttendancePreferences: () =>
                      _showAttendancePreferences(context),
                  onHomeWidget:
                      ref.watch(homeWidgetPinControllerProvider).isLoading
                      ? null
                      : () => _addHomeWidget(context, ref),
                  onExportCsv: busy ? null : () => _exportCsv(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),
                _DangerSection(
                  busy: busy,
                  activeSemesterName: activeSemester?.name,
                ),
              ],
            ),
            if (busy)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(CollegeThemeMode? mode) => switch (mode) {
    CollegeThemeMode.light => 'Light',
    CollegeThemeMode.dark => 'Dark',
    CollegeThemeMode.system => 'Use device setting',
    null => 'Loading…',
  };

  String _shortDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  Future<void> _showAttendancePreferences(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance preferences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'CollegeOS derives classes from your weekly timetable. Unmarked classes stay unmarked. Holidays, college-closed days, and cancelled classes never affect attendance percentage.',
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showAppInfo(BuildContext context, String? version) =>
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BrandIcon(size: 72),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'CollegeOS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Version ${version ?? 'Loading…'}',
                  key: const Key('app_info_version'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  key: const Key('made_by_tsp'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Made By Tsp',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Your private, offline college companion.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'No accounts • No cloud • No tracking',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _showNotificationTools(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final enabled = ref
            .watch(collegeSettingsProvider)
            .value
            ?.notificationsEnabled;
        final operation = ref.watch(notificationPermissionControllerProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Notification check',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    enabled == true
                        ? 'Notifications are enabled in CollegeOS.'
                        : 'Sending a test will ask for Android permission and enable reminders.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    key: const Key('send_test_notification'),
                    onPressed: operation.isLoading
                        ? null
                        : () async {
                            final sent = await ref
                                .read(
                                  notificationPermissionControllerProvider
                                      .notifier,
                                )
                                .sendTest();
                            if (!sheetContext.mounted) return;
                            _message(
                              sheetContext,
                              sent
                                  ? 'Test sent. Check your notification shade.'
                                  : 'Android has blocked CollegeOS notifications. Open Android Settings → CollegeOS → Notifications.',
                            );
                          },
                    icon: operation.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: const Text('Send test notification'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                    key: const Key('open_android_notification_settings'),
                    onPressed: () async {
                      try {
                        await ref
                            .read(notificationPlatformProvider)
                            .openNotificationSettings();
                      } catch (_) {
                        if (sheetContext.mounted) {
                          _message(
                            sheetContext,
                            'Could not open Android notification settings.',
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open Android notification settings'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Task, exam, class and pending-attendance reminders stay on this device. A class reminder is projected for its next occurrence and skips holidays, closures and cancelled classes. Attendance reminders arrive 15 minutes after the last class, and only the next eligible day is scheduled. Reminders refresh when you use CollegeOS, and precise alarm access improves delivery while the phone is idle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _showAccessibility(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Accessibility',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'CollegeOS follows your Android accessibility settings automatically.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _AccessibilityStatusRow(
                icon: Icons.format_size_rounded,
                title: 'Text scaling',
                value: '${(textScale * 100).round()}%',
                detail:
                    'Forms and upgraded screens remain scrollable as text grows.',
              ),
              _AccessibilityStatusRow(
                icon: Icons.motion_photos_off_outlined,
                title: 'Reduced motion',
                value: reduceMotion ? 'On' : 'Off',
                detail:
                    'Page, navigation bar, calendar and progress animations stop when Android requests reduced motion.',
              ),
              _AccessibilityStatusRow(
                icon: Icons.contrast_rounded,
                title: 'High contrast',
                value: media.highContrast ? 'On' : 'Off',
                detail:
                    'Attendance states include text or icons and never rely on color alone.',
              ),
              const _AccessibilityStatusRow(
                icon: Icons.record_voice_over_outlined,
                title: 'Screen readers',
                value: 'Supported',
                detail:
                    'Important percentages, controls, calendar states and actions have semantic labels.',
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseTheme(
    BuildContext context,
    WidgetRef ref,
    CollegeThemeMode selected,
  ) async {
    final choice = await showModalBottomSheet<CollegeThemeMode>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: const Text(
                  'Choose how CollegeOS looks on this device.',
                ),
              ),
              for (final option in CollegeThemeMode.values)
                ListTile(
                  title: Text(_themeLabel(option)),
                  leading: Icon(switch (option) {
                    CollegeThemeMode.system => Icons.brightness_auto_outlined,
                    CollegeThemeMode.light => Icons.light_mode_outlined,
                    CollegeThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  trailing: option == selected
                      ? const Icon(Icons.check_circle_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || choice == selected) {
      return;
    }
    await ref
        .read(settingsPreferenceControllerProvider.notifier)
        .setTheme(choice);
  }

  Future<void> _editTarget(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final controller = TextEditingController(
      text: (current * 100).toStringAsFixed(0),
    );
    final key = GlobalKey<FormState>();
    final target = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default attendance target'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This becomes the target for every subject, including the ones '
                'you already added. A single subject can still be given its own '
                'target when you edit it.',
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('attendance_target_field'),
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target',
                  suffixText: '%',
                ),
                validator: (text) {
                  final value = double.tryParse(text ?? '');
                  return value == null || value <= 0 || value > 100
                      ? 'Enter a value from 1 to 100'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(context, double.parse(controller.text) / 100);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (target == null) {
      return;
    }
    await ref
        .read(settingsPreferenceControllerProvider.notifier)
        .setDefaultAttendanceTarget(target);
  }

  Future<void> _setNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(
      notificationPermissionControllerProvider.notifier,
    );
    final success = enabled
        ? await controller.enable()
        : await controller.disable();
    if (!context.mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Android notification permission was not granted.'
              : 'Could not update notification settings.',
        ),
      ),
    );
  }

  /// Records the class-notifier preference.
  ///
  /// Turning it on only asks Android for delivery permission when the global
  /// notifications master is already on; otherwise the section shows the notice
  /// explaining why nothing would arrive yet.
  Future<void> _setClassNotifier(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final success = await ref
        .read(settingsPreferenceControllerProvider.notifier)
        .setClassRemindersEnabled(enabled);
    if (!context.mounted) return;
    if (!success) {
      _message(context, 'Could not update class reminders.');
      return;
    }
    final masterEnabled = ref
        .read(collegeSettingsProvider)
        .value
        ?.notificationsEnabled;
    if (!enabled || masterEnabled != true) return;
    await ref.read(notificationPermissionControllerProvider.notifier).enable();
  }

  Future<void> _editClassReminderTime(
    BuildContext context,
    WidgetRef ref,
    int minutesBefore,
  ) async {
    final chosen = await showClassReminderTimeSheet(
      context,
      initialMinutesBefore: minutesBefore,
      keyPrefix: 'class_notifier',
      title: 'Reminder time',
      description:
          'Choose how long before each class CollegeOS should remind you.',
      confirmLabel: 'Save time',
    );
    if (chosen == null || !context.mounted) return;
    final success = await ref
        .read(settingsPreferenceControllerProvider.notifier)
        .setClassReminderMinutesBefore(chosen);
    if (!context.mounted) return;
    _message(
      context,
      success
          ? 'Reminder time saved. Apply it to your classes to use it now.'
          : 'Could not save the reminder time.',
    );
  }

  /// Replaces every class's reminder with the class-notifier time.
  ///
  /// The confirmation names the consequence, because this overwrites any
  /// reminder time the student set on a single class.
  Future<void> _applyReminderToAllClasses(
    BuildContext context,
    WidgetRef ref, {
    required int minutesBefore,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
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
                'Apply to all classes',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Every class in the active semester will remind you '
                '${formatClassReminderLead(minutesBefore)}. Reminder times you '
                'set on individual classes will be replaced.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: const Key('confirm_apply_class_reminders'),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Apply to all classes'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final updated = await ref
        .read(timetableCommandProvider.notifier)
        .applyReminderToAll(minutesBefore);
    if (!context.mounted) return;
    _message(context, switch (updated) {
      null => 'Could not update your classes.',
      0 => 'No classes to update.',
      1 => 'Reminder time applied to 1 class.',
      final count => 'Reminder time applied to $count classes.',
    });
  }

  Future<void> _addHomeWidget(BuildContext context, WidgetRef ref) async {
    final projection = ref.read(collegeHomeWidgetProjectionProvider).value;
    if (projection != null) {
      await ref.read(collegeHomeWidgetServiceProvider).sync(projection);
    }
    final result = await ref
        .read(homeWidgetPinControllerProvider.notifier)
        .requestPin();
    if (!context.mounted) return;
    _message(context, switch (result) {
      HomeWidgetPinResult.requested =>
        'Confirm the CollegeOS widget on your home screen.',
      HomeWidgetPinResult.unsupported =>
        'Add CollegeOS from your launcher\'s Widgets menu.',
      HomeWidgetPinResult.unavailable =>
        'The widget could not be opened on this device.',
    });
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    try {
      final saved = await ref
          .read(settingsDataControllerProvider.notifier)
          .exportAttendanceCsv();
      if (saved && context.mounted) {
        _message(context, 'Attendance CSV saved.');
      }
    } catch (_) {
      if (context.mounted) {
        _message(context, 'Could not export attendance CSV.');
      }
    }
  }
}

class _AccessibilityStatusRow extends StatelessWidget {
  const _AccessibilityStatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$title, $value. $detail',
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsIcon(icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CollegeProfileCard extends StatelessWidget {
  const _CollegeProfileCard({
    required this.settings,
    required this.semester,
    required this.onTap,
  });

  final CollegeSettings? settings;
  final Semester? semester;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final collegeName = settings?.collegeName.trim();
    final detail = [
      settings?.studentName.trim(),
      settings?.course.trim(),
      settings?.branch.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return Card(
      key: const Key('settings_college_profile'),
      child: InkWell(
        key: const Key('college_information_tile'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const _BrandIcon(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'College Information',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      collegeName?.isNotEmpty == true
                          ? collegeName!
                          : 'CollegeOS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (semester != null)
                      Text(
                        'Current: ${semester!.name} • ${semester!.academicYear}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    minTileHeight: 62,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    leading: _SettingsIcon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: subtitle.isEmpty
        ? null
        : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    onTap: onTap,
  );
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 20, color: colors.primary),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      // Deep brand tint instead of a hardcoded navy, so the logo plate
      // follows the theme.
      color: Color.alphaBlend(
        Colors.black.withValues(alpha: .55),
        Theme.of(context).colorScheme.primary,
      ),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        'assets/branding/collegeos_icon_foreground.png',
        semanticLabel: 'CollegeOS logo',
      ),
    ),
  );
}

class _AdvancedSettings extends StatelessWidget {
  const _AdvancedSettings({
    required this.busy,
    required this.onAcademicCalendar,
    required this.onAttendancePreferences,
    required this.onHomeWidget,
    required this.onExportCsv,
  });

  final bool busy;
  final VoidCallback onAcademicCalendar;
  final VoidCallback onAttendancePreferences;
  final VoidCallback? onHomeWidget;
  final VoidCallback? onExportCsv;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: const Key('advanced_settings_section'),
      leading: const _SettingsIcon(Icons.tune_rounded),
      title: const Text(
        'More options',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Calendar, widget, exports and app information'),
      children: [
        const Divider(height: 1),
        _SettingsTile(
          key: const Key('academic_calendar_tile'),
          icon: Icons.event_note_outlined,
          title: 'Academic Calendar',
          subtitle: 'Holidays, closures and academic events',
          onTap: onAcademicCalendar,
        ),
        _SettingsTile(
          icon: Icons.rule_rounded,
          title: 'How Attendance Works',
          subtitle: 'Review class-based attendance rules',
          onTap: onAttendancePreferences,
        ),
        _SettingsTile(
          key: const Key('home_screen_widget_tile'),
          icon: Icons.widgets_outlined,
          title: 'Home-screen Widget',
          subtitle: 'Next class and today\'s attendance',
          onTap: onHomeWidget,
        ),
        _SettingsTile(
          key: const Key('export_attendance_csv_tile'),
          icon: Icons.table_view_outlined,
          title: 'Export Attendance CSV',
          subtitle: 'Spreadsheet-friendly attendance history',
          onTap: busy ? null : onExportCsv,
        ),
      ],
    ),
  );
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile({required this.appVersion, required this.onTap});

  final AsyncValue<String> appVersion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SettingsTile(
    key: const Key('app_info_tile'),
    icon: Icons.info_outline_rounded,
    title: 'App Info',
    subtitle: appVersion.when(
      data: (version) => 'Version $version • Made By Tsp',
      loading: () => 'Version loading • Made By Tsp',
      error: (_, _) => 'Made By Tsp',
    ),
    onTap: onTap,
  );
}

class _DangerSection extends ConsumerWidget {
  const _DangerSection({required this.busy, required this.activeSemesterName});
  final bool busy;
  final String? activeSemesterName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer.withValues(alpha: 0.22),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('danger_zone_section'),
        leading: Icon(Icons.warning_amber_rounded, color: colors.error),
        iconColor: colors.error,
        collapsedIconColor: colors.error,
        title: Text(
          'Danger zone',
          style: TextStyle(color: colors.error, fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Reset or permanently erase local data'),
        children: [
          const Divider(height: 1),
          _SettingsTile(
            key: const Key('reset_current_semester_tile'),
            icon: Icons.restart_alt_rounded,
            title: 'Reset Current Semester',
            subtitle: activeSemesterName == null
                ? 'No active semester'
                : 'Clear $activeSemesterName while preserving older history',
            onTap: busy || activeSemesterName == null
                ? null
                : () => _resetSemester(context, ref, activeSemesterName!),
          ),
          const Divider(height: 1),
          _SettingsTile(
            key: const Key('delete_all_data_tile'),
            icon: Icons.delete_forever_outlined,
            title: 'Delete All CollegeOS Data',
            subtitle: 'Erase app data and return to first-time setup',
            onTap: busy ? null : () => _deleteAll(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSemester(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text('Reset $name?'),
        content: const Text(
          'This permanently removes subjects, daily attendance within this semester\'s dates, timetable entries, tasks, exams, and marks from the current semester.\n\n'
          'The semester itself, college information, preferences, exported backups, and every older semester remain untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_reset_semester'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset semester'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(settingsDataControllerProvider.notifier)
          .resetCurrentSemester();
      if (context.mounted) {
        _message(context, '$name was reset. Older history is safe.');
      }
    } catch (_) {
      if (context.mounted) {
        _message(
          context,
          'Could not reset the semester. Nothing was partially removed.',
        );
      }
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final text = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: Icon(
            Icons.delete_forever_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const Text('Delete all CollegeOS data?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This erases college information, all semesters, subjects, attendance, timetable, tasks, exams, marks, preferences, and private recovery backups. The app returns to first-time setup.\n\nBackups exported to Downloads or another app are not deleted.',
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Type DELETE to confirm.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key('delete_all_confirmation_field'),
                controller: text,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm_delete_all_data'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: text.text == 'DELETE'
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Delete everything'),
            ),
          ],
        ),
      ),
    );
    text.dispose();
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(settingsDataControllerProvider.notifier).deleteAllData();
      if (context.mounted) {
        context.go(RoutePaths.welcome);
      }
    } catch (_) {
      if (context.mounted) {
        _message(
          context,
          'Could not delete data. Your database remains usable.',
        );
      }
    }
  }
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
