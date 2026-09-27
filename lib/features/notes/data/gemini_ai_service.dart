import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:college_os/core/ai/gemini_config.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_search_service.dart';
import 'package:flutter/foundation.dart';

/// Gemini REST API implementation of [AiSearchService].
///
/// Sends the user's question plus locally retrieved PDF page text to Gemini
/// and returns a structured [AiSearchResult].
///
/// **Key behaviours:**
/// - Only the text from the supplied [PdfAiContext] pages is sent — no raw
///   PDFs, no unrelated files, no full document uploads.
/// - The prompt strictly instructs Gemini to use only the supplied context.
/// - All error paths (network, timeout, rate-limit, malformed JSON) return a
///   safe [AiSearchResult] without throwing.
/// - The API key is never written to logs.
final class GeminiAiService implements AiSearchService {
  GeminiAiService(this._config);

  final GeminiConfig _config;

  // ─── Public API ────────────────────────────────────────────────────────────

  @override
  Future<AiSearchResult> ask(AiSearchRequest request) async {
    if (!_config.isValid) {
      debugPrint('[GeminiAiService] No API key configured — skipping request.');
      return const AiSearchResult(
        answer: 'AI search is not configured. Please supply a Gemini API key.',
        sources: [],
      );
    }

    final trimmedQuestion = request.question.trim();
    if (trimmedQuestion.isEmpty) return const AiSearchResult.empty();

    // Limit 1: Limit the maximum number of retrieved pages.
    // The incoming contexts are assumed to be sorted by FTS5 rank (highest relevance first).
    // Limit 4: Prefer the highest-ranked FTS results.
    final rankedContexts = request.contexts.take(GeminiConfig.maxContextPages).toList();

    final safeContexts = <PdfAiContext>[];
    int currentTotalChars = 0;

    for (final ctx in rankedContexts) {
      // Limit 2 & 7: Limit max characters per page and truncate safely.
      String safeText = ctx.pageText;
      if (safeText.length > GeminiConfig.maxCharsPerPage) {
        safeText = '${safeText.substring(0, GeminiConfig.maxCharsPerPage)}... [Truncated]';
      }

      // Limit 3: Limit the total context size.
      // If adding this page exceeds the total budget, we discard this and all subsequent
      // lower-ranked pages.
      if (currentTotalChars + safeText.length > GeminiConfig.maxTotalContextChars) {
        debugPrint('[GeminiAiService] Context limit reached. Discarding lower-ranked pages.');
        break;
      }

      // Limit 5 & 6: Preserve page numbers and file IDs.
      safeContexts.add(
        PdfAiContext(
          fileId: ctx.fileId,
          pageNumber: ctx.pageNumber,
          pageText: safeText,
        ),
      );

      currentTotalChars += safeText.length;
    }

    if (safeContexts.isEmpty) {
      return const AiSearchResult(
        answer:
            'No relevant pages were found in your notes for this question.',
        sources: [],
      );
    }

    final prompt = _buildPrompt(trimmedQuestion, safeContexts);

    try {
      final responseBody = await _postToGemini(prompt);
      return _parseResponse(responseBody, safeContexts);
    } on TimeoutException {
      debugPrint('[GeminiAiService] Request timed out.');
      return const AiSearchResult(
        answer: 'AI request timed out. Please try again.',
        sources: [],
      );
    } on SocketException {
      debugPrint('[GeminiAiService] Network error — no internet connection.');
      return const AiSearchResult(
        answer: 'Unable to reach AI service. Please check your connection.',
        sources: [],
      );
    } on HttpException catch (e) {
      debugPrint('[GeminiAiService] HTTP error: ${e.message}');
      return AiSearchResult(
        answer: 'AI service returned an error. Please try again.',
        sources: const [],
      );
    } on _GeminiApiException catch (e) {
      // Rate-limit and other API-level errors.
      debugPrint('[GeminiAiService] API error: ${e.status} ${e.message}');
      if (e.status == 429) {
        return const AiSearchResult(
          answer: 'Too many requests. Please wait a moment and try again.',
          sources: [],
        );
      }
      return AiSearchResult(
        answer: 'AI service error (${e.status}). Please try again later.',
        sources: const [],
      );
    } catch (e) {
      debugPrint('[GeminiAiService] Unexpected error: $e');
      return const AiSearchResult(
        answer: 'Something went wrong. Please try again.',
        sources: [],
      );
    }
  }

  // ─── Prompt construction ───────────────────────────────────────────────────

  /// Builds the strict grounded prompt sent to Gemini.
  ///
  /// Each page is tagged with `[File:<fileId> Page:<pageNumber>]` so the
  /// model can cite sources in its response.
  String _buildPrompt(String question, List<PdfAiContext> contexts) {
    final buffer = StringBuffer();

    buffer.writeln('You are CollegeOS Notes Assistant.');
    buffer.writeln('Rules:');
    buffer.writeln('1. Use the supplied note context as the primary and authoritative source.');
    buffer.writeln('2. Do not invent facts that are not supported by the context.');
    buffer.writeln('3. If the answer cannot be found in the supplied context, clearly say: "I couldn\'t find this information in your notes."');
    buffer.writeln('4. You may organize information for easier understanding.');
    buffer.writeln('5. Keep answers suitable for a first-year B.Tech student.');
    buffer.writeln('6. For "explain" questions, use simple language.');
    buffer.writeln('7. For "short answer" questions, give a concise answer.');
    buffer.writeln('8. For "exam answer" questions, structure the answer clearly with headings/bullets where appropriate.');
    buffer.writeln('9. For "summarize" questions, summarize only the supplied notes.');
    buffer.writeln('10. Always provide source page references when possible.');
    buffer.writeln('11. Never claim to have read a PDF page that was not supplied in the context.');
    buffer.writeln();
    buffer.writeln('Format requirement: After the answer, list the source page references you used on a new line starting exactly with "Sources:", like this:');
    buffer.writeln('Sources: [File:<fileId> Page:<pageNumber>]');
    buffer.writeln();
    buffer.writeln('--- NOTE EXCERPTS ---');

    for (final ctx in contexts) {
      buffer.writeln('[File:${ctx.fileId} Page:${ctx.pageNumber}]');
      buffer.writeln(ctx.pageText);
      buffer.writeln();
    }

    buffer.writeln('--- END OF NOTES ---');
    buffer.writeln();
    buffer.writeln('Student question: $question');

    return buffer.toString();
  }

  // ─── Network ───────────────────────────────────────────────────────────────

  /// Sends [prompt] to Gemini, automatically falling back through
  /// [GeminiConfig.modelChain] when a model returns a rate-limit (429) or
  /// quota-exceeded (503) error.
  ///
  /// Throws [_GeminiApiException] only when ALL models in the chain are
  /// exhausted.  Throws [TimeoutException] / [SocketException] on
  /// network-level failures.
  Future<String> _postToGemini(String prompt) async {
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,      // low temp → more factual, less creative
        'maxOutputTokens': 1024,
        'topP': 0.8,
        'topK': 40,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HARASSMENT',        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH',       'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    });

    _GeminiApiException? lastError;

    for (final model in GeminiConfig.modelChain) {
      final uri = _config.generateContentUriForModel(model);
      debugPrint('[GeminiAiService] Trying model: $model');

      final client = HttpClient();
      client.connectionTimeout = GeminiConfig.timeout;

      try {
        final httpRequest = await client
            .postUrl(uri)
            .timeout(GeminiConfig.timeout);

        httpRequest.headers.set('Content-Type', 'application/json; charset=utf-8');
        httpRequest.write(requestBody);

        final response = await httpRequest.close().timeout(GeminiConfig.timeout);
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success — return immediately without trying the next model.
          debugPrint('[GeminiAiService] Success with model: $model');
          return body;
        }

        final apiError = _GeminiApiException(
          status: response.statusCode,
          message: _safeExtractError(body),
          model: model,
        );

        // 429 = rate limit, 503 = quota exhausted / overloaded — fall through
        // to next model.  For other errors (400 bad request, 401 unauthorised,
        // etc.) there is no point retrying a different model.
        if (response.statusCode == 429 || response.statusCode == 503) {
          debugPrint('[GeminiAiService] Model $model hit rate/quota limit '
              '(${response.statusCode}), trying next...');
          lastError = apiError;
          continue;
        }

        // Non-retryable error — throw immediately.
        throw apiError;
      } finally {
        client.close();
      }
    }

    // All models in the chain were exhausted.
    throw lastError ?? _GeminiApiException(
      status: 429,
      message: 'All models in the fallback chain are rate-limited.',
      model: GeminiConfig.modelChain.last,
    );
  }

  // ─── Response parsing ──────────────────────────────────────────────────────

  /// Parses the Gemini JSON response and extracts the answer + source refs.
  ///
  /// If the response is malformed or empty, returns a safe fallback result.
  AiSearchResult _parseResponse(
    String body,
    List<PdfAiContext> contexts,
  ) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Gemini response shape:
      // { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return const AiSearchResult(
          answer: 'No answer was returned by the AI.',
          sources: [],
        );
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final rawText = (parts?.first['text'] as String? ?? '').trim();

      if (rawText.isEmpty) {
        return const AiSearchResult(
          answer: 'The AI returned an empty response.',
          sources: [],
        );
      }

      // Extract source references the model cited (format: [File:X Page:Y]).
      final sources = _extractSources(rawText, contexts);

      // Strip the trailing "Sources: …" line from the answer text so the UI
      // can display answer and sources independently.
      final answer = _stripSourcesLine(rawText);

      return AiSearchResult(answer: answer, sources: sources);
    } catch (e) {
      debugPrint('[GeminiAiService] Failed to parse response: $e');
      return const AiSearchResult(
        answer: 'Could not read the AI response. Please try again.',
        sources: [],
      );
    }
  }

  /// Parses `[File:<fileId> Page:<pageNumber>]` tags from the model output
  /// and maps them back to [AiSourceReference]s, including an optional excerpt
  /// from the original context.
  List<AiSourceReference> _extractSources(
    String text,
    List<PdfAiContext> contexts,
  ) {
    // Match all [File:N Page:M] occurrences in the response.
    final pattern = RegExp(r'\[File:(\d+)\s+Page:(\d+)\]');
    final matches = pattern.allMatches(text);

    final seen = <String>{};
    final refs = <AiSourceReference>[];

    for (final m in matches) {
      final fileId = int.tryParse(m.group(1) ?? '');
      final pageNumber = int.tryParse(m.group(2) ?? '');
      if (fileId == null || pageNumber == null) continue;

      final key = '$fileId:$pageNumber';
      if (seen.contains(key)) continue;
      seen.add(key);

      refs.add(AiSourceReference(
        fileId: fileId,
        pageNumber: pageNumber,
        excerpt: null,
      ));
    }

    return refs;
  }

  /// Removes the "Sources: …" trailing line that Gemini was asked to append,
  /// so the UI can display the clean answer text only.
  String _stripSourcesLine(String text) {
    final lines = text.split('\n');
    final filtered = lines
        .where((l) => !l.trimLeft().startsWith('Sources:'))
        .toList();
    return filtered.join('\n').trim();
  }

  /// Safely extracts an error message from a Gemini error response body
  /// without logging the full body (which may contain metadata).
  String _safeExtractError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? 'Unknown API error';
    } catch (_) {
      return 'Unknown API error';
    }
  }
}

// ─── Internal exceptions ────────────────────────────────────────────────────

/// Thrown when Gemini returns a non-2xx HTTP status code.
final class _GeminiApiException implements Exception {
  const _GeminiApiException({
    required this.status,
    required this.message,
    required this.model,
  });
  final int status;
  final String message;
  final String model;
}
