import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/shared/widgets/entrance.dart';
import 'package:college_os/shared/widgets/icon_pop.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:college_os/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Entrance', () {
    testWidgets('rises from transparent and settles at rest', (tester) async {
      const key = Key('section');
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: Entrance(key: key, child: Text('Section')),
          ),
        ),
      );

      expect(find.text('Section'), findsOneWidget);
      expect(_opacityOf(tester, key), 0);
      expect(_riseOf(tester, key), AppMotion.entranceRise);

      await tester.pumpAndSettle();

      expect(_opacityOf(tester, key), 1);
      expect(_riseOf(tester, key), 0);
    });

    testWidgets('later steps wait their turn in the wave', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              Entrance(key: Key('first'), child: Text('First')),
              Entrance(key: Key('later'), index: 3, child: Text('Later')),
            ],
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 80));

      expect(_opacityOf(tester, const Key('first')), greaterThan(0));
      expect(_opacityOf(tester, const Key('later')), 0);

      await tester.pumpAndSettle();

      expect(_opacityOf(tester, const Key('later')), 1);
    });

    testWidgets('shows the child at rest when motion is reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Entrance(key: Key('section'), child: Text('Section')),
          ),
        ),
      );

      expect(_opacityOf(tester, const Key('section')), 1);
      expect(_riseOf(tester, const Key('section')), 0);
    });

    testWidgets('shows the child at rest for accessibility navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(accessibleNavigation: true),
            child: Entrance(key: Key('section'), child: Text('Section')),
          ),
        ),
      );

      expect(_opacityOf(tester, const Key('section')), 1);
      expect(_riseOf(tester, const Key('section')), 0);
    });
  });

  group('IconPop', () {
    testWidgets('grows a new icon in and settles at rest', (tester) async {
      const key = Key('pop');
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: IconPop(
              key: key,
              popOnMount: true,
              fromScale: .5,
              child: Icon(Icons.circle),
            ),
          ),
        ),
      );

      // The first frame starts below resting size, then the pop peaks past it.
      expect(_scaleOf(tester, key), .5);

      await tester.pump(const Duration(milliseconds: 72));
      expect(_scaleOf(tester, key), closeTo(AppMotion.dockIconPeakScale, .01));

      await tester.pumpAndSettle();
      expect(_scaleOf(tester, key), 1);
    });

    testWidgets('replays only when its trigger changes', (tester) async {
      const key = Key('pop');
      Widget build({required bool selected}) => MaterialApp(
        home: Center(
          child: IconPop(
            key: key,
            trigger: selected,
            child: const Icon(Icons.circle),
          ),
        ),
      );

      await tester.pumpWidget(build(selected: false));
      await tester.pumpWidget(build(selected: false));
      await tester.pump(const Duration(milliseconds: 72));
      expect(_scaleOf(tester, key), 1);

      await tester.pumpWidget(build(selected: true));
      await tester.pump(const Duration(milliseconds: 72));
      expect(_scaleOf(tester, key), greaterThan(1));

      await tester.pumpAndSettle();
      expect(_scaleOf(tester, key), 1);
    });

    testWidgets('shows the icon at rest when motion is reduced', (
      tester,
    ) async {
      const key = Key('pop');
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: IconPop(
              key: key,
              popOnMount: true,
              fromScale: .5,
              child: Icon(Icons.circle),
            ),
          ),
        ),
      );

      expect(_scaleOf(tester, key), 1);
      await tester.pumpAndSettle();
      expect(_scaleOf(tester, key), 1);
    });

    testWidgets('section headers pop their icon coin in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              key: Key('header'),
              title: 'Today',
              icon: Icons.today_rounded,
            ),
          ),
        ),
      );

      expect(_scaleOf(tester, const Key('header')), lessThan(1));

      await tester.pumpAndSettle();
      expect(_scaleOf(tester, const Key('header')), 1);
    });
  });

  group('PressScale', () {
    testWidgets('shrinks while held and springs back on release', (
      tester,
    ) async {
      const key = Key('target');
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PressScale(
              key: key,
              pressedScale: .5,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      expect(_scaleOf(tester, key), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(_scaleOf(tester, key), .5);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scaleOf(tester, key), closeTo(1, .01));
    });

    testWidgets('releases the press when the finger slides away', (
      tester,
    ) async {
      const key = Key('target');
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: PressScale(
              key: key,
              pressedScale: .5,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(_scaleOf(tester, key), .5);

      // Sliding past the touch slop is a scroll, not a press: the child
      // springs back to rest while the finger is still down.
      await gesture.moveBy(const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(_scaleOf(tester, key), closeTo(1, .01));

      await gesture.up();
    });
  });
}

double _opacityOf(WidgetTester tester, Key entrance) => tester
    .widget<Opacity>(
      find.descendant(of: find.byKey(entrance), matching: find.byType(Opacity)),
    )
    .opacity;

double _riseOf(WidgetTester tester, Key entrance) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byKey(entrance),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getTranslation()
    .y;

double _scaleOf(WidgetTester tester, Key key) => tester
    .widget<Transform>(
      find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
    )
    .transform
    .storage[0];
