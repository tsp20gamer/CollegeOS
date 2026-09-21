import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final class AndroidNotificationPlatform
    implements NotificationPlatform, NotificationDiagnosticsPlatform {
  AndroidNotificationPlatform({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;
  void Function(String payload) _onTap = _ignoreTap;

  static const _channelId = 'collegeos_reminders_v4';
  static const _legacyChannelIds = <String>[
    'collegeos_reminders',
    'collegeos_reminders_v2',
    'collegeos_reminders_v3',
  ];
  static const _testNotificationId = 2147483000;
  static const _settingsChannel = MethodChannel(
    'com.collegeos.app/notifications',
  );

  static const _channel = AndroidNotificationChannel(
    _channelId,
    'CollegeOS reminders',
    description: 'Task, assignment, exam, and attendance reminders',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'CollegeOS reminders',
      channelDescription: 'Task, assignment, exam, and attendance reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
  );

  @override
  Future<String?> initialize(void Function(String payload) onTap) async {
    _onTap = onTap;
    await _ensureInitialized();
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true
        ? launch?.notificationResponse?.payload
        : null;
  }

  @override
  Future<bool> notificationsEnabled() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final native = await _nativeDiagnostics();
    final permissionEnabled =
        native.postPermissionGranted ??
        native.appNotificationsEnabled ??
        await android.areNotificationsEnabled() ??
        true;
    if (!permissionEnabled) return false;

    final channels = await android.getNotificationChannels();
    final reminderChannel = channels
        ?.where((channel) => channel.id == _channelId)
        .firstOrNull;
    return native.channelEnabled ??
        (reminderChannel == null ||
            reminderChannel.importance != Importance.none);
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    return await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final alreadyAllowed = await android.canScheduleExactNotifications();
    if (alreadyAllowed != false) return alreadyAllowed ?? true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<void> openNotificationSettings() async {
    await _ensureInitialized();
    await _settingsChannel.invokeMethod(
      'openNotificationSettings',
      <String, String>{'channelId': _channelId},
    );
  }

  @override
  Future<void> openBatterySettings() async {
    await _ensureInitialized();
    await _settingsChannel.invokeMethod('openBatterySettings');
  }

  @override
  Future<void> showTestNotification() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _testNotificationId);
    await _plugin.show(
      id: _testNotificationId,
      title: 'CollegeOS notifications work',
      body: 'Task and exam reminders will appear on this device.',
      notificationDetails: _details,
    );
  }

  @override
  Future<void> schedule(CollegeOsNotification notification) async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarmAllowed =
        await android?.canScheduleExactNotifications() == true;
    await _plugin.zonedSchedule(
      id: notificationId(notification.type, notification.entityId),
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(notification.scheduledAt, tz.local),
      notificationDetails: _details,
      androidScheduleMode: exactAlarmAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: notificationPayload(notification.type, notification.entityId),
    );
  }

  @override
  Future<void> cancel(NotificationEntityType type, int entityId) async {
    await _plugin.cancel(id: notificationId(type, entityId));
  }

  @override
  Future<List<PendingCollegeOsNotification>> pending() async {
    return (await _plugin.pendingNotificationRequests())
        .map((item) => (id: item.id, payload: item.payload))
        .toList(growable: false);
  }

  @override
  Future<NotificationDiagnostics> diagnostics() async {
    await _ensureInitialized();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final native = await _nativeDiagnostics();
    final permissionEnabled =
        native.postPermissionGranted ??
        native.appNotificationsEnabled ??
        await android?.areNotificationsEnabled() ??
        true;
    final channels = await android?.getNotificationChannels();
    final reminderChannel = channels
        ?.where((channel) => channel.id == _channelId)
        .firstOrNull;
    return NotificationDiagnostics(
      permissionEnabled: permissionEnabled,
      channelExists: reminderChannel != null,
      channelEnabled:
          native.channelEnabled ??
          (reminderChannel != null &&
              reminderChannel.importance != Importance.none),
      channelImportance: _importanceLabel(reminderChannel?.importance),
      pendingReminderCount: (await pending()).length,
      timezone: tz.local.name,
      androidSdk: native.sdkInt,
      batteryOptimizationExempt: native.batteryOptimizationExempt,
      exactAlarmAllowed:
          native.exactAlarmAllowed ??
          (await android?.canScheduleExactNotifications()),
    );
  }

  Future<_NativeNotificationDiagnostics> _nativeDiagnostics() async {
    try {
      final result = await _settingsChannel.invokeMapMethod<String, Object?>(
        'getNotificationDiagnostics',
        <String, String>{'channelId': _channelId},
      );
      return _NativeNotificationDiagnostics(
        sdkInt: result?['sdkInt'] as int?,
        batteryOptimizationExempt:
            result?['batteryOptimizationExempt'] as bool?,
        postPermissionGranted: result?['postPermissionGranted'] as bool?,
        appNotificationsEnabled: result?['appNotificationsEnabled'] as bool?,
        channelEnabled: result?['channelEnabled'] as bool?,
        exactAlarmAllowed: result?['exactAlarmAllowed'] as bool?,
      );
    } on PlatformException {
      return const _NativeNotificationDiagnostics();
    } on MissingPluginException {
      return const _NativeNotificationDiagnostics();
    }
  }

  Future<void> _ensureInitialized() async {
    final existing = _initialization;
    if (existing != null) {
      await existing;
      return;
    }
    final attempt = _initializePlugin();
    _initialization = attempt;
    try {
      await attempt;
    } catch (_) {
      if (identical(_initialization, attempt)) _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializePlugin() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Reminder instants are stored in UTC, so this still preserves the exact
      // delivery instant if the device timezone plugin is temporarily absent.
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _onTap(payload);
      },
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    for (final channelId in _legacyChannelIds) {
      await android?.deleteNotificationChannel(channelId: channelId);
    }
  }
}

final class _NativeNotificationDiagnostics {
  const _NativeNotificationDiagnostics({
    this.sdkInt,
    this.batteryOptimizationExempt,
    this.postPermissionGranted,
    this.appNotificationsEnabled,
    this.channelEnabled,
    this.exactAlarmAllowed,
  });

  final int? sdkInt;
  final bool? batteryOptimizationExempt;
  final bool? postPermissionGranted;
  final bool? appNotificationsEnabled;
  final bool? channelEnabled;
  final bool? exactAlarmAllowed;
}

String _importanceLabel(Importance? importance) => switch (importance) {
  Importance.max => 'Maximum',
  Importance.high => 'High',
  Importance.defaultImportance => 'Default',
  Importance.low => 'Low',
  Importance.min => 'Minimum',
  Importance.none => 'Blocked',
  null => 'Missing',
  _ => importance.name,
};

void _ignoreTap(String _) {}
