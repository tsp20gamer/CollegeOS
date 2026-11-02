import 'dart:async';

import 'package:college_os/features/subject_files/data/pdf_render_budget.dart';
import 'package:college_os/features/subject_files/data/pdf_render_queue.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:college_os/features/subject_files/presentation/widgets/large_pdf_reader.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfRenderBudget', () {
    const budget = PdfRenderBudget();

    test('renders at the on-screen width times the pixel ratio', () {
      final size = budget.sizeFor(
        pageWidth: 612,
        pageHeight: 792,
        displayWidth: 411,
        devicePixelRatio: 2.625,
      );
      expect(size.width, 1078);
      expect(size.height, (1078.875 * 792 / 612).floor());
    });

    test('ignores the PDF native size of huge pages', () {
      // An A0 poster declared at 2384 x 3370 pt renders like any other page.
      final poster = budget.sizeFor(
        pageWidth: 2384,
        pageHeight: 3370,
        displayWidth: 411,
        devicePixelRatio: 2.625,
      );
      expect(poster.width, 1078);
      expect(poster.pixels, lessThan(2 * 1000 * 1000));
    });

    test('zoom renders sharper but never past the pixel budget', () {
      final zoomed = budget.sizeFor(
        pageWidth: 612,
        pageHeight: 792,
        displayWidth: 411,
        devicePixelRatio: 2.625,
        zoom: 3,
      );
      expect(zoomed.pixels, lessThanOrEqualTo(budget.maxPixelsPerPage));
      expect(zoomed.width, greaterThan(2000));

      final deeper = budget.sizeFor(
        pageWidth: 612,
        pageHeight: 792,
        displayWidth: 411,
        devicePixelRatio: 2.625,
        zoom: 5,
      );
      expect(deeper, zoomed, reason: 'zoom past 3x reuses the 3x render');
    });

    test('a very tall page is capped by its longest side', () {
      final strip = budget.sizeFor(
        pageWidth: 600,
        pageHeight: 20000,
        displayWidth: 411,
        devicePixelRatio: 3,
      );
      expect(strip.height, lessThanOrEqualTo(budget.maxSidePixels));
      expect(strip.pixels, lessThanOrEqualTo(budget.maxPixelsPerPage));
    });

    test('nonsense sizes still give a small valid render', () {
      final size = budget.sizeFor(
        pageWidth: 0,
        pageHeight: double.nan,
        displayWidth: double.infinity,
        devicePixelRatio: 0,
      );
      expect(size.width, greaterThanOrEqualTo(1));
      expect(size.height, greaterThanOrEqualTo(1));
      expect(size.pixels, lessThanOrEqualTo(budget.maxPixelsPerPage));
    });
  });

  group('BoundedLruCache', () {
    test('evicts least recently used by count and disposes once', () {
      final evicted = <String>[];
      final cache = BoundedLruCache<String, int>(
        maxEntries: 3,
        maxBytes: 1000,
        sizeOf: (v) => v,
        onEvict: (k, _) => evicted.add(k),
      );
      cache.put('a', 1);
      cache.put('b', 1);
      cache.put('c', 1);
      expect(cache.get('a'), 1); // a is now the newest
      cache.put('d', 1);
      expect(evicted, ['b']);
      expect(cache.keys, ['c', 'a', 'd']);
    });

    test('evicts by bytes', () {
      final evicted = <String>[];
      final cache = BoundedLruCache<String, int>(
        maxEntries: 100,
        maxBytes: 10,
        sizeOf: (v) => v,
        onEvict: (k, _) => evicted.add(k),
      );
      cache.put('a', 4);
      cache.put('b', 4);
      cache.put('c', 4);
      expect(evicted, ['a']);
      expect(cache.bytes, 8);
    });

    test('a value bigger than the whole budget is not kept', () {
      final evicted = <String>[];
      final cache = BoundedLruCache<String, int>(
        maxEntries: 4,
        maxBytes: 10,
        sizeOf: (v) => v,
        onEvict: (k, _) => evicted.add(k),
      );
      cache.put('huge', 11);
      expect(cache.length, 0);
      expect(evicted, ['huge']);
    });

    test('replace, remove and clear hand every value back', () {
      final evicted = <int>[];
      final cache = BoundedLruCache<String, int>(
        maxEntries: 4,
        maxBytes: 100,
        sizeOf: (v) => 1,
        onEvict: (_, v) => evicted.add(v),
      );
      cache.put('a', 1);
      cache.put('a', 2);
      cache.put('b', 3);
      cache.remove('b');
      cache.put('c', 4);
      cache.clear();
      expect(evicted, [1, 3, 2, 4]);
      expect(cache.length, 0);
      expect(cache.bytes, 0);
    });
  });

  group('PdfRenderQueue', () {
    test('runs one job at a time, newest request first', () async {
      final queue = PdfRenderQueue(maxConcurrent: 1);
      final order = <int>[];
      var running = 0;
      var maxRunning = 0;
      Future<int> job(int n) async {
        running++;
        maxRunning = running > maxRunning ? running : maxRunning;
        order.add(n);
        await Future<void>.delayed(const Duration(milliseconds: 5));
        running--;
        return n;
      }

      final tickets = [for (var i = 1; i <= 5; i++) queue.schedule(() => job(i))];
      final results = await Future.wait(tickets.map((t) => t.future));
      expect(results, [1, 2, 3, 4, 5]);
      expect(maxRunning, 1);
      // 1 starts at once; then the newest waiting request goes first.
      expect(order, [1, 5, 4, 3, 2]);
    });

    test('a cancelled request never reaches the renderer', () async {
      final queue = PdfRenderQueue(maxConcurrent: 1);
      final ran = <int>[];
      final gate = Completer<void>();
      final first = queue.schedule(() async {
        ran.add(1);
        await gate.future;
        return 1;
      });
      final second = queue.schedule(() async {
        ran.add(2);
        return 2;
      });
      second.cancel();
      gate.complete();
      expect(await first.future, 1);
      expect(await second.future, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(ran, [1]);
    });

    test('a result that lands after cancel is discarded', () async {
      final discarded = <Object?>[];
      final queue = PdfRenderQueue(onDiscard: discarded.add);
      final gate = Completer<void>();
      final ticket = queue.schedule(() async {
        await gate.future;
        return 'image';
      });
      await Future<void>.delayed(Duration.zero);
      ticket.cancel();
      gate.complete();
      expect(await ticket.future, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(discarded, ['image']);
    });

    test('a failing render fails only its own ticket', () async {
      final queue = PdfRenderQueue();
      final bad = queue.schedule<int>(() async => throw StateError('broken'));
      final good = queue.schedule<int>(() async => 7);
      await expectLater(bad.future, throwsStateError);
      expect(await good.future, 7);
    });

    test('close cancels waiting work and refuses new work', () async {
      final queue = PdfRenderQueue();
      final gate = Completer<void>();
      final running = queue.schedule(() async {
        await gate.future;
        return 1;
      });
      final waiting = queue.schedule(() async => 2);
      queue.close();
      final late = queue.schedule(() async => 3);
      gate.complete();
      expect(await waiting.future, isNull);
      expect(await late.future, isNull);
      // Work already on the renderer finishes; its page cancels it if gone.
      expect(await running.future, 1);
    });
  });

  group('large reader choice and layout', () {
    test('long or heavy documents use the large reader', () {
      expect(shouldUseLargePdfReader(fileBytes: 2 << 20, pageCount: 12), isFalse);
      expect(shouldUseLargePdfReader(fileBytes: 2 << 20, pageCount: 80), isTrue);
      expect(shouldUseLargePdfReader(fileBytes: 91004791, pageCount: 412), isTrue);
      expect(shouldUseLargePdfReader(fileBytes: 25 << 20, pageCount: 10), isTrue);
    });

    test('layout finds the page under an offset', () {
      final layout = LargePdfLayout.compute(
        [const Size(100, 100), const Size(100, 200), const Size(50, 50)],
        100,
      );
      expect(layout.tops, [0, 100 + kLargePdfPageGap, 300 + 2 * kLargePdfPageGap]);
      expect(layout.totalHeight, 400 + 2 * kLargePdfPageGap);
      expect(layout.indexAt(-5), 0);
      expect(layout.indexAt(99), 0);
      expect(layout.indexAt(150), 1);
      expect(layout.indexAt(10000), 2);
      expect(layout.range(50, 150), (0, 1));
    });
  });
}
