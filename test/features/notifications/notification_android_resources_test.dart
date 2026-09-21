import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release build retains the configured Android notification icon', () {
    final platformSource = File(
      'lib/core/services/notifications/android_notification_platform.dart',
    ).readAsStringSync();
    final icon = File('android/app/src/main/res/drawable/ic_notification.xml');
    final keepRules = File(
      'android/app/src/main/res/raw/keep.xml',
    ).readAsStringSync();

    expect(
      platformSource,
      contains("AndroidInitializationSettings('ic_notification')"),
    );
    expect(icon.existsSync(), isTrue);
    expect(keepRules, contains('@drawable/ic_notification'));
  });
}
