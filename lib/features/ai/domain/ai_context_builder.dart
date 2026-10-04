import 'package:college_os/features/ai/domain/ai_context_limits.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';

/// One locally retrieved page, prepared for the model prompt.
///
/// The block is the ground truth for citation validation: an answer may only
/// cite a `(fileId, pageNumber)` pair that exists in the block list, which is
/// exactly why the model is asked to copy `File ID` and `Page` verbatim.
class AiContextBlock {
  const AiContextBlock({
    required this.sourceIndex,
    required this.fileId,
    required this.fileName,
    required this.pageNumber,
    required this.text,
  });

  /// 1-based position in the prompt, used for the `[Source N]` label.
  final int sourceIndex;

  final int fileId;
  final String fileName;
  final int pageNumber;
  final String text;

  /// The heading the model sees above the page text.
  String get label =>
      '[Source $sourceIndex]\n'
      'File: $fileName\n'
      'File ID: $fileId\n'
      'Page: $pageNumber';

  /// Full block as embedded in the prompt.
  String render() => '$label\n\n$text';

  /// `"<fileName> — page <N>"`, used in logs and UI-adjacent messages.
  String get shortDescription => '$fileName — page $pageNumber';

  @override
  String toString() =>
      'AiContextBlock(#$sourceIndex, fileId: $fileId, page: $pageNumber, chars: ${text.length})';
}

/// The result of bounded context assembly.
class AiContextBundle {
  const AiContextBundle({required this.blocks, required this.promptContext});

  /// Blocks that survived the size limits, in relevance order.
  final List<AiContextBlock> blocks;

  /// The labelled text placed in the prompt (empty when [blocks] is empty).
  final String promptContext;

  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;

  /// Total characters actually sent, for logging and tests.
  int get totalChars => blocks.fold(0, (sum, b) => sum + b.text.length);

  /// `(fileId, pageNumber)` pairs handed to the model. A citation is valid only
  /// if it appears here.
  Set<String> get suppliedPageKeys => {
    for (final b in blocks) AiContextBuilder.pageKey(b.fileId, b.pageNumber),
  };

  static const AiContextBundle empty = AiContextBundle(
    blocks: [],
    promptContext: '',
  );

  @override
  String toString() =>
      'AiContextBundle(blocks: ${blocks.length}, chars: $totalChars)';
}

/// Assembles retrieved pages into a bounded, labelled prompt context.
///
/// Responsibilities, in order:
///  1. cap the number of pages ([AiContextLimits.maxContextPages]),
///  2. drop empty pages rather than wasting budget on them,
///  3. truncate any single oversized page ([AiContextLimits.maxCharsPerPage]),
///  4. stop before the total budget is exceeded
///     ([AiContextLimits.maxTotalContextChars]),
///  5. keep every page in its own labelled block so page boundaries survive.
///
/// Steps 3–4 only ever cut text, never merge two pages into one block, so a
/// page number can always be traced back to what the model actually read.
class AiContextBuilder {
  const AiContextBuilder([this.limits = AiContextLimits.defaults]);

  final AiContextLimits limits;

  /// Stable identity of a source page, shared with citation validation.
  static String pageKey(int fileId, int pageNumber) => '$fileId:$pageNumber';

  /// Builds the bundle for [pages], which are expected to already be sorted by
  /// FTS5 relevance (most relevant first).
  AiContextBundle build(List<PdfAiContext> pages) {
    if (pages.isEmpty) return AiContextBundle.empty;

    final blocks = <AiContextBlock>[];
    final seenPages = <String>{};
    var usedChars = 0;
    var sourceIndex = 1;

    for (final page in pages) {
      if (blocks.length >= limits.maxContextPages) break;

      // The same page can be returned twice when a question repeats a term.
      if (!seenPages.add(pageKey(page.fileId, page.pageNumber))) continue;

      var text = _prepareText(page.pageText);
      if (text.isEmpty) continue;

      final remaining = limits.maxTotalContextChars - usedChars;
      if (remaining <= 0) break;

      if (text.length > remaining) {
        // The first page is always kept, cut down to whatever budget exists, so
        // a small total budget can never turn a real match into "no context".
        // Later pages are dropped instead of squeezed: a half page of a
        // lower-ranked source is worse grounding than no source at all.
        if (blocks.isNotEmpty) break;
        text = _fitToBudget(text, remaining);
        if (text.isEmpty) break;
      }

      blocks.add(
        AiContextBlock(
          sourceIndex: sourceIndex,
          fileId: page.fileId,
          fileName: page.displayFileName,
          pageNumber: page.pageNumber,
          text: text,
        ),
      );
      usedChars += text.length;
      sourceIndex++;
    }

    if (blocks.isEmpty) return AiContextBundle.empty;

    return AiContextBundle(
      blocks: blocks,
      promptContext: blocks.map((b) => b.render()).join('\n\n---\n\n'),
    );
  }

  /// Normalises whitespace and enforces the per-page character limit.
  String _prepareText(String raw) {
    final normalised = raw.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    if (normalised.isEmpty) return '';

    if (normalised.length <= limits.maxCharsPerPage) return normalised;

    return normalised.substring(0, limits.maxCharsPerPage) +
        AiContextLimits.truncationMarker;
  }

  /// Truncates [text] to exactly [budget] characters, marker included, or
  /// returns an empty string when there is not enough room for any content.
  String _fitToBudget(String text, int budget) {
    if (budget >= text.length) return text;

    final marker = AiContextLimits.truncationMarker;
    if (budget <= marker.length) return '';
    return text.substring(0, budget - marker.length) + marker;
  }
}
