import 'package:college_os/app/app_error_handling.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('release error view protects user data messaging', (
    tester,
  ) async {
    await tester.pumpWidget(const CollegeOsErrorView());

    expect(find.text('This section could not be displayed'), findsOneWidget);
    expect(find.textContaining('data is safe'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
