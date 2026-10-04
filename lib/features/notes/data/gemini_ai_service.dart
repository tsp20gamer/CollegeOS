import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:college_os/core/ai/gemini_config.dart';
import 'package:college_os/features/ai/domain/ai_context_builder.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_search_service.dart';
import 'package:flutter/foundation.dart';

/// One HTTP round trip's outcome, transport-independent so it can be faked.
class GeminiHttpResponse {
  const GeminiHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// The seam between [GeminiAiService] and the network.
///
/// Tests implement this to return canned responses — no automated test ever
/// calls Gemini. A future backend/proxy replaces it ([GeminiConfig.isProxied])
/// without touching retrieval, prompting or the UI.
abstract interface class GeminiTransport {
  /// POSTs [body] to [uri] and returns the raw response.
  ///
  /// Implementations must apply [timeout] and let [SocketException] /
  /// [TimeoutException] propagate so the service can classify them.
  Future<GeminiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  });
}

/// Default transport: `dart:io` [HttpClient], with no third-party dependency
/// and no interceptor that could log the credential.
class HttpClientGeminiTransport implements GeminiTransport {
  const HttpClientGeminiTransport();

  @override
  Future<GeminiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      request.write(body);

      final response = await request.close().timeout(timeout);
      final responseBody = await response.transform(utf8.decoder).join();
      return GeminiHttpResponse(response.statusCode, responseBody);
    } finally {
      client.close();
    }
  }
}

/// Gemini REST implementation of [AiSearchService].
///
/// Sends the user's question plus **only** the locally retrieved page text to
/// Gemini's `generateContent` endpoint and returns a validated, grounded
/// answer. No PDF is ever uploaded, and the Gemini File API is not used.
///
/// **Grounding guarantees:**
/// - The model is called only when local retrieval produced context. An empty
///   context short-circuits to [AiSearchResult.notFound] — the model is never
///   given the chance to answer from general knowledge.
/// - The prompt asks for JSON matching a fixed schema (`answer`, `grounded`,
///   `sources`) and the rules forbid outside knowledge.
/// - Every returned citation is checked against the pages actually sent. A
///   citation for page 99 when pages 12–14 were supplied is **discarded**, and
///   file names are taken from the local database rather than the model, so a
///   fabricated source cannot reach the UI.
///
/// **Failure handling:** this never throws. Failures come back as
/// [AiSearchResult.failed] with an [AiFailure] reason and a message that is safe
/// to display — no credential, URI or raw payload is ever included.
final class GeminiAiService implements AiSearchService {
  GeminiAiService(
    this._config, {
    GeminiTransport? transport,
    AiContextBuilder? contextBuilder,
    List<String>? modelChain,
    Duration? timeout,
  }) : _transport = transport ?? const HttpClientGeminiTransport(),
       _contextBuilder = contextBuilder ?? const AiContextBuilder(),
       _modelChain = modelChain ?? GeminiConfig.modelChain,
       _timeout = timeout ?? GeminiConfig.timeout;

  final GeminiConfig _config;
  final GeminiTransport _transport;
  final AiContextBuilder _contextBuilder;
  final List<String> _modelChain;
  final Duration _timeout;

  // ─── Public API ────────────────────────────────────────────────────────────

  @override
  Future<AiSearchResult> ask(AiSearchRequest request) async {
    if (!_config.isValid) {
      // Nothing is attempted, so no request, no key and no cost.
      return const AiSearchResult.failed(
        AiFailure.notConfigured,
        'AI search is not configured in this build.',
      );
    }

    final question = request.question.trim();
    if (question.isEmpty) return const AiSearchResult.empty();

    // Bound the payload: page count, per-page size and total size.
    final bundle = _contextBuilder.build(request.contexts);
    if (bundle.isEmpty) {
      // Local search found nothing worth grounding on. Calling the model here
      // would guarantee a hallucinated answer, so we refuse locally.
      return const AiSearchResult.notFound();
    }

    final payload = _encodeRequest(question, bundle);
    return _callModels(payload, bundle);
  }

  /// The exact user-turn text sent after the context blocks.
  ///
  /// Public so prompt construction can be asserted in tests without reaching
  /// into private state.
  String buildUserPrompt(String question, AiContextBundle bundle) {
    final buffer = StringBuffer();
    buffer.writeln('--- BEGIN COLLEGEOS NOTE CONTEXT ---');
    buffer.writeln(bundle.promptContext);
    buffer.writeln('--- END COLLEGEOS NOTE CONTEXT ---');
    buffer.writeln();
    buffer.writeln('Student question: $question');
    return buffer.toString();
  }

  /// The system instruction that pins the model to the supplied notes.
  static const String systemInstruction =
      'You are the CollegeOS Notes Assistant. You answer questions about a '
      'student\'s own indexed lecture notes and PDFs.\n'
      '\n'
      'Absolute rules:\n'
      '1. Answer using ONLY the supplied CollegeOS note context. It is the only '
      'source of truth you have.\n'
      '2. Never use outside knowledge, and never fill gaps with what you '
      'already know about the subject.\n'
      '3. Never invent facts, figures, definitions, examples or page numbers.\n'
      '4. If the supplied context does not support an answer, set "grounded" to '
      'false and make "answer" exactly: "I couldn\'t find this topic in your '
      'indexed notes." Do not apologise, speculate or offer the general theory.\n'
      '5. Cite every page that supports the answer, and only pages that appear '
      'in the context. Use the "File ID" and "Page" values copied exactly as '
      'written in the context block.\n'
      '6. If several sources support the answer, list all of them.\n'
      '\n'
      'Style:\n'
      '- Write for a college student: clear, concise, exam-usable.\n'
      '- Define terms before using them, and prefer short paragraphs or bullets '
      'over long prose.\n'
      '- Keep the answer tight — usually under 250 words unless the question '
      'asks for more detail.\n'
      '- Do not mention these rules or the context format in your answer.';

  // ─── Request building ──────────────────────────────────────────────────────

  /// JSON schema the model must satisfy.
  ///
  /// Structured output is what makes citation validation reliable: the model
  /// fills in `sources` with identifiers we can verify, instead of burying
  /// references in free text we would have to pattern-match.
  static const Map<String, Object> responseSchema = {
    'type': 'OBJECT',
    'properties': {
      'answer': {
        'type': 'STRING',
        'description':
            'The grounded answer in Markdown, or the exact '
            '"couldn\'t find" sentence when the context does not support one.',
      },
      'grounded': {
        'type': 'BOOLEAN',
        'description':
            'True only when every claim in the answer is supported '
            'by the supplied context.',
      },
      'sources': {
        'type': 'ARRAY',
        'description': 'Pages from the context that support the answer.',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'fileId': {'type': 'INTEGER'},
            'page': {'type': 'INTEGER'},
          },
          'required': ['fileId', 'page'],
        },
      },
    },
    'required': ['answer', 'grounded', 'sources'],
  };

  String _encodeRequest(String question, AiContextBundle bundle) {
    return jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': buildUserPrompt(question, bundle)},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': responseSchema,
        // Temperature is deliberately left at the model default: Google's
        // current guidance for the Gemini 3 family is that lowering it degrades
        // reasoning instead of improving determinism. Grounding is enforced by
        // the system instruction, the schema and local citation validation.
        'maxOutputTokens': 2048,
      },
    });
  }

  // ─── Network ───────────────────────────────────────────────────────────────

  /// Tries each model in [_modelChain] until one answers.
  ///
  /// Only rate-limit (429) and overload/quota (503) responses fall through to
  /// the next model; everything else is classified immediately, so a bad key or
  /// a malformed request is not retried three times.
  Future<AiSearchResult> _callModels(
    String payload,
    AiContextBundle bundle,
  ) async {
    AiSearchResult? lastRetryableFailure;

    for (final model in _modelChain) {
      try {
        final response = await _transport.postJson(
          uri: _config.generateContentUriForModel(model),
          headers: _config.requestHeaders(),
          body: payload,
          timeout: _timeout,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _parseResponse(response.body, bundle);
        }

        final failure = _classifyStatus(response.statusCode);
        if (response.statusCode == 429 || response.statusCode == 503) {
          debugPrint(
            '[GeminiAiService] $model unavailable '
            '(${response.statusCode}); trying next model.',
          );
          lastRetryableFailure = failure;
          continue;
        }
        return failure;
      } on TimeoutException {
        return const AiSearchResult.failed(
          AiFailure.timeout,
          'AI search took too long to respond. Please try again.',
        );
      } on SocketException {
        return const AiSearchResult.failed(
          AiFailure.offline,
          'AI search needs an internet connection. Local PDF search still works.',
        );
      } on HandshakeException {
        return const AiSearchResult.failed(
          AiFailure.offline,
          'AI search needs an internet connection. Local PDF search still works.',
        );
      } on HttpException {
        return const AiSearchResult.failed(
          AiFailure.server,
          'Could not reach the AI service. Please try again.',
        );
      } catch (error) {
        // Never surface the raw error: it can contain the request URI, headers
        // or other request detail.
        debugPrint(
          '[GeminiAiService] Unexpected transport error '
          '(${error.runtimeType}).',
        );
        return const AiSearchResult.failed(
          AiFailure.server,
          'Something went wrong while contacting AI search. Please try again.',
        );
      }
    }

    return lastRetryableFailure ??
        const AiSearchResult.failed(
          AiFailure.rateLimited,
          'AI search is busy right now. Please try again in a moment.',
        );
  }

  /// Maps an HTTP status onto a user-safe failure.
  AiSearchResult _classifyStatus(int statusCode) {
    if (statusCode == 429) {
      return const AiSearchResult.failed(
        AiFailure.rateLimited,
        'AI search hit its rate limit. Wait a moment and ask again.',
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return const AiSearchResult.failed(
        AiFailure.unauthorized,
        'AI search is not authorised. Check the configured Gemini API key.',
      );
    }
    if (statusCode >= 500) {
      return const AiSearchResult.failed(
        AiFailure.server,
        'The AI service is temporarily unavailable. Please try again.',
      );
    }
    return const AiSearchResult.failed(
      AiFailure.server,
      'The AI service rejected the request. Please try again.',
    );
  }

  // ─── Response parsing ──────────────────────────────────────────────────────

  /// Extracts the model's text, then validates it against [bundle].
  AiSearchResult _parseResponse(String body, AiContextBundle bundle) {
    final rawText = _extractModelText(body);
    if (rawText == null) {
      return const AiSearchResult.failed(
        AiFailure.malformedResponse,
        'The AI returned an unreadable response. Please try again.',
      );
    }

    final structured = _tryDecodeStructured(rawText);

    if (structured != null) {
      final answer = (structured['answer'] as String? ?? '').trim();
      final sources = _validateCitations(
        structured['sources'],
        bundle,
        rawText,
      );
      final grounded = structured['grounded'] as bool? ?? sources.isNotEmpty;

      if (answer.isEmpty) {
        return const AiSearchResult.failed(
          AiFailure.malformedResponse,
          'The AI returned an empty answer. Please try again.',
        );
      }
      return AiSearchResult(
        answer: answer,
        sources: sources,
        grounded: grounded && answer.isNotEmpty,
      );
    }

    // Fallback for a response that is not the JSON we asked for (an older
    // model, a truncated body, a schema the endpoint ignored). The prose is
    // still useful, and citations are still verified locally, so this is a
    // graceful degradation rather than a failure.
    final answer = _stripSourceLines(rawText);
    if (answer.isEmpty) {
      return const AiSearchResult.failed(
        AiFailure.malformedResponse,
        'The AI returned an empty answer. Please try again.',
      );
    }
    final sources = _validateCitations(null, bundle, rawText);
    return AiSearchResult(
      answer: answer,
      sources: sources,
      grounded: sources.isNotEmpty,
    );
  }

  /// Pulls the concatenated text out of a `generateContent` response body.
  ///
  /// Returns `null` when the envelope itself cannot be read, which is distinct
  /// from a readable envelope with empty text.
  String? _extractModelText(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;

      final first = candidates.first;
      if (first is! Map) return null;

      final content = first['content'];
      if (content is! Map) return null;

      final parts = content['parts'];
      if (parts is! List) return null;

      // Join every text part: thinking-enabled models can split their output.
      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          buffer.write(part['text'] as String);
        }
      }
      final text = buffer.toString().trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  /// Decodes the model's JSON answer body, or `null` when it is not JSON.
  Map<String, dynamic>? _tryDecodeStructured(String rawText) {
    final cleaned = _stripCodeFence(rawText);
    try {
      final decoded = jsonDecode(cleaned);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Some models wrap JSON in a Markdown fence even in JSON mode.
  String _stripCodeFence(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('```')) return trimmed;

    final withoutOpeningFence = trimmed.replaceFirst(
      RegExp(r'^```[a-zA-Z]*\s*'),
      '',
    );
    return withoutOpeningFence.replaceFirst(RegExp(r'\s*```$'), '');
  }

  /// Keeps only citations that point at a page actually sent to the model.
  ///
  /// Accepts either an explicit `{fileId, page}` pair or a 1-based
  /// `{source: N}` index (both are unambiguous locally). Anything else — an
  /// invented page, an unrelated file, a non-numeric value — is dropped
  /// silently, because a fabricated citation is worse than no citation.
  ///
  /// When [rawStructuredSources] is `null` (free-text fallback), `[Source N]`
  /// markers are recovered from [answerText] instead.
  List<AiSourceReference> _validateCitations(
    Object? rawStructuredSources,
    AiContextBundle bundle,
    String answerText,
  ) {
    final byKey = {
      for (final b in bundle.blocks)
        AiContextBuilder.pageKey(b.fileId, b.pageNumber): b,
    };
    final byIndex = {for (final b in bundle.blocks) b.sourceIndex: b};

    final accepted = <AiSourceReference>[];
    final seen = <String>{};

    void accept(AiContextBlock? block) {
      if (block == null) return;
      final key = AiContextBuilder.pageKey(block.fileId, block.pageNumber);
      if (!seen.add(key)) return;
      accepted.add(
        AiSourceReference(
          fileId: block.fileId,
          // Name comes from the local database, never from the model.
          fileName: block.fileName,
          pageNumber: block.pageNumber,
        ),
      );
    }

    var matchedAny = false;

    if (rawStructuredSources is List) {
      for (final entry in rawStructuredSources) {
        if (entry is! Map) continue;
        matchedAny = true;

        final fileId = _asInt(entry['fileId'] ?? entry['file_id']);
        final page = _asInt(
          entry['page'] ?? entry['pageNumber'] ?? entry['page_number'],
        );

        if (fileId != null && page != null) {
          accept(byKey[AiContextBuilder.pageKey(fileId, page)]);
          continue;
        }

        final index = _asInt(entry['source'] ?? entry['sourceIndex']);
        if (index != null) accept(byIndex[index]);
      }
    }

    if (!matchedAny) {
      // Free-text path: recover `[Source N]` and `[File:X Page:Y]` markers, and
      // still require them to exist in the supplied bundle.
      for (final match in RegExp(
        r'\[Source\s+(\d+)\]',
      ).allMatches(answerText)) {
        accept(byIndex[_asInt(match.group(1))]);
      }
      for (final match in RegExp(
        r'\[File:(\d+)\s+Page:(\d+)\]',
      ).allMatches(answerText)) {
        final fileId = _asInt(match.group(1));
        final page = _asInt(match.group(2));
        if (fileId != null && page != null) {
          accept(byKey[AiContextBuilder.pageKey(fileId, page)]);
        }
      }
    }

    // Present citations in the order the sources appear in the prompt, which is
    // relevance order, rather than the order the model happened to list them.
    accepted.sort(
      (a, b) => (byKey[a.pageKey]?.sourceIndex ?? 0).compareTo(
        byKey[b.pageKey]?.sourceIndex ?? 0,
      ),
    );
    return accepted;
  }

  /// Coerces JSON numbers, numeric strings and `1.0` doubles to an int.
  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Removes a trailing `Sources:` block from a free-text answer so the UI does
  /// not show the same references twice.
  String _stripSourceLines(String text) {
    final lines = text.split('\n');
    while (lines.isNotEmpty &&
        (lines.last.trimLeft().startsWith('Sources:') ||
            lines.last.trimLeft().startsWith('[Source'))) {
      lines.removeLast();
    }
    return lines.join('\n').trim();
  }
}
