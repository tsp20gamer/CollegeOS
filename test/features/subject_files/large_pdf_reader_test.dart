import 'dart:ui' as ui;

import 'package:college_os/features/subject_files/data/pdf_page_rasterizer.dart';
import 'package:college_os/features/subject_files/presentation/widgets/large_pdf_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Draws flat pages instantly and records what it was asked for.
class _FakeRasterizer implements PdfPageRasterizer {
  _FakeRasterizer(this.count, {Set<int> failOnce = const {}})
    : failOnce = {...failOnce};

  final int count;
  final Set<int> failOnce;
  final List<int> rendered = [];
  final List<(int, int)> sizes = [];
  int running = 0;
  int maxRunning = 0;
  bool closed = false;

  @override
  int get pageCount => count;

  @override
  Future<List<Size>> pageSizes() async =>
      List<Size>.filled(count, const Size(612, 792));

  @override
  Future<ui.Image> render(int pageNumber, int width, int height) async {
    running++;
    if (running > maxRunning) maxRunning = running;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (failOnce.remove(pageNumber)) {
        throw StateError('cannot draw $pageNumber');
      }
      rendered.add(pageNumber);
      sizes.add((width, height));
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      final picture = recorder.endRecording();
      // Small backing image: the reader only cares about its reported size.
      final image = picture.toImageSync(width, height);
      picture.dispose();
      return image;
    } finally {
      running--;
    }
  }

  @override
  Future<void> close() async => closed = true;
}

Future<void> _pumpReader(
  WidgetTester tester,
  _FakeRasterizer rasterizer, {
  LargePdfReaderController? controller,
  ValueChanged<int>? onPageChanged,
  GlobalKey<LargePdfReaderState>? key,
  int? initialPage,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargePdfReader(
          key: key,
          rasterizer: rasterizer,
          pageSizes: await rasterizer.pageSizes(),
          controller: controller,
          initialPageNumber: initialPage,
          onPageChanged: onPageChanged,
        ),
      ),
    ),
  );
}

Future<void> _settleRenders(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('builds and renders only the pages near the screen', (
    tester,
  ) async {
    final rasterizer = _FakeRasterizer(412);
    await _pumpReader(tester, rasterizer);
    await _settleRenders(tester);

    final built = find.byType(LargePdfPage).evaluate().length;
    expect(built, lessThanOrEqualTo(6));
    expect(rasterizer.rendered, containsAll(<int>[1, 2]));
    expect(rasterizer.rendered.toSet().length, lessThanOrEqualTo(6));
    expect(rasterizer.maxRunning, 1);
    // Rendered at screen width x pixel ratio, not at the PDF's own size.
    for (final (width, _) in rasterizer.sizes) {
      expect(width, 1080);
    }
  });

  testWidgets('a fling through 412 pages stays bounded', (tester) async {
    final rasterizer = _FakeRasterizer(412);
    final key = GlobalKey<LargePdfReaderState>();
    var lastPage = 1;
    await _pumpReader(
      tester,
      rasterizer,
      key: key,
      onPageChanged: (page) => lastPage = page,
    );
    await _settleRenders(tester);

    // Drag the whole document quickly, a screen at a time, never pausing
    // long enough for a page to be worth drawing.
    for (var i = 0; i < 400; i++) {
      await tester.dragFrom(const Offset(200, 700), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 16));
      final state = key.currentState!;
      expect(find.byType(LargePdfPage).evaluate().length, lessThanOrEqualTo(8));
      expect(state.cache.length, lessThanOrEqualTo(12));
      expect(state.cache.bytes, lessThanOrEqualTo(96 * 1024 * 1024));
    }
    expect(lastPage, greaterThan(150));
    // Pages flung past were skipped, not rendered.
    expect(rasterizer.rendered.length, lessThan(60));

    await _settleRenders(tester);
    expect(rasterizer.maxRunning, 1);
    final state = key.currentState!;
    expect(state.cache.length, lessThanOrEqualTo(12));
    expect(
      rasterizer.rendered,
      contains(state.currentPage),
      reason: 'the page the fling stopped on is drawn',
    );
  });

  testWidgets('scrubber jumps and reports the page', (tester) async {
    final rasterizer = _FakeRasterizer(300);
    final controller = LargePdfReaderController();
    addTearDown(controller.dispose);
    final pages = <int>[];
    await _pumpReader(
      tester,
      rasterizer,
      controller: controller,
      onPageChanged: pages.add,
    );
    controller.jumpToPage(250);
    await _settleRenders(tester);
    expect(pages.last, 250);
    expect(rasterizer.rendered, contains(250));
    expect(rasterizer.rendered, isNot(contains(100)));
  });

  testWidgets('opens at the requested page', (tester) async {
    final rasterizer = _FakeRasterizer(300);
    final pages = <int>[];
    await _pumpReader(
      tester,
      rasterizer,
      initialPage: 116,
      onPageChanged: pages.add,
    );
    await _settleRenders(tester);
    expect(pages.last, 116);
    expect(rasterizer.rendered, contains(116));
  });

  testWidgets('a page that fails shows a retry instead of crashing', (
    tester,
  ) async {
    final rasterizer = _FakeRasterizer(10, failOnce: {1});
    await _pumpReader(tester, rasterizer);
    await _settleRenders(tester);
    expect(find.text("Couldn't show page 1"), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry'));
    await _settleRenders(tester);
    expect(find.text("Couldn't show page 1"), findsNothing);
    expect(rasterizer.rendered, contains(1));
  });

  testWidgets('double tap zooms and re-renders sharper within budget', (
    tester,
  ) async {
    final rasterizer = _FakeRasterizer(20);
    await _pumpReader(tester, rasterizer);
    await _settleRenders(tester);
    final before = rasterizer.sizes.length;

    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(200, 300));
    await _settleRenders(tester);

    final sharper = rasterizer.sizes.skip(before).toList();
    expect(sharper, isNotEmpty);
    for (final (width, height) in sharper) {
      expect(width, greaterThan(1080));
      expect(width * height, lessThanOrEqualTo(8 * 1000 * 1000));
    }
  });

  testWidgets('closing the reader drops queued renders and the cache', (
    tester,
  ) async {
    final rasterizer = _FakeRasterizer(100);
    final key = GlobalKey<LargePdfReaderState>();
    await _pumpReader(tester, rasterizer, key: key);
    await tester.pump(const Duration(milliseconds: 100));
    final state = key.currentState!;
    await tester.pumpWidget(const SizedBox.shrink());
    await _settleRenders(tester);
    expect(state.cache.length, 0);
    expect(state.queue.pendingCount, 0);
  });
}
