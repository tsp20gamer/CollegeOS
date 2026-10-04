import 'package:college_os/features/ai/domain/ai_context_builder.dart';
import 'package:college_os/features/ai/domain/ai_context_limits.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:flutter_test/flutter_test.dart';

PdfAiContext _page(
  int pageNumber, {
  required String text,
  int fileId = 7,
  String? fileName = 'Engineering Physics Notes.pdf',
  double? rank,
}) {
  return PdfAiContext(
    fileId: fileId,
    pageNumber: pageNumber,
    pageText: text,
    rank: rank,
    fileName: fileName,
  );
}

void main() {
  group('AiContextBuilder', () {
    test('labels every block with its source file and page', () {
      final bundle = const AiContextBuilder().build([
        _page(42, text: 'A PN junction diode conducts in one direction.'),
        _page(43, text: 'Reverse bias widens the depletion region.'),
      ]);

      expect(bundle.blocks, hasLength(2));
      expect(bundle.promptContext, contains('[Source 1]'));
      expect(bundle.promptContext, contains('[Source 2]'));
      expect(
        bundle.promptContext,
        contains('File: Engineering Physics Notes.pdf'),
      );
      expect(bundle.promptContext, contains('Page: 42'));
      expect(bundle.promptContext, contains('Page: 43'));

      // Blocks appear in relevance order and keep their own text.
      expect(
        bundle.promptContext.indexOf('Page: 42'),
        lessThan(bundle.promptContext.indexOf('Page: 43')),
      );
    });

    test('caps the number of pages at maxContextPages', () {
      final pages = [
        for (var i = 1; i <= 20; i++) _page(i, text: 'content of page $i'),
      ];

      final bundle = const AiContextBuilder().build(pages);

      expect(bundle.blocks, hasLength(AiContextLimits.defaultMaxContextPages));
      expect(bundle.blocks.last.pageNumber, 8);
    });

    test('honours a custom page-count limit', () {
      final bundle = const AiContextBuilder(AiContextLimits(maxContextPages: 3))
          .build([
            for (var i = 1; i <= 10; i++) _page(i, text: 'content of page $i'),
          ]);

      expect(bundle.blocks, hasLength(3));
      expect(bundle.blocks.map((b) => b.pageNumber), [1, 2, 3]);
    });

    test('truncates a single oversized page instead of letting it win', () {
      final bundle = const AiContextBuilder(
        AiContextLimits(maxCharsPerPage: 100, maxTotalContextChars: 10000),
      ).build([_page(12, text: 'x' * 5000)]);

      expect(bundle.blocks, hasLength(1));
      expect(bundle.blocks.single.text.length, lessThanOrEqualTo(130));
      expect(
        bundle.blocks.single.text,
        endsWith(AiContextLimits.truncationMarker),
        reason: 'the model must know the page was cut short',
      );
    });

    test('stops adding pages once the total character budget is spent', () {
      final bundle =
          const AiContextBuilder(
            AiContextLimits(
              maxContextPages: 8,
              maxCharsPerPage: 1000,
              maxTotalContextChars: 250,
            ),
          ).build([
            _page(1, text: 'a' * 200),
            _page(2, text: 'b' * 200),
            _page(3, text: 'c' * 200),
          ]);

      expect(bundle.blocks, hasLength(1));
      expect(bundle.totalChars, lessThanOrEqualTo(250));
      expect(
        bundle.blocks.single.pageNumber,
        1,
        reason: 'higher-ranked pages keep their place; lower-ranked ones drop',
      );
    });

    test(
      'keeps at least one page when the total budget is smaller than one page',
      () {
        // A tiny budget must not turn a real match into "no context".
        final bundle = const AiContextBuilder(
          AiContextLimits(maxCharsPerPage: 500, maxTotalContextChars: 40),
        ).build([_page(9, text: 'y' * 500)]);

        expect(bundle.blocks, hasLength(1));
        expect(bundle.totalChars, lessThanOrEqualTo(40));
      },
    );

    test('preserves page identity so citations can be validated', () {
      final bundle = const AiContextBuilder().build([
        _page(12, text: 'first', fileId: 3),
        _page(13, text: 'second', fileId: 3),
        _page(4, text: 'third', fileId: 9),
      ]);

      expect(bundle.suppliedPageKeys, {'3:12', '3:13', '9:4'});
      expect(bundle.blocks.map((b) => b.fileId), [3, 3, 9]);
      expect(bundle.blocks.map((b) => b.sourceIndex), [1, 2, 3]);
    });

    test('drops duplicate pages and empty pages', () {
      final bundle = const AiContextBuilder().build([
        _page(12, text: 'real content'),
        _page(12, text: 'real content'),
        _page(13, text: '   \n\t  '),
      ]);

      expect(bundle.blocks, hasLength(1));
      expect(bundle.blocks.single.pageNumber, 12);
    });

    test('returns an empty bundle for no pages', () {
      final bundle = const AiContextBuilder().build([]);

      expect(bundle.isEmpty, isTrue);
      expect(bundle.promptContext, isEmpty);
      expect(bundle.suppliedPageKeys, isEmpty);
    });

    test('falls back to a synthetic file name when the row is missing', () {
      final bundle = const AiContextBuilder().build([
        _page(5, text: 'content', fileId: 21, fileName: null),
      ]);

      expect(bundle.promptContext, contains('File: Document 21'));
    });
  });
}
