import 'package:college_os/features/ai/domain/pdf_ai_context.dart';

/// A reference back to a specific PDF page that contributed to an AI answer.
///
/// [fileId] and [pageNumber] uniquely identify the page in the local database,
/// allowing the UI to open or highlight the source page.
///
/// [excerpt] is an optional short passage (≤ ~200 chars) that the AI
/// identified as the most relevant sentence or phrase from that page.  It is
/// `null` when the implementation cannot or chooses not to produce one.
class AiSourceReference {
  final int fileId;
  final int pageNumber;

  /// A short quoted or paraphrased passage from the source page, or `null`.
  final String? excerpt;

  const AiSourceReference({
    required this.fileId,
    required this.pageNumber,
    this.excerpt,
  });

  @override
  String toString() =>
      'AiSourceReference(fileId: $fileId, page: $pageNumber, excerpt: ${excerpt != null ? '"${excerpt!.substring(0, excerpt!.length.clamp(0, 40))}…"' : 'null'})';
}

/// The result of an [AiSearchService.ask] call.
///
/// [answer] is the model-generated response text.  It may be empty when the
/// model determined there was not enough context to answer.
///
/// [sources] lists the PDF pages that were used to produce [answer].  An
/// empty list means no pages were referenced (e.g. the answer came entirely
/// from the model's own knowledge, or the context was empty).
class AiSearchResult {
  /// The generated answer text.
  final String answer;

  /// Pages from the local PDF index that informed the answer.
  final List<AiSourceReference> sources;

  const AiSearchResult({
    required this.answer,
    required this.sources,
  });

  /// Convenience constructor for an empty / no-answer result.
  const AiSearchResult.empty()
      : answer = '',
        sources = const [];

  bool get hasAnswer => answer.isNotEmpty;
  bool get hasSources => sources.isNotEmpty;

  @override
  String toString() =>
      'AiSearchResult(chars: ${answer.length}, sources: ${sources.length})';
}

/// The question and its retrieved page context passed into an [AiSearchService].
///
/// Keeping these together avoids positional argument confusion at the call site
/// and makes it easy to log or cache the full request payload.
class AiSearchRequest {
  /// The raw question from the user.
  final String question;

  /// Pages retrieved from the local FTS5 index that are relevant to [question].
  /// May be empty if the index had no matches.
  final List<PdfAiContext> contexts;

  const AiSearchRequest({
    required this.question,
    required this.contexts,
  });
}
