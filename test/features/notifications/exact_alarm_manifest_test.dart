import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// Offline reminders depend on Android granting exact alarms at install.
///
/// SCHEDULE_EXACT_ALARM alone is denied by default on Android 14+, which left
/// every reminder on an inexact alarm that Doze holds until the phone wakes
/// (with internet on, other apps' pushes do that; offline nothing does). This
/// pins the manifest so the auto-granted permission cannot be dropped again.
void main() {
  final manifest = XmlDocument.parse(
    File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
  );
  const androidNs = 'http://schemas.android.com/apk/res/android';

  Iterable<XmlElement> permissions(String name) => manifest.rootElement
      .findElements('uses-permission')
      .where((e) => e.getAttribute('name', namespaceUri: androidNs) == name);

  test('declares USE_EXACT_ALARM with no SDK cap', () {
    final useExact = permissions('android.permission.USE_EXACT_ALARM');
    expect(useExact, hasLength(1));
    expect(
      useExact.single.getAttribute('maxSdkVersion', namespaceUri: androidNs),
      isNull,
    );
  });

  test('keeps SCHEDULE_EXACT_ALARM for Android 12 and 12L only', () {
    final schedule = permissions('android.permission.SCHEDULE_EXACT_ALARM');
    expect(schedule, hasLength(1));
    expect(
      schedule.single.getAttribute('maxSdkVersion', namespaceUri: androidNs),
      '32',
    );
  });

  test('reschedules reminders after a reboot or an app update', () {
    expect(
      permissions('android.permission.RECEIVE_BOOT_COMPLETED'),
      hasLength(1),
    );
    final bootReceiver = manifest.rootElement
        .findAllElements('receiver')
        .where(
          (e) =>
              e.getAttribute('name', namespaceUri: androidNs) ==
              'com.dexterous.flutterlocalnotifications.'
                  'ScheduledNotificationBootReceiver',
        )
        .single;
    final actions = bootReceiver
        .findAllElements('action')
        .map((e) => e.getAttribute('name', namespaceUri: androidNs))
        .toSet();
    expect(
      actions,
      containsAll(<String>[
        'android.intent.action.BOOT_COMPLETED',
        'android.intent.action.MY_PACKAGE_REPLACED',
      ]),
    );
  });
}
