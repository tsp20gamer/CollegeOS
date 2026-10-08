import 'dart:convert';

import 'package:college_os/core/ai/gemini_config.dart';
import 'package:college_os/features/ai/application/pdf_ai_context_providers.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:college_os/features/notes/data/gemini_ai_service.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_note_search_state.dart';
import 'package:college_os/features/notes/domain/ai_search_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads the [GeminiConfig] using a two-step fallback:
///
/// 1. **Compile-time** `--dart-define=GEMINI_API_KEY=…` (CI / release builds).
/// 2. **Bundled asset** `env.json` at the project root (local development).
///
/// This makes `flutter run` work out-of-the-box when `env.json` is present,
/// without requiring the developer to remember `--dart-define-from-file`.
final geminiConfigProvider = FutureProvider<GeminiConfig?>((ref) async {
  // 1. Compile-time define takes priority.
  final fromDefine = GeminiConfig.fromEnvironment();
  if (fromDefine != null) return fromDefine;

  // 2. Fallback: load from the bundled env.json asset.
  try {
    final raw = await rootBundle.loadString('env.json');
    final parsed = jsonDecode(raw);
    if (parsed is Map<String, dynamic>) {
      final key = parsed['GEMINI_API_KEY'] as String? ?? '';
      final baseUrl = parsed['GEMINI_API_BASE_URL'] as String? ?? '';
      if (key.isNotEmpty) {
        debugPrint('[GeminiConfig] Loaded API key from bundled env.json.');
        return GeminiConfig.withKey(
          key,
          proxyBaseUrl: baseUrl.isEmpty ? null : baseUrl,
        );
      }
    }
  } catch (e) {
    // Asset missing or malformed — not an error, AI simply stays unconfigured.
    debugPrint('[GeminiConfig] No env.json asset found ($e).');
  }

  return null;
});

/// Provides the active [AiSearchService] implementation.
///
/// Currently wired to [GeminiAiService]. To swap implementations (tests, or a
/// future backend/proxy) override this provider in a
/// `ProviderScope(overrides: [...])` — no UI or retrieval change is needed.
final aiSearchServiceProvider = FutureProvider<AiSearchService>((ref) async {
  final config = await ref.watch(geminiConfigProvider.future);
  // A missing key is not an error here: the service reports it as a
  // not-configured failure without attempting a request.
  return GeminiAiService(config ?? const GeminiConfig.empty());
});

/// Orchestrates the AI note-search flow and exposes it as [AiNoteSearchStatus].
///
/// Flow: local FTS5 retrieval → bounded context → model → validated citations.
/// The model is never consulted before local retrieval succeeds, and never sees
/// the PDF itself — only the retrieved page text.
///
/// **Caching:** identical question + identical retrieved context is answered
/// from a small in-memory map. Nothing is persisted, so no answer text is left
/// on disk.
///
/// **Concurrency:** while a request for the same question + subject scope is in
/// flight, a second identical request returns immediately instead of starting a
/// duplicate (and, once a later question is asked, a stale response is dropped
/// rather than overwriting newer state).
final aiSearchControllerProvider =
    NotifierProvider<AiSearchController, AiNoteSearchStatus>(
      AiSearchController.new,
    );

class AiSearchController extends Notifier<AiNoteSearchStatus> {
  /// Cap on cached answers. Small on purpose: Phase 1 answers independent
  /// questions and keeps no conversation history.
  static const int maxCacheEntries = 16;

  final Map<String, AiSearchResult> _cache = {};
  final Set<String> _inFlight = {};

  /// Incremented per accepted request so an out-of-order response from an
  /// earlier question cannot overwrite the current one.
  int _requestToken = 0;

  @override
  AiNoteSearchStatus build() => AiNoteSearchStatus.initial;

  /// Resets to idle, e.g. when the user clears the search box.
  void reset() {
    _requestToken++;
    state = AiNoteSearchStatus.initial;
  }

  /// Answers [question] from the indexed notes.
  ///
  /// [allowedFileIds] narrows retrieval to the PDFs of the current subject;
  /// `null` searches every indexed PDF.
  Future<void> ask(String question, {List<int>? allowedFileIds}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final requestKey = _fingerprint('$trimmed|${_scopeKey(allowedFileIds)}');
    if (!_inFlight.add(requestKey)) return; // duplicate request already running
    final token = ++_requestToken;

    try {
      state = AiNoteSearchStatus(
        phase: AiNoteSearchPhase.searching,
        question: trimmed,
      );

      final contexts = await _retrieveContext(trimmed, allowedFileIds);
      if (token != _requestToken) return; // superseded by a newer question

      // No usable local context: stop here. Sending an empty context would
      // invite the model to answer from its own knowledge, which is exactly the
      // failure mode this feature must avoid.
      if (contexts.isEmpty) {
        state = AiNoteSearchStatus(
          phase: AiNoteSearchPhase.noContext,
          question: trimmed,
          result: const AiSearchResult.notFound(),
          message: "I couldn't find this topic in your indexed notes.",
          failure: AiFailure.noContext,
        );
        return;
      }

      final cacheKey = _fingerprint('$trimmed|${_contextKey(contexts)}');
      final cached = _cache[cacheKey];
      if (cached != null) {
        state = _statusFor(trimmed, cached, contexts.length);
        return;
      }

      state = AiNoteSearchStatus(
        phase: AiNoteSearchPhase.contextFound,
        question: trimmed,
        sourcePageCount: contexts.length,
      );

      state = AiNoteSearchStatus(
        phase: AiNoteSearchPhase.generating,
        question: trimmed,
        sourcePageCount: contexts.length,
      );

      final service = await ref.read(aiSearchServiceProvider.future);
      final result = await service.ask(
        AiSearchRequest(question: trimmed, contexts: contexts),
      );

      if (token != _requestToken) return; // superseded while waiting

      final status = _statusFor(trimmed, result, contexts.length);
      if (!result.isFailure) _remember(cacheKey, result);
      state = status;
    } finally {
      _inFlight.remove(requestKey);
    }
  }

  /// Retrieves pages, tolerating a retrieval failure as "no context".
  ///
  /// A thrown error here would be a database problem, and the honest response
  /// is that nothing was found — not a crash and not an invented answer.
  Future<List<PdfAiContext>> _retrieveContext(
    String question,
    List<int>? allowedFileIds,
  ) async {
    try {
      final contexts = await ref
          .read(pdfContextRepositoryProvider)
          .retrieveContext(question);
      if (allowedFileIds == null) return contexts;
      return contexts.where((c) => allowedFileIds.contains(c.fileId)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Maps a service result onto the phase the UI renders.
  AiNoteSearchStatus _statusFor(
    String question,
    AiSearchResult result,
    int contextCount,
  ) {
    const notFoundMessage = "I couldn't find this topic in your indexed notes.";

    final (AiNoteSearchPhase phase, String? message) = switch (result.failure) {
      AiFailure.offline => (
        AiNoteSearchPhase.offline,
        result.answer.isNotEmpty
            ? result.answer
            : 'AI search needs an internet connection.',
      ),
      AiFailure.notConfigured ||
      AiFailure.timeout ||
      AiFailure.rateLimited ||
      AiFailure.unauthorized ||
      AiFailure.server ||
      AiFailure.malformedResponse => (
        AiNoteSearchPhase.apiError,
        result.answer.isNotEmpty
            ? result.answer
            : 'AI search is unavailable right now.',
      ),
      AiFailure.noContext => (AiNoteSearchPhase.noContext, notFoundMessage),
      AiFailure.none =>
        // An answer that cites nothing and admits it is not grounded is the
        // "not in your notes" outcome, not a success to celebrate.
        (!result.grounded && !result.hasSources)
            ? (AiNoteSearchPhase.noContext, notFoundMessage)
            : (AiNoteSearchPhase.success, null),
    };

    return AiNoteSearchStatus(
      phase: phase,
      question: question,
      result: result,
      message: message,
      sourcePageCount: contextCount,
      failure: result.failure,
    );
  }

  void _remember(String cacheKey, AiSearchResult result) {
    if (_cache.length >= maxCacheEntries) {
      // Dart maps preserve insertion order, so the first key is the oldest.
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = result;
  }

  /// Identity of the retrieved page set, used so a changed index (a newly
  /// indexed PDF, a re-indexed file) cannot be served from a stale cache entry.
  String _contextKey(List<PdfAiContext> contexts) {
    final signature = contexts
        .map((c) => '${c.fileId}:${c.pageNumber}:${c.pageText.length}')
        .join(',');
    return _fingerprint(signature);
  }

  String _scopeKey(List<int>? allowedFileIds) {
    if (allowedFileIds == null) return 'all';
    final sorted = [...allowedFileIds]..sort();
    return sorted.join(',');
  }

  /// Short SHA-256 of [value]. Used only for in-memory map keys — never for the
  /// API key, which no provider in this file reads.
  String _fingerprint(String value) =>
      sha256.convert(utf8.encode(value)).toString().substring(0, 16);
}
