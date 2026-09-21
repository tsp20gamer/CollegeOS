import 'package:college_os/app/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captures the assembled splash logo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: CollegeStartupSplash(child: ColoredBox(color: Colors.black)),
      ),
    );
    final context = tester.element(find.byType(CollegeStartupSplash));
    await tester.runAsync(
      () => Future.wait(
        const [
          'assets/splash/splash_background_1080x1920.png',
          'assets/splash/subtle_noise.png',
          'assets/splash/splash_glow.png',
          'assets/splash/collegeos_calendar.png',
          'assets/splash/collegeos_cap.png',
          'assets/splash/collegeos_check.png',
          'assets/splash/collegeos_wordmark.png',
        ].map((asset) => precacheImage(AssetImage(asset), context)),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 100; i++) {
      final opacity = tester
          .widget<FadeTransition>(find.byKey(const Key('startup_calendar')))
          .opacity
          .value;
      if (opacity > 0) break;
      await tester.pump(const Duration(milliseconds: 25));
    }
    expect(
      tester
          .widget<FadeTransition>(find.byKey(const Key('startup_calendar')))
          .opacity
          .value,
      greaterThan(0),
    );
    await tester.pump(const Duration(milliseconds: 1675));

    await expectLater(
      find.byKey(const Key('startup_splash')),
      matchesGoldenFile('goldens/collegeos_splash_assembled_390x844.png'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
