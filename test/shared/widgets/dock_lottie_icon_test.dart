import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/shared/widgets/dock_lottie_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const _asset = 'assets/lottie/home.json';
const _accent = Color(0xFF2563EB);
const _muted = Color(0xFF49454F);

/// Every animation the dock ships.
const _shipped = [
  _asset,
  'assets/lottie/completed.json',
  'assets/lottie/calendar.json',
  'assets/lottie/tasks.json',
  'assets/lottie/library.json',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Lottie parses from the real asset bundle; loading each composition once
    // keeps every test's own pumps free of real asynchronous work.
    for (final asset in _shipped) {
      final composition = await AssetLottie(asset).load();
      expect(
        composition.duration,
        greaterThan(Duration.zero),
        reason: '$asset must carry a playable timeline',
      );
      // One drawn family: all five share the dock's 36 px artboard, so the
      // glyph scale measured per destination is comparable between them.
      expect(composition.bounds.width, 36, reason: asset);
      expect(composition.bounds.height, 36, reason: asset);
    }
  });

  testWidgets('is tinted and rests on its finished frame while unselected', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: false));
    await tester.pump();

    expect(find.byType(Lottie), findsOneWidget);
    expect(_tint(tester), ColorFilter.mode(_muted, BlendMode.srcIn));
    // The family draws itself in from an empty first frame, so resting at the
    // start would leave an unselected destination blank.
    expect(_controller(tester).value, 1.0);
    expect(_controller(tester).isAnimating, isFalse);
  });

  testWidgets('plays once when chosen and holds the final frame', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: false));
    await tester.pump();
    expect(_controller(tester).value, 1.0);

    await tester.pumpWidget(_host(selected: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final midFlight = _controller(tester).value;
    expect(midFlight, greaterThan(0.0));
    expect(midFlight, lessThan(1.0));
    expect(_controller(tester).isAnimating, isTrue);

    await tester.pump(AppDurations.dockLottieMaxPlayback);
    expect(_controller(tester).value, 1.0);
    expect(_controller(tester).isAnimating, isFalse);
    expect(_tint(tester), ColorFilter.mode(_accent, BlendMode.srcIn));
  });

  testWidgets('settles on the finished frame when it is already selected', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: true));
    await tester.pump();

    expect(_controller(tester).value, 1.0);
    expect(_controller(tester).isAnimating, isFalse);
  });

  testWidgets('returns to its resting frame when the destination is left', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: true, restAt: .55));
    await tester.pump();
    expect(_controller(tester).value, 1.0);

    await tester.pumpWidget(_host(selected: false, restAt: .55));
    await tester.pump();
    expect(_controller(tester).value, .55);
    expect(_controller(tester).isAnimating, isFalse);
  });

  testWidgets('rests on the configured frame while unselected', (tester) async {
    await tester.pumpWidget(_host(selected: false, restAt: .3));
    await tester.pump();
    expect(_controller(tester).value, .3);

    await tester.pumpWidget(_host(selected: true, restAt: .3));
    await tester.pump();
    await tester.pump(AppDurations.dockLottieMaxPlayback);
    expect(_controller(tester).value, 1.0);

    await tester.pumpWidget(_host(selected: false, restAt: .3));
    await tester.pump();
    expect(_controller(tester).value, .3);
    expect(_controller(tester).isAnimating, isFalse);
  });

  testWidgets('normalises the artwork inside the glyph box', (tester) async {
    await tester.pumpWidget(_host(selected: true, glyphScale: 2.2));
    await tester.pump();

    final scale = tester.widget<Transform>(
      find.descendant(
        of: find.byType(DockLottieIcon),
        matching: find.byType(Transform),
      ),
    );
    expect(scale.transform.getMaxScaleOnAxis(), closeTo(2.2, .001));
    expect(
      find.descendant(
        of: find.byType(DockLottieIcon),
        matching: find.byType(ClipRect),
      ),
      findsOneWidget,
      reason: 'the enlarged artwork is clipped to its own slot',
    );
  });

  testWidgets('shows the Material icon instead of the animation when motion '
      'is reduced', (tester) async {
    await tester.pumpWidget(_host(selected: true, reduceMotion: true));
    await tester.pump();

    expect(find.byType(Lottie), findsNothing);
    final fallback = tester.widget<Icon>(
      find.byKey(const Key('dock_icon_Home_true')),
    );
    expect(fallback.icon, Icons.space_dashboard_rounded);
    expect(fallback.color, _accent);
    expect(fallback.size, AppIconSize.md);
  });

  testWidgets('falls back to the Material icon when the asset cannot load', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(asset: 'assets/lottie/missing.json', selected: true),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // A failed load never reaches the player: nothing renders a composition and
    // the destination shows the Material glyph the dock used before.
    expect(find.byType(Lottie), findsNothing);
    expect(
      find.byKey(const Key('dock_icon_Home_true')),
      findsOneWidget,
      reason: 'a missing animation degrades to the Material glyph',
    );
    expect(
      tester.widget<Icon>(find.byKey(const Key('dock_icon_Home_true'))).icon,
      Icons.space_dashboard_rounded,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  String asset = _asset,
  required bool selected,
  bool reduceMotion = false,
  double glyphScale = 1,
  double restAt = 1,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: DockLottieIcon(
        asset: asset,
        label: 'Home',
        glyphScale: glyphScale,
        restAt: restAt,
        selected: selected,
        reduceMotion: reduceMotion,
        tint: selected ? _accent : _muted,
        fallbackIcon: selected
            ? Icons.space_dashboard_rounded
            : Icons.space_dashboard_outlined,
      ),
    ),
  ),
);

AnimationController _controller(WidgetTester tester) =>
    tester.widget<Lottie>(find.byType(Lottie)).controller
        as AnimationController;

ColorFilter? _tint(WidgetTester tester) =>
    tester.widget<ColorFiltered>(find.byType(ColorFiltered)).colorFilter;
