import 'package:college_os/features/notes/domain/ai_context.dart';

/// Contract for asking a question using locally retrieved PDF page context.
///
/// Implementations decide *how* to answer — e.g. using a cloud model like
/// Gemini, a local on-device model, or a stub for tests.  The rest of the
/// codebase depends only on this interface, so the backing implementation can
/// be swapped without touching any call-site.
///
/// **Responsibilities of an implementation:**
/// - Accept a [AiSearchRequest] containing the user question and retrieved
///   [PdfAiContext] pages.
/// - Return an [AiSearchResult] with the generated answer and zero or more
///   [AiSourceReference]s pointing back to the pages it used.
/// - Never throw; surface errors via [AiSearchResult.empty] or a result with
///   a descriptive [AiSearchResult.answer] like "Unable to answer right now.".
/// - Never write to the local database or modify indexed data.
///
/// **What this interface does NOT do:**
/// - It does not perform FTS retrieval — that is [PdfContextRepository]'s job.
/// - It does not manage API keys or credentials — those belong in the
///   implementation's constructor or a separate config layer.
abstract interface class AiSearchService {
  /// Answers [request.question] using [request.contexts] as grounding.
  ///
  /// [request.contexts] may be empty (e.g. no FTS matches); implementations
  /// should handle this gracefully and either return a safe fallback or an
  /// [AiSearchResult] with an empty [AiSearchResult.answer].
  ///
  /// This method is safe to call from a Riverpod provider or repository;
  /// it must never throw an unhandled exception.
  Future<AiSearchResult> ask(AiSearchRequest request);
}
