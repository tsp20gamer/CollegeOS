import 'package:college_os/core/ai/gemini_config.dart';
import 'package:college_os/features/ai/application/pdf_ai_context_providers.dart';
import 'package:college_os/features/notes/data/gemini_ai_service.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_search_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [GeminiConfig] read from compile-time `--dart-define`.
///
/// Returns `null` when `GEMINI_API_KEY` was not supplied at build time.
/// Downstream providers should check for `null` and degrade gracefully.
final geminiConfigProvider = Provider<GeminiConfig?>((ref) {
  return GeminiConfig.fromEnvironment();
});

/// Provides the active [AiSearchService] implementation.
///
/// Currently wired to [GeminiAiService].  To swap implementations (e.g. for
/// tests or a different backend) override this provider in a
/// `ProviderScope(overrides: [...])`.
final aiSearchServiceProvider = Provider<AiSearchService>((ref) {
  final config = ref.watch(geminiConfigProvider);
  // If no key is configured, GeminiAiService still returns a safe error
  // result — it never throws.
  return GeminiAiService(config ?? const GeminiConfig.empty());
});

/// Application layer controller that orchestrates the full AI search flow:
/// 1. Takes the user's question.
/// 2. Queries the local FTS5 index for relevant PDF pages.
/// 3. If no pages match, returns a graceful fallback without hitting the network.
/// 4. Otherwise, calls the AI service (Gemini) with the retrieved context.
/// 5. Manages loading, success, and error states for the UI.
final aiSearchControllerProvider =
    AsyncNotifierProvider<AiSearchController, AiSearchResult?>(
  AiSearchController.new,
);

class AiSearchController extends AsyncNotifier<AiSearchResult?> {
  @override
  Future<AiSearchResult?> build() async {
    // Start with a null state to indicate we are idle / haven't searched yet.
    return null;
  }

  Future<void> search(String question, {List<int>? allowedFileIds}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    // Transition to loading state.
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // 1. Retrieve the local FTS5 context.
      // pdfAiContextDefaultProvider handles the query sanitization, FTS5 search,
      // and inherently limits to 8 pages to avoid blowing up the prompt context.
      var contexts = await ref.read(pdfAiContextDefaultProvider(trimmed).future);

      // Filter by allowed files if a specific subject/context was provided.
      if (allowedFileIds != null) {
        contexts = contexts.where((c) => allowedFileIds.contains(c.fileId)).toList();
      }

      // 2. Early exit if no relevant context was found locally.
      // We don't want to call Gemini if we have no grounding material.
      if (contexts.isEmpty) {
        return const AiSearchResult(
          answer: "I couldn't find relevant information in your notes.",
          sources: [],
        );
      }

      // 3. Build the payload.
      final request = AiSearchRequest(
        question: trimmed,
        contexts: contexts,
      );

      // 4. Ask the AI.
      final service = ref.read(aiSearchServiceProvider);
      return await service.ask(request);
    });
  }
}
