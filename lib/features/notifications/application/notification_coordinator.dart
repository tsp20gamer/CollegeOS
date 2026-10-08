// Named public constructor parameters intentionally initialize private fields.
// ignore_for_file: prefer_initializing_formals

import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';

final class NotificationCoordinator {
  NotificationCoordinator({
    required NotificationPlatform platform,
    required TaskRepository tasks,
    required ExamRepository exams,
    required SettingsRepository settings,
    DateTime Function()? now,
  }) : _platform = platform,
       _tasks = tasks,
       _exams = exams,
       _settings = settings,
       _now = now ?? DateTime.now;

  final NotificationPlatform _platform;
  final TaskRepository _tasks;
  final ExamRepository _exams;
  final SettingsRepository _settings;
  final DateTime Function() _now;
  bool _initialized = false;
  CollegeOsNotification? _attendanceReminder;
  Future<void> _attendanceQueue = Future.value();
  Map<int, CollegeOsNotification> _classReminders = const {};
  Future<void> _classQueue = Future.value();

  Future<void> syncAttendanceReminder(CollegeOsNotification? reminder) {
    final operation = _attendanceQueue.then((_) async {
      final enabled = (await _settings.get()).notificationsEnabled;
      final desired = enabled ? reminder : null;
      if (desired != null && desired == _attendanceReminder) return;
      if (desired == null) {
        await _platform.cancel(NotificationEntityType.attendance, 1);
      } else {
        await _platform.schedule(desired);
      }
      _attendanceReminder = desired;
    });
    _attendanceQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> initialize(void Function(String payload) onTap) async {
    if (_initialized) return;
    final initialPayload = await _platform.initialize(onTap);
    _initialized = true;
    await reconcile();
    if (initialPayload != null) onTap(initialPayload);
  }

  Future<bool> enableWithPermission() async {
    var allowed = await _platform.notificationsEnabled();
    if (!allowed) {
      await _platform.requestPermission();
      // App permission and the active reminder channel must both be enabled.
      allowed = await _platform.notificationsEnabled();
    }
    await _saveEnabled(allowed);
    if (allowed) {
      await _requestExactAlarmAccess();
      await reconcile();
    }
    return allowed;
  }

  Future<bool> ensureEnabledForReminder(DateTime? reminderAt) async {
    if (reminderAt == null) return true;
    return _ensureReminderDelivery();
  }

  /// Class reminders store a lead time rather than an instant, so this asks for
  /// permission only when a class actually carries a reminder.
  Future<bool> ensureEnabledForClassReminder(int? minutesBefore) async {
    if (minutesBefore == null) return true;
    return _ensureReminderDelivery();
  }

  Future<bool> _ensureReminderDelivery() async {
    if ((await _settings.get()).notificationsEnabled &&
        await _platform.notificationsEnabled()) {
      await _requestExactAlarmAccess();
      return true;
    }
    return enableWithPermission();
  }

  Future<bool> sendTestNotification() async {
    var allowed = await _platform.notificationsEnabled();
    if (!allowed) {
      await _platform.requestPermission();
      allowed = await _platform.notificationsEnabled();
    }
    if (!allowed) return false;
    try {
      await _platform.showTestNotification();
      await _saveEnabled(true);
      await reconcile();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    await _saveEnabled(false);
    await _attendanceQueue;
    await _classQueue;
    await _cancelAllCollegeOsPending();
  }

  /// Projects each class's reminder into one Android alarm.
  ///
  /// [reminders] is the complete desired set for the class namespace, so this
  /// cancels class alarms that are no longer wanted (a removed class, a
  /// disabled reminder, a past occurrence) and schedules the rest. Like the
  /// attendance reminder, calls are serialized and the projection is rebuilt
  /// whenever the timetable, calendar or clock changes.
  Future<void> syncClassReminders(List<CollegeOsNotification> reminders) {
    final operation = _classQueue.then((_) async {
      final enabled = (await _settings.get()).notificationsEnabled;
      final desired = <int, CollegeOsNotification>{
        for (final reminder in enabled ? reminders : const <CollegeOsNotification>[])
          notificationId(reminder.type, reminder.entityId): reminder,
      };
      final stillPending = <int>{};
      for (final pending in await _platform.pending()) {
        final parsed = parseNotificationPayload(pending.payload);
        if (parsed == null ||
            parsed.type != NotificationEntityType.classReminder) {
          continue;
        }
        final id = notificationId(parsed.type, parsed.entityId);
        if (desired.containsKey(id)) {
          stillPending.add(id);
        } else {
          await _platform.cancel(parsed.type, parsed.entityId);
        }
      }
      for (final entry in desired.entries) {
        final unchanged = _classReminders[entry.key] == entry.value;
        if (unchanged && stillPending.contains(entry.key)) continue;
        await _platform.schedule(entry.value);
      }
      _classReminders = desired;
    });
    _classQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> syncTask({
    required int id,
    required String title,
    required CollegeTaskType type,
    required DateTime? reminderAt,
    required bool completed,
  }) async {
    final notification = reminderAt == null || completed
        ? null
        : (
            type: NotificationEntityType.task,
            entityId: id,
            title: type == CollegeTaskType.assignment
                ? 'Assignment reminder'
                : 'Task reminder',
            body: title,
            scheduledAt: reminderAt,
          );
    await _sync(notification, NotificationEntityType.task, id);
  }

  Future<void> syncExam({
    required int id,
    required String name,
    required DateTime? reminderAt,
  }) => _sync(
    reminderAt == null
        ? null
        : (
            type: NotificationEntityType.exam,
            entityId: id,
            title: 'Exam reminder',
            body: name,
            scheduledAt: reminderAt,
          ),
    NotificationEntityType.exam,
    id,
  );

  Future<void> cancel(NotificationEntityType type, int id) =>
      _platform.cancel(type, id);

  Future<void> reconcile() async {
    final settings = await _settings.get();
    final expected = <int, CollegeOsNotification>{};
    if (settings.notificationsEnabled) {
      for (final task in await _tasks.getAllWithReminders()) {
        if (!task.isCompleted && _isFuture(task.reminderAt)) {
          final type = task.type == CollegeTaskType.assignment
              ? 'Assignment reminder'
              : 'Task reminder';
          expected[notificationId(NotificationEntityType.task, task.id)] = (
            type: NotificationEntityType.task,
            entityId: task.id,
            title: type,
            body: task.title,
            scheduledAt: task.reminderAt!,
          );
        }
      }
      for (final exam in await _exams.getAllWithReminders()) {
        if (_isFuture(exam.reminderAt)) {
          expected[notificationId(NotificationEntityType.exam, exam.id)] = (
            type: NotificationEntityType.exam,
            entityId: exam.id,
            title: 'Exam reminder',
            body: exam.name,
            scheduledAt: exam.reminderAt!,
          );
        }
      }
    }
    for (final pending in await _platform.pending()) {
      final parsed = parseNotificationPayload(pending.payload);
      if (parsed == null || expected.containsKey(pending.id)) continue;
      // Class reminders and the attendance reminder keep their own projection
      // channels, so startup must not sweep them before those syncs run.
      if (parsed.type == NotificationEntityType.classReminder) continue;
      if (parsed.type == NotificationEntityType.attendance &&
          settings.notificationsEnabled) {
        continue;
      }
      await _platform.cancel(parsed.type, parsed.entityId);
    }
    for (final notification in expected.values) {
      await _platform.schedule(notification);
    }
  }

  Future<void> _sync(
    CollegeOsNotification? notification,
    NotificationEntityType type,
    int id,
  ) async {
    final settings = await _settings.get();
    final canSchedule =
        notification != null &&
        _isFuture(notification.scheduledAt) &&
        settings.notificationsEnabled;
    if (canSchedule) {
      await _platform.schedule(notification);
    } else {
      await _platform.cancel(type, id);
    }
  }

  bool _isFuture(DateTime? instant) =>
      instant != null && instant.isAfter(_now().toUtc());

  Future<void> _cancelAllCollegeOsPending() async {
    _attendanceReminder = null;
    _classReminders = const {};
    for (final pending in await _platform.pending()) {
      final parsed = parseNotificationPayload(pending.payload);
      if (parsed != null) await _platform.cancel(parsed.type, parsed.entityId);
    }
  }

  Future<void> _saveEnabled(bool enabled) async {
    final current = await _settings.get();
    await _settings.save((
      studentName: current.studentName,
      collegeName: current.collegeName,
      course: current.course,
      branch: current.branch,
      academicYearStartDate: current.academicYearStartDate,
      academicYearEndDate: current.academicYearEndDate,
      defaultAttendanceTarget: current.defaultAttendanceTarget,
      themeMode: current.themeMode,
      onboardingCompleted: current.onboardingCompleted,
      notificationsEnabled: enabled,
      automaticLocalBackup: current.automaticLocalBackup,
    ));
  }

  Future<void> _requestExactAlarmAccess() async {
    try {
      await _platform.requestExactAlarmPermission();
    } catch (_) {
      // The reminder remains valid and is scheduled with the platform's
      // battery-friendly inexact fallback when special access is unavailable.
    }
  }
}
