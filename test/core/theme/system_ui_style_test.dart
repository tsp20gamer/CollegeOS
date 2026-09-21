import 'package:college_os/core/theme/system_ui_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('system icons remain readable in both CollegeOS themes', () {
    final light = AppSystemUiStyle.forBrightness(Brightness.light);
    final dark = AppSystemUiStyle.forBrightness(Brightness.dark);

    expect(light.statusBarIconBrightness, Brightness.dark);
    expect(light.systemNavigationBarIconBrightness, Brightness.dark);
    expect(dark.statusBarIconBrightness, Brightness.light);
    expect(dark.systemNavigationBarIconBrightness, Brightness.light);
  });
}
