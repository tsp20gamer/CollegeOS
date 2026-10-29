import 'package:college_os/features/subject_files/presentation/widgets/pdf_page_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rail = find.byKey(const Key('pdf_page_scrubber_gestures'));
  final thumb = find.byKey(const Key('pdf_page_scrubber_thumb'));

  Future<void> pumpScrubber(
    WidgetTester tester, {
    required int pageCount,
    required int currentPage,
    required List<int> selected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 300,
              height: 400,
              child: PdfPageScrubber(
                pageCount: pageCount,
                currentPage: currentPage,
                onPageSelected: selected.add,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders nothing for a document with a single page', (
    tester,
  ) async {
    final selected = <int>[];
    await pumpScrubber(
      tester,
      pageCount: 1,
      currentPage: 1,
      selected: selected,
    );

    expect(rail, findsNothing);
    expect(thumb, findsNothing);
  });

  testWidgets('puts the thumb at the top of the first page and the bottom of '
      'the last', (tester) async {
    final selected = <int>[];
    await pumpScrubber(
      tester,
      pageCount: 10,
      currentPage: 1,
      selected: selected,
    );

    final track = tester.getRect(rail);
    // The rail keeps clear of the page's own edges: 16 px top and bottom.
    expect(track.height, 400 - 32);
    // One page out of ten, but never shorter than the 36 px grabbable floor.
    expect(tester.getRect(thumb).height, closeTo(track.height / 10, .1));
    expect(tester.getRect(thumb).top, closeTo(track.top, .5));

    await pumpScrubber(
      tester,
      pageCount: 10,
      currentPage: 10,
      selected: selected,
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(thumb).bottom, closeTo(track.bottom, .5));

    await pumpScrubber(
      tester,
      pageCount: 10,
      currentPage: 3,
      selected: selected,
    );
    await tester.pumpAndSettle();

    final travel = track.height - tester.getRect(thumb).height;
    expect(
      tester.getRect(thumb).top,
      closeTo(track.top + 2 / 9 * travel, .5),
      reason: 'page 3 of 10 belongs two ninths of the way down the rail',
    );
  });

  testWidgets('seeks to the page a tap lands on', (tester) async {
    final selected = <int>[];
    await pumpScrubber(
      tester,
      pageCount: 10,
      currentPage: 1,
      selected: selected,
    );
    await tester.pumpAndSettle();

    final track = tester.getRect(rail);
    await tester.tapAt(Offset(track.center.dx, track.bottom - 2));
    await tester.pumpAndSettle();

    expect(selected, [10]);
    expect(
      find.byKey(const Key('pdf_page_scrubber_bubble')),
      findsNothing,
      reason: 'a tap jumps to a page; nothing is left following the finger',
    );

    // A tap that lands on the page already on screen asks for nothing.
    selected.clear();
    await tester.tapAt(Offset(track.center.dx, track.top + 2));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });

  testWidgets('follows a drag down the rail and names the page under the '
      'finger', (tester) async {
    final selected = <int>[];
    await pumpScrubber(
      tester,
      pageCount: 8,
      currentPage: 1,
      selected: selected,
    );
    await tester.pumpAndSettle();

    final bubble = find.byKey(const Key('pdf_page_scrubber_bubble'));
    final pageLabel = find.byKey(const Key('pdf_page_scrubber_page_label'));
    expect(pageLabel, findsOneWidget);
    expect(
      find.descendant(of: pageLabel, matching: find.text('Page 1 of 8')),
      findsOneWidget,
    );

    final track = tester.getRect(rail);
    final gesture = await tester.startGesture(
      Offset(track.center.dx, track.top + 2),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(bubble, findsOneWidget);
    expect(
      find.descendant(of: bubble, matching: find.text('Page 1 of 8')),
      findsOneWidget,
    );

    await gesture.moveTo(Offset(track.center.dx, track.bottom - 2));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: bubble, matching: find.text('Page 8 of 8')),
      findsOneWidget,
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected.last, 8);
    expect(pageLabel, findsOneWidget);
    expect(
      bubble,
      findsNothing,
      reason: 'the bubble is feedback while scrubbing, not permanent chrome',
    );
  });

  testWidgets('exposes itself as a slider that steps a page at a time', (
    tester,
  ) async {
    final selected = <int>[];
    await pumpScrubber(
      tester,
      pageCount: 10,
      currentPage: 3,
      selected: selected,
    );
    await tester.pumpAndSettle();

    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(PdfPageScrubber),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.properties.slider, isTrue);
    expect(semantics.properties.value, 'Page 3 of 10');
    expect(semantics.properties.increasedValue, 'Page 4 of 10');
    expect(semantics.properties.decreasedValue, 'Page 2 of 10');

    semantics.properties.onIncrease!();
    semantics.properties.onDecrease!();
    expect(selected, [4, 2]);
  });
}
