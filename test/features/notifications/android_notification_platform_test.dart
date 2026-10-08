import 'dart:convert';

import 'package:college_os/core/services/notifications/android_notification_platform.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const settingsChannel = MethodChannel('com.collegeos.app/notifications');
  final calls = <MethodCall>[];
  var exposeReminderChannel = false;
  var pluginNotificationsEnabled = true;
  var nativePermissionGranted = true;
  var nativeChannelEnabled = true;
  var exactAlarmAllowed = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    exposeReminderChannel = false;
    pluginNotificationsEnabled = true;
    nativePermissionGranted = true;
    nativeChannelEnabled = true;
    exactAlarmAllowed = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'areNotificationsEnabled' => pluginNotificationsEnabled,
            'canScheduleExactNotifications' => exactAlarmAllowed,
            'requestExactAlarmsPermission' => exactAlarmAllowed = true,
            'getNotificationChannels' =>
              exposeReminderChannel
                  ? <dynamic>[
                      <String, dynamic>{
                        'id': 'collegeos_reminders_v4',
                        'name': 'CollegeOS reminders',
                        'description': 'Task, assignment, and exam reminders',
                        'importance': 5,
                        'bypassDnd': false,
                        'playSound': true,
                        'enableLights': false,
                        'enableVibration': true,
                        'showBadge': true,
                        'vibrationPattern': Int64List(0),
                        'ledColor': 0,
                        'audioAttributesUsage': 5,
                      },
                    ]
                  : <dynamic>[],
            _ => null,
          };
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, (call) async {
          if (call.method == 'getNotificationStatus') {
            return <String, dynamic>{
              'postPermissionGranted': nativePermissionGranted,
              'appNotificationsEnabled': pluginNotificationsEnabled,
              'channelEnabled': nativeChannelEnabled,
            };
          }
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, null);
  });

  test('migrates to an enabled v4 channel before posting a test', () async {
    final platform = AndroidNotificationPlatform();

    expect(await platform.notificationsEnabled(), isTrue);
    await platform.showTestNotification();

    final created = calls.singleWhere(
      (call) => call.method == 'createNotificationChannel',
    );
    final channelArguments = created.arguments! as Map<dynamic, dynamic>;
    expect(channelArguments['id'], 'collegeos_reminders_v4');
    expect(channelArguments['name'], 'CollegeOS reminders');
    expect(channelArguments['importance'], 5);
    expect(channelArguments['playSound'], isTrue);
    expect(channelArguments['enableVibration'], isTrue);

    final deletedChannels = calls
        .where((call) => call.method == 'deleteNotificationChannel')
        .map((call) => call.arguments)
        .toSet();
    expect(deletedChannels, {
      'collegeos_reminders',
      'collegeos_reminders_v2',
      'collegeos_reminders_v3',
    });

    final cancelIndex = calls.indexWhere((call) => call.method == 'cancel');
    final showIndex = calls.indexWhere((call) => call.method == 'show');
    expect(cancelIndex, greaterThanOrEqualTo(0));
    expect(showIndex, greaterThan(cancelIndex));
    expect(
      jsonEncode(calls[showIndex].arguments),
      contains('collegeos_reminders_v4'),
    );
  });

  test('native status bridge decides permission and channel state', () async {
    exposeReminderChannel = true;
    final platform = AndroidNotificationPlatform();

    expect(await platform.notificationsEnabled(), isTrue);

    // A blocked reminder channel in Android must win over the app-level
    // permission the plugin reports.
    nativeChannelEnabled = false;
    expect(await platform.notificationsEnabled(), isFalse);

    nativeChannelEnabled = true;
    expect(await platform.notificationsEnabled(), isTrue);
  });

  test('uses native runtime permission when the OEM probe is stale', () async {
    pluginNotificationsEnabled = false;
    nativePermissionGranted = true;

    expect(await AndroidNotificationPlatform().notificationsEnabled(), isTrue);
  });

  test('uses exact idle alarms when allowed and an inexact fallback', () async {
    final platform = AndroidNotificationPlatform();
    final reminder = (
      type: NotificationEntityType.task,
      entityId: 7,
      title: 'Task reminder',
      body: 'Submit lab record',
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
    );

    await platform.schedule(reminder);
    var scheduled = calls.lastWhere((call) => call.method == 'zonedSchedule');
    var arguments = scheduled.arguments! as Map<dynamic, dynamic>;
    var specifics = arguments['platformSpecifics'] as Map<dynamic, dynamic>;
    expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');

    exactAlarmAllowed = true;
    await platform.schedule(reminder);
    scheduled = calls.lastWhere((call) => call.method == 'zonedSchedule');
    arguments = scheduled.arguments! as Map<dynamic, dynamic>;
    specifics = arguments['platformSpecifics'] as Map<dynamic, dynamic>;
    expect(specifics['scheduleMode'], 'exactAllowWhileIdle');
  });
}
