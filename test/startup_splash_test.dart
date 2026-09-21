import 'package:college_os/app/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the CollegeOS background immediately without loading UI', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.byKey(const Key('startup_background')), findsOneWidget);
    expect(find.byKey(const Key('startup_splash')), findsOneWidget);
    expect(find.byKey(const Key('startup_content_fade')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Loading'), findsNothing);
    expect(_contentOpacity(tester), 0);
  });

  testWidgets('animates logo layers in sequence and crossfades into content', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _pumpUntilCalendarStarts(tester);

    expect(_layerOpacity(tester, 'startup_calendar'), inExclusiveRange(0, 1));
    expect(_layerOpacity(tester, 'startup_cap'), 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(_layerOpacity(tester, 'startup_calendar'), greaterThan(.95));
    expect(_layerOpacity(tester, 'startup_cap'), greaterThan(0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(_layerOpacity(tester, 'startup_cap'), closeTo(1, .001));
    expect(_layerOpacity(tester, 'startup_check'), greaterThan(0));

    await tester.pump(const Duration(milliseconds: 450));
    expect(_layerOpacity(tester, 'startup_check'), closeTo(1, .001));
    expect(_layerOpacity(tester, 'startup_wordmark'), inExclusiveRange(0, 1));
    expect(_layerOpacity(tester, 'startup_glow'), greaterThan(.15));

    await tester.pump(const Duration(milliseconds: 600));
    expect(_layerOpacity(tester, 'startup_wordmark'), closeTo(1, .001));
    expect(_contentOpacity(tester), 0);
    expect(_splashOpacity(tester), 1);

    await tester.pump(const Duration(milliseconds: 300));
    expect(_contentOpacity(tester), inExclusiveRange(0, 1));
    expect(_splashOpacity(tester), inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('startup_splash')), findsNothing);
    expect(find.byKey(const Key('next_screen')), findsOneWidget);
  });

  testWidgets('reconstructs the supplied logo geometry responsively', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(600, 1000),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_testApp());
      await _pumpUntilCalendarStarts(tester);
      await tester.pump(const Duration(milliseconds: 1700));

      final logo = tester.getRect(find.byKey(const Key('startup_logo')));
      final cap = tester.getRect(find.byKey(const Key('startup_cap')));
      final calendar = tester.getRect(
        find.byKey(const Key('startup_calendar')),
      );
      final check = tester.getRect(find.byKey(const Key('startup_check')));
      final wordmark = tester.getRect(
        find.byKey(const Key('startup_wordmark')),
      );
      final scale = logo.width / 808;

      expect(logo.center.dx, closeTo(size.width / 2, .01));
      expect(logo.center.dy, closeTo(size.height / 2, .01));
      expect(logo.left, greaterThanOrEqualTo(0));
      expect(logo.top, greaterThanOrEqualTo(0));
      expect(logo.right, lessThanOrEqualTo(size.width));
      expect(logo.bottom, lessThanOrEqualTo(size.height));
      expect(cap.left, closeTo(logo.left + 134 * scale, .02));
      expect(cap.top, closeTo(logo.top, .02));
      expect(calendar.left, closeTo(logo.left + 173 * scale, .02));
      expect(calendar.top, closeTo(logo.top + 253 * scale, .02));
      expect(check.left, closeTo(logo.left + 412 * scale, .02));
      expect(check.top, closeTo(logo.top + 452 * scale, .02));
      expect(wordmark.left, closeTo(logo.left, .02));
      expect(wordmark.top, closeTo(logo.top + 671 * scale, .02));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('uses a static assembled mark when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(disableAnimations: true));
    await _pumpUntilLogoIsAssembled(tester);

    expect(_layerOpacity(tester, 'startup_calendar'), closeTo(1, .001));
    expect(_layerOpacity(tester, 'startup_cap'), closeTo(1, .001));
    expect(_layerOpacity(tester, 'startup_check'), closeTo(1, .001));
    expect(_layerOpacity(tester, 'startup_wordmark'), closeTo(1, .001));

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 125));
    expect(_contentOpacity(tester), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(find.byKey(const Key('startup_splash')), findsNothing);
  });

  testWidgets('disabled splash renders content without preparing animation', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(enabled: false));

    expect(find.byKey(const Key('next_screen')), findsOneWidget);
    expect(find.byKey(const Key('startup_splash')), findsNothing);
    expect(find.byKey(const Key('startup_background')), findsNothing);
  });
}

Widget _testApp({bool enabled = true, bool disableAnimations = false}) {
  return MaterialApp(
    builder: disableAnimations
        ? (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          )
        : null,
    home: CollegeStartupSplash(
      enabled: enabled,
      child: const ColoredBox(
        key: Key('next_screen'),
        color: Color(0xFF101116),
      ),
    ),
  );
}

Future<void> _pumpUntilCalendarStarts(WidgetTester tester) async {
  await _waitForSplashAssets(tester);
  for (var i = 0; i < 100; i++) {
    if (_layerOpacity(tester, 'startup_calendar') > 0) return;
    await tester.pump(const Duration(milliseconds: 25));
  }
  fail('Splash animation did not start.');
}

Future<void> _pumpUntilLogoIsAssembled(WidgetTester tester) async {
  await _waitForSplashAssets(tester);
  for (var i = 0; i < 100; i++) {
    if (_layerOpacity(tester, 'startup_wordmark') == 1) return;
    await tester.pump(const Duration(milliseconds: 25));
  }
  fail('Reduced-motion splash did not assemble.');
}

Future<void> _waitForSplashAssets(WidgetTester tester) async {
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
}

double _layerOpacity(WidgetTester tester, String key) =>
    tester.widget<FadeTransition>(find.byKey(Key(key))).opacity.value;

double _splashOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const Key('startup_splash')))
    .opacity
    .value;

double _contentOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.byKey(const Key('startup_content_fade')))
    .opacity
    .value;
