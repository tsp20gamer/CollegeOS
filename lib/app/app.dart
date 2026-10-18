import 'dart:async';
import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/attendance/domain/attendance_engine_repository.dart';
import 'package:college_os/core/theme/spacing.dart';

import 'package:college_os/core/routing/app_router.dart';
import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/core/theme/system_ui_style.dart';
import 'package:college_os/app/startup_splash.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/backup/application/automatic_backup_coordinator.dart';
import 'package:college_os/features/backup/application/incoming_backup_service.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/features/notifications/application/class_reminder_providers.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/features/home_widget/application/home_widget_providers.dart';
import 'package:college_os/features/home_widget/domain/home_widget_projection.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:college_os/features/onboarding/application/onboarding_providers.dart';
import 'package:college_os/core/database/database_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class CollegeOsApp extends ConsumerStatefulWidget {
  const CollegeOsApp({this.enableStartupAnimation = true, super.key});

  final bool enableStartupAnimation;

  @override
  ConsumerState<CollegeOsApp> createState() => _CollegeOsAppState();
}

class _CollegeOsAppState extends ConsumerState<CollegeOsApp>
    with WidgetsBindingObserver {
  late final AutomaticBackupCoordinator _automaticBackups;
  StreamSubscription<IncomingBackupEvent>? _incomingBackupSubscription;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _automaticBackups = ref.read(automaticBackupCoordinatorProvider)..start();
    unawaited(ref.read(backupServiceProvider).discardTemporaryData());
    final incomingBackups = ref.read(incomingBackupServiceProvider);
    _incomingBackupSubscription = incomingBackups.events.listen(
      _handleIncomingBackup,
    );
    unawaited(incomingBackups.initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeNotifications());
    });
  }

  Future<void> _handleIncomingBackup(IncomingBackupEvent event) async {
    if (event case IncomingBackupFile(:final path)) {
      try {
        await ref.read(onboardingCompletedProvider.future);
      } catch (_) {
        // Restore remains available even if onboarding state cannot be read.
      }
      if (!mounted) return;
      ref.read(appRouterProvider).push(RoutePaths.restoreBackup, extra: path);
      return;
    }

    if (event case IncomingBackupFailure(:final message)) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final context = ref
            .read(appRouterProvider)
            .routerDelegate
            .navigatorKey
            .currentContext;
        if (context == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      });
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await ref
          .read(notificationCoordinatorProvider)
          .initialize(_openNotification);
      if (mounted) {
        await _syncAttendanceReminder(
          ref.read(pendingAttendanceReminderProvider),
        );
        final classReminders = ref.read(pendingClassRemindersProvider);
        if (classReminders != null) {
          await _syncClassReminders(classReminders);
        }
      }
    } catch (_) {
      // Platform notification availability never blocks CollegeOS startup.
    }
  }

  void _openNotification(String payload) {
    final target = parseNotificationPayload(payload);
    if (target == null || !mounted) return;
    final router = ref.read(appRouterProvider);
    switch (target.type) {
      case NotificationEntityType.task:
        router.go('/tasks?taskId=${target.entityId}');
      case NotificationEntityType.exam:
        // Settings is a pushed destination rather than a tab, so this pushes
        // instead of replacing the stack and leaves the shell underneath for
        // the user to come back to.
        router.push('/settings/exams-marks?examId=${target.entityId}');
      case NotificationEntityType.attendance:
        router.go('/attendance/pending');
      case NotificationEntityType.classReminder:
        router.go('/timetable');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_automaticBackups.checkpoint());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_incomingBackupSubscription?.cancel());
    unawaited(_automaticBackups.dispose());
    super.dispose();
  }

  Future<void> _syncHomeWidget(HomeWidgetProjection projection) async {
    try {
      await ref.read(collegeHomeWidgetServiceProvider).sync(projection);
    } catch (_) {
      // The launcher/widget host is optional and must never destabilize the app.
    }
  }

  Future<void> _syncAttendanceReminder(CollegeOsNotification? reminder) async {
    try {
      await ref
          .read(notificationCoordinatorProvider)
          .syncAttendanceReminder(reminder);
    } catch (_) {
      // An OS error must not interrupt attendance entry; the next launch
      // reconciles the projection again.
    }
  }

  Future<void> _syncClassReminders(
    List<CollegeOsNotification> reminders,
  ) async {
    try {
      await ref
          .read(notificationCoordinatorProvider)
          .syncClassReminders(reminders);
    } catch (_) {
      // Reminder intent stays in SQLite, so a failed projection is retried on
      // the next change or launch.
    }
  }

  Future<void> _undoAttendance(AttendanceUndo undo) async {
    try {
      final restored = await undo();
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            restored
                ? 'Attendance restored.'
                : 'Attendance changed again. Undo was not applied.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not undo attendance. Please try editing the class.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingAttendanceReminderProvider, (_, next) {
      unawaited(_syncAttendanceReminder(next));
    });
    ref.listen(pendingClassRemindersProvider, (_, next) {
      if (next == null) return;
      unawaited(_syncClassReminders(next));
    });
    ref.listen(attendanceUndoProvider, (_, undo) {
      if (undo == null) return;
      _messengerKey.currentState?.hideCurrentSnackBar();
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          // Scaffold already lifts a floating SnackBar above the bottom
          // navigation bar, so this only supplies the standard gap.
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: const Duration(seconds: 6),
          content: const Text('Attendance updated'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => unawaited(_undoAttendance(undo)),
          ),
        ),
      );
    });
    ref.listen(collegeHomeWidgetProjectionProvider, (_, next) {
      next.whenData((projection) {
        unawaited(_syncHomeWidget(projection));
      });
    });
    final storedTheme = ref.watch(collegeSettingsProvider).value?.themeMode;
    return MaterialApp.router(
      scaffoldMessengerKey: _messengerKey,
      title: 'CollegeOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (storedTheme) {
        CollegeThemeMode.light => ThemeMode.light,
        CollegeThemeMode.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        final themedContent = AnnotatedRegion<SystemUiOverlayStyle>(
          key: const Key('app_system_ui_style'),
          value: AppSystemUiStyle.forBrightness(Theme.of(context).brightness),
          child: child ?? const SizedBox.shrink(),
        );
        return CollegeStartupSplash(
          enabled: widget.enableStartupAnimation,
          child: themedContent,
        );
      },
    );
  }
}
