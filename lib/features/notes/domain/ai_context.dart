import 'package:college_os/features/ai/domain/pdf_ai_context.dart';

/// Why an AI answer could not be produced.
///
/// The service never throws, so the failure reason travels with the result and
/// lets the controller map it onto a UI state (`offline`, `apiError`, …) without
/// guessing from human-readable text.
enum AiFailure {
  /// No failure — a normal answer (possibly a "not in your notes" answer, which
  /// is still a successful, grounded response).
  none,

  /// No API key was supplied at build time, so no request was attempted.
  notConfigured,

  /// The local FTS5 index returned nothing usable, so the model was never
  /// called. Answering would have meant inventing content.
  noContext,

  /// The device could not reach the network.
  offline,

  /// The request exceeded the configured timeout.
  timeout,

  /// The API rejected the request because of rate limiting or exhausted quota.
  rateLimited,

  /// The API rejected the credential (missing, invalid or unauthorised).
  unauthorized,

  /// The API returned a server-side error.
  server,

  /// A response arrived but could not be understood or contained no answer.
  malformedResponse,
}

/// A reference back to a specific PDF page that contributed to an AI answer.
///
/// [fileId] and [pageNumber] uniquely identify the page in the local database,
/// allowing the UI to open or highlight the source page.
///
/// [fileName] is resolved locally, not taken from the model, so a hallucinated
/// name can never be displayed next to a real page.
///
/// [excerpt] is an optional short passage (≤ ~200 chars) that the AI
/// identified as the most relevant sentence or phrase from that page.  It is
/// `null` when the implementation cannot or chooses not to produce one.
///
/// Every instance handed to the UI has already been validated against the pages
/// that were actually sent to the model — see `GeminiAiService`.
class AiSourceReference {
  final int fileId;
  final int pageNumber;

  /// A short quoted or paraphrased passage from the source page, or `null`.
  final String? excerpt;

  /// Display name of the source document, or `null` when unknown.
  final String? fileName;

  const AiSourceReference({
    required this.fileId,
    required this.pageNumber,
    this.excerpt,
    this.fileName,
  });

  /// Stable identity used for de-duplication and citation validation.
  String get pageKey => '$fileId:$pageNumber';

  @override
  String toString() =>
      'AiSourceReference(fileId: $fileId, page: $pageNumber, file: $fileName)';
}

/// The result of an [AiSearchService.ask] call.
///
/// [answer] is the model-generated response text.  It may be empty when the
/// model determined there was not enough context to answer.
///
/// [sources] lists the PDF pages that were used to produce [answer].  An
/// empty list means no pages were referenced (e.g. the model answered without
/// citing anything, or [failure] is set).
///
/// [grounded] is the model's own assessment of whether [answer] is fully
/// supported by the supplied context. It is `false` whenever the answer is a
/// "not found in your notes" response, so the UI can present that honestly
/// instead of dressing it up as an answer.
class AiSearchResult {
  /// The generated answer text.
  final String answer;

  /// Pages from the local PDF index that informed the answer.
  final List<AiSourceReference> sources;

  /// Whether the model claims the answer is fully supported by the context.
  final bool grounded;

  /// Populated when no answer could be produced. [AiFailure.none] otherwise.
  final AiFailure failure;

  const AiSearchResult({
    required this.answer,
    required this.sources,
    this.grounded = false,
    this.failure = AiFailure.none,
  });

  /// Convenience constructor for an empty / no-answer result.
  const AiSearchResult.empty()
    : answer = '',
      sources = const [],
      grounded = false,
      failure = AiFailure.none;

  /// A failed attempt, carrying a safe user-facing [message].
  const AiSearchResult.failed(this.failure, this.answer)
    : sources = const [],
      grounded = false;

  /// The answer was not found in the indexed notes. Not an error — it is the
  /// honest outcome the feature is designed to produce.
  const AiSearchResult.notFound()
    : answer = "I couldn't find this topic in your indexed notes.",
      sources = const [],
      grounded = false,
      failure = AiFailure.noContext;

  bool get hasAnswer => answer.isNotEmpty;
  bool get hasSources => sources.isNotEmpty;
  bool get isFailure => failure != AiFailure.none;

  @override
  String toString() =>
      'AiSearchResult(chars: ${answer.length}, '
      'sources: ${sources.length}, grounded: $grounded, failure: $failure)';
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

  /// Phase 1 sends independent questions only; this type exists so conversation
  /// history can be added later without changing the service signature.
  const AiSearchRequest({required this.question, required this.contexts});
}
