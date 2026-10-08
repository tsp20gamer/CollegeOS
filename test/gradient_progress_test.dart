import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/shared/widgets/gradient_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('attendance indicators fit a compact phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientProgressRing(
                    key: Key('test_gradient_ring'),
                    value: .783,
                    semanticLabel: '78.3% attendance',
                    child: Text('78.3%'),
                  ),
                  SizedBox(height: 24),
                  GradientProgressBar(
                    value: .783,
                    semanticLabel: 'Attendance progress',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('78.3%'), findsOneWidget);
    expect(find.byKey(const Key('gradient_ring_track')), findsOneWidget);
    expect(find.byKey(const Key('gradient_ring_animated_arc')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('test_gradient_ring')),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
