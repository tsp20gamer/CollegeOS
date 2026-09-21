import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android accepts opened and shared CollegeOS backup files', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.intent.action.VIEW'));
    expect(manifest, contains('android.intent.action.SEND'));
    expect(manifest, contains('application/x-collegeos'));
    expect(manifest, contains('application/octet-stream'));
    expect(manifest, contains('application/zip'));
    expect(manifest, contains('android:launchMode="singleTop"'));
  });
}
