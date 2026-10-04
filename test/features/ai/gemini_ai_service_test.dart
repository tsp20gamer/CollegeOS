import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:college_os/core/ai/gemini_config.dart';
import 'package:college_os/features/ai/domain/ai_context_builder.dart';
import 'package:college_os/features/ai/domain/pdf_ai_context.dart';
import 'package:college_os/features/notes/data/gemini_ai_service.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the service tried to send, and answers from a script.
///
/// No test in this suite ever reaches the network.
class _FakeTransport implements GeminiTransport {
  _FakeTransport(this._responder);

  final Future<GeminiHttpResponse> Function(Uri uri) _responder;

  int callCount = 0;
  String? lastBody;
  Map<String, String>? lastHeaders;
  final List<Uri> uris = [];

  @override
  Future<GeminiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) {
    callCount++;
    uris.add(uri);
    lastBody = body;
    lastHeaders = headers;
    return _responder(uri);
  }
}

/// Wraps model output in a `generateContent` response envelope.
String _envelope(String modelText) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': modelText},
        ],
      },
    },
  ],
});

String _structured({
  required String answer,
  required bool grounded,
  List<Map<String, Object>> sources = const [],
}) => jsonEncode({'answer': answer, 'grounded': grounded, 'sources': sources});

const _page12 = PdfAiContext(
  fileId: 3,
  pageNumber: 12,
  pageText: 'A PN junction diode conducts current in one direction only.',
  fileName: 'Engineering Physics Notes.pdf',
);
const _page13 = PdfAiContext(
  fileId: 3,
  pageNumber: 13,
  pageText: 'Reverse bias widens the depletion region at the junction.',
  fileName: 'Engineering Physics Notes.pdf',
);

const _question = 'What is the working principle of a PN junction diode?';

GeminiAiService _service(
  GeminiTransport transport, {
  GeminiConfig? config,
  List<String> modelChain = const ['gemini-3.1-flash-lite'],
}) {
  return GeminiAiService(
    config ?? GeminiConfig.withKey('test-key'),
    transport: transport,
    modelChain: modelChain,
    timeout: const Duration(seconds: 5),
  );
}

void main() {
  group('prompt construction', () {
    test('labels context blocks and includes the question', () {
      final bundle = const AiContextBuilder().build([_page12, _page13]);
      final prompt = _service(
        _FakeTransport((_) async => throw StateError('unused')),
      ).buildUserPrompt(_question, bundle);

      expect(prompt, contains('--- BEGIN COLLEGEOS NOTE CONTEXT ---'));
      expect(prompt, contains('[Source 1]'));
      expect(prompt, contains('File: Engineering Physics Notes.pdf'));
      expect(prompt, contains('File ID: 3'));
      expect(prompt, contains('Page: 12'));
      expect(prompt, contains('Page: 13'));
      expect(prompt, contains(_question));
      expect(prompt, contains('--- END COLLEGEOS NOTE CONTEXT ---'));
    });

    test(
      'sends the grounding rules, the schema and the key as a header',
      () async {
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(
            200,
            _envelope(
              _structured(
                answer: 'A diode conducts in one direction.',
                grounded: true,
                sources: [
                  {'fileId': 3, 'page': 12},
                ],
              ),
            ),
          ),
        );

        await _service(
          transport,
        ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

        final body = jsonDecode(transport.lastBody!) as Map<String, dynamic>;
        final systemInstruction = jsonEncode(body['systemInstruction']);

        expect(
          systemInstruction,
          contains('Answer using ONLY the supplied CollegeOS note context'),
        );
        expect(systemInstruction, contains('Never use outside knowledge'));
        expect(systemInstruction, contains('Never invent facts'));

        final generationConfig =
            body['generationConfig'] as Map<String, dynamic>;
        expect(generationConfig['responseMimeType'], 'application/json');
        expect(
          generationConfig['responseSchema'],
          GeminiAiService.responseSchema,
        );

        // The credential travels in a header, never in the URL: URIs are what end
        // up in stack traces and HTTP logs.
        expect(transport.lastHeaders![GeminiConfig.apiKeyHeader], 'test-key');
        expect(transport.uris.single.toString(), isNot(contains('test-key')));
        expect(transport.uris.single.path, contains('gemini-3.1-flash-lite'));
      },
    );
  });

  group('successful grounded response', () {
    test('parses a structured answer and keeps valid citations', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'A PN junction diode conducts in one direction.',
              grounded: true,
              sources: [
                {'fileId': 3, 'page': 12},
                {'fileId': 3, 'page': 13},
              ],
            ),
          ),
        ),
      );

      final result = await _service(transport).ask(
        const AiSearchRequest(
          question: _question,
          contexts: [_page12, _page13],
        ),
      );

      expect(result.failure, AiFailure.none);
      expect(result.grounded, isTrue);
      expect(result.answer, contains('one direction'));
      expect(result.sources.map((s) => s.pageKey), ['3:12', '3:13']);
      expect(result.sources.first.fileName, 'Engineering Physics Notes.pdf');
    });

    test('accepts a numeric-string page number from the model', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'Bias matters.',
              grounded: true,
              sources: [
                {'fileId': '3', 'page': '12'},
              ],
            ),
          ),
        ),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.sources.single.pageNumber, 12);
    });

    test(
      'takes the file name from the local index, not from the model',
      () async {
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(
            200,
            _envelope(
              _structured(
                answer: 'Grounded answer.',
                grounded: true,
                sources: [
                  {
                    'fileId': 3,
                    'page': 12,
                    'fileName': 'Totally Invented Notes.pdf',
                  },
                ],
              ),
            ),
          ),
        );

        final result = await _service(
          transport,
        ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

        expect(result.sources.single.fileName, 'Engineering Physics Notes.pdf');
      },
    );

    test('reports an honest not-grounded answer as no context', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: "I couldn't find this topic in your indexed notes.",
              grounded: false,
            ),
          ),
        ),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.grounded, isFalse);
      expect(result.sources, isEmpty);
      expect(result.failure, AiFailure.none);
    });
  });

  group('citation validation', () {
    test('rejects a page number that was never supplied', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'Something with an invented citation.',
              grounded: true,
              sources: [
                {'fileId': 3, 'page': 12},
                {'fileId': 3, 'page': 99}, // never sent to the model
              ],
            ),
          ),
        ),
      );

      final result = await _service(transport).ask(
        const AiSearchRequest(
          question: _question,
          // Only pages 12 and 13 exist locally.
          contexts: [_page12, _page13],
        ),
      );

      expect(
        result.sources.map((s) => s.pageNumber),
        [12],
        reason: 'page 99 must never reach the UI as a source',
      );
    });

    test('rejects a citation for a file that was never supplied', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'Cross-file invention.',
              grounded: true,
              sources: [
                {'fileId': 77, 'page': 12},
              ],
            ),
          ),
        ),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.sources, isEmpty);
    });

    test('keeps a citation expressed as a source index', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'Indexed citation.',
              grounded: true,
              sources: [
                {'source': 2},
              ],
            ),
          ),
        ),
      );

      final result = await _service(transport).ask(
        const AiSearchRequest(
          question: _question,
          contexts: [_page12, _page13],
        ),
      );

      expect(result.sources.single.pageNumber, 13);
    });

    test(
      'recovers citations from a free-text response and still validates them',
      () async {
        // The endpoint ignored the schema and answered in prose. The prose is
        // usable, but the invented page is still rejected.
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(
            200,
            _envelope(
              'A diode conducts in one direction. [Source 1] '
              'Sources: [File:3 Page:12] [File:3 Page:99]',
            ),
          ),
        );

        final result = await _service(
          transport,
        ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

        expect(result.answer, contains('one direction'));
        expect(result.sources.map((s) => s.pageNumber), [12]);
      },
    );

    test('de-duplicates repeated citations', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'Repeated citation.',
              grounded: true,
              sources: [
                {'fileId': 3, 'page': 12},
                {'fileId': 3, 'page': 12},
              ],
            ),
          ),
        ),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.sources, hasLength(1));
    });
  });

  group('no context', () {
    test('never calls the model when retrieval found nothing', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(_structured(answer: 'should not happen', grounded: true)),
        ),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: []));

      expect(
        transport.callCount,
        0,
        reason: 'an empty context invites hallucination',
      );
      expect(result.failure, AiFailure.noContext);
      expect(
        result.answer,
        "I couldn't find this topic in your indexed notes.",
      );
    });

    test('does not call the model when every page is blank', () async {
      final transport = _FakeTransport(
        (_) async => throw StateError('the model must not be called'),
      );

      final result = await _service(transport).ask(
        const AiSearchRequest(
          question: _question,
          contexts: [
            PdfAiContext(fileId: 3, pageNumber: 1, pageText: '   \n  '),
          ],
        ),
      );

      expect(transport.callCount, 0);
      expect(result.failure, AiFailure.noContext);
    });
  });

  group('configuration and transport failures', () {
    test('reports a missing API key without attempting a request', () async {
      final transport = _FakeTransport(
        (_) async => throw StateError('the model must not be called'),
      );

      final result = await _service(
        transport,
        config: const GeminiConfig.empty(),
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(transport.callCount, 0);
      expect(result.failure, AiFailure.notConfigured);
    });

    test('maps a socket failure to an offline failure', () async {
      final transport = _FakeTransport(
        (_) async => throw const SocketException('network is unreachable'),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.failure, AiFailure.offline);
      expect(result.answer, contains('internet connection'));
      expect(result.answer, isNot(contains('SocketException')));
    });

    test('maps a timeout to a timeout failure', () async {
      final transport = _FakeTransport(
        (_) async => throw TimeoutException('too slow'),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.failure, AiFailure.timeout);
      expect(result.answer, isNot(contains('TimeoutException')));
    });

    test('maps 429 to a rate-limit failure', () async {
      final transport = _FakeTransport(
        (_) async =>
            const GeminiHttpResponse(429, '{"error":{"message":"quota"}}'),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.failure, AiFailure.rateLimited);
    });

    test(
      'maps 401 to an unauthorised failure without leaking the key',
      () async {
        final transport = _FakeTransport(
          (_) async => const GeminiHttpResponse(
            401,
            '{"error":{"message":"API key not valid: test-key"}}',
          ),
        );

        final result = await _service(
          transport,
        ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

        expect(result.failure, AiFailure.unauthorized);
        expect(result.answer, isNot(contains('test-key')));
      },
    );

    test('maps 500 to a server failure', () async {
      final transport = _FakeTransport(
        (_) async => const GeminiHttpResponse(500, 'internal error'),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.failure, AiFailure.server);
    });

    test('falls back to the next model on 429 and succeeds', () async {
      final transport = _FakeTransport((uri) async {
        if (uri.path.contains('first-model')) {
          return const GeminiHttpResponse(429, 'rate limited');
        }
        return GeminiHttpResponse(
          200,
          _envelope(
            _structured(
              answer: 'Answered by the fallback model.',
              grounded: true,
              sources: [
                {'fileId': 3, 'page': 12},
              ],
            ),
          ),
        );
      });

      final result = await _service(
        transport,
        modelChain: const ['first-model', 'gemini-3.1-flash-lite'],
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(transport.callCount, 2);
      expect(result.failure, AiFailure.none);
      expect(result.answer, contains('fallback model'));
    });

    test('does not retry another model after a bad request', () async {
      final transport = _FakeTransport(
        (_) async => const GeminiHttpResponse(400, 'bad request'),
      );

      await _service(
        transport,
        modelChain: const ['first-model', 'second-model'],
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(transport.callCount, 1);
    });

    test('maps a malformed envelope to a malformed-response failure', () async {
      final transport = _FakeTransport(
        (_) async => const GeminiHttpResponse(200, 'not json at all'),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.failure, AiFailure.malformedResponse);
    });

    test(
      'maps an empty candidate list to a malformed-response failure',
      () async {
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(200, jsonEncode({'candidates': []})),
        );

        final result = await _service(
          transport,
        ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

        expect(result.failure, AiFailure.malformedResponse);
      },
    );

    test(
      'maps an empty answer field to a malformed-response failure',
      () async {
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(
            200,
            _envelope(_structured(answer: '   ', grounded: true)),
          ),
        );

        final result = await _service(
          transport,
        ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

        expect(result.failure, AiFailure.malformedResponse);
      },
    );

    test('accepts JSON wrapped in a Markdown fence', () async {
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            '```json\n${_structured(answer: 'Fenced answer.', grounded: true)}\n```',
          ),
        ),
      );

      final result = await _service(
        transport,
      ).ask(const AiSearchRequest(question: _question, contexts: [_page12]));

      expect(result.answer, 'Fenced answer.');
    });

    test(
      'returns an empty result for a blank question without calling out',
      () async {
        final transport = _FakeTransport(
          (_) async => throw StateError('the model must not be called'),
        );

        final result = await _service(
          transport,
        ).ask(const AiSearchRequest(question: '   ', contexts: [_page12]));

        expect(transport.callCount, 0);
        expect(result.answer, isEmpty);
      },
    );
  });
}
