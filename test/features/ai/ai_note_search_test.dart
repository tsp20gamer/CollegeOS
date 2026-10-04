import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:college_os/core/ai/gemini_config.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/daos/pdf_search_dao.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/notes/application/ai_search_providers.dart';
import 'package:college_os/features/notes/data/gemini_ai_service.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_note_search_state.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers from a script and remembers what it was asked.
///
/// Every test in this file runs against this fake; none of them can reach
/// Gemini, so they are safe to run offline and on CI.
class _FakeTransport implements GeminiTransport {
  _FakeTransport(this._responder);

  final Future<GeminiHttpResponse> Function(Uri uri) _responder;

  int callCount = 0;
  String? lastBody;

  @override
  Future<GeminiHttpResponse> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
    required Duration timeout,
  }) {
    callCount++;
    lastBody = body;
    return _responder(uri);
  }
}

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

String _answer({
  required String answer,
  required bool grounded,
  List<Map<String, Object>> sources = const [],
}) => jsonEncode({'answer': answer, 'grounded': grounded, 'sources': sources});

/// Page 12 exists in the index and contains the physics; the wording of the
/// question deliberately does not appear on the page.
const _page12Text =
    'A PN junction diode conducts current in one direction only. '
    'Forward bias narrows the depletion region; reverse bias widens it.';
const _page13Text =
    'The depletion region forms where p-type and n-type semiconductors meet, '
    'creating a potential barrier across the junction.';
const _unrelatedText =
    'Attendance policy for the semester and the list of laboratory sessions.';

const _question = 'What is the working principle of a PN junction diode?';

Future<({int fileId, int otherFileId, int subjectId})> _seedIndex(
  AppDatabase database,
) async {
  final semesterId = await database.semestersDao.insertSemester(
    SemestersCompanion.insert(
      name: 'Semester 1',
      semesterNumber: 1,
      academicYear: '2026-2027',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 12, 20),
      isActive: const Value(true),
    ),
  );
  final subjectId = await database.subjectsDao.insertSubject(
    SubjectsCompanion.insert(
      semesterId: semesterId,
      name: 'Engineering Physics',
      displayColor: 0xFF6750A4,
    ),
  );

  Future<int> addFile(
    String title,
    List<({int page, String text})> pages,
  ) async {
    final fileId = await database.subjectFilesDao.insertFile(
      SubjectFilesCompanion.insert(
        subjectId: subjectId,
        semesterId: semesterId,
        title: Value(title),
        fileName: '$title.pdf',
        fileExtension: 'pdf',
        fileSizeBytes: 1024,
        relativeFilePath: 'engineering_physics/$title.pdf',
      ),
    );
    await database.pdfSearchDao.saveExtractedBatch(
      fileId,
      [
        for (final p in pages)
          PdfExtractedPage(pageNumber: p.page, text: p.text),
      ],
      lastPageIndexed: pages.last.page,
      totalPages: pages.last.page,
    );
    return fileId;
  }

  final fileId = await addFile('Engineering Physics Notes', [
    (page: 12, text: _page12Text),
    (page: 13, text: _page13Text),
  ]);
  final otherFileId = await addFile('Attendance Rules', [
    (page: 4, text: _unrelatedText),
  ]);

  return (fileId: fileId, otherFileId: otherFileId, subjectId: subjectId);
}

void main() {
  group('local FTS5 retrieval for AI context', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('a natural-language question finds the relevant page', () async {
      final seeded = await _seedIndex(database);

      final rows = await database.pdfSearchDao.searchAiContextByExpression(
        'working* OR principle* OR pn* OR junction* OR diode*',
      );

      expect(rows, isNotEmpty);
      expect(
        rows.any((r) => r.fileId == seeded.fileId && r.pageNumber == 12),
        isTrue,
      );
    });

    test(
      'a keyword AND query would have found nothing for the same question',
      () async {
        await _seedIndex(database);

        // This is the existing keyword path: every word of the sentence must
        // appear on the page, which no real page satisfies.
        final keywordResult = await database.pdfSearchDao.searchForAiContext(
          _question,
        );

        expect(
          keywordResult,
          isEmpty,
          reason: 'the reason AI retrieval needs its own OR expression',
        );
      },
    );

    test('returns bounded results and never writes to the index', () async {
      await _seedIndex(database);
      final before = await database.pdfSearchDao.getAllMetadata();

      final rows = await database.pdfSearchDao.searchAiContextByExpression(
        'semester* OR policy* OR diode*',
        limit: 2,
      );

      expect(rows.length, lessThanOrEqualTo(2));
      expect(
        await database.pdfSearchDao.getAllMetadata(),
        hasLength(before.length),
      );
    });

    test('a malformed expression fails closed instead of throwing', () async {
      await _seedIndex(database);

      final rows = await database.pdfSearchDao.searchAiContextByExpression(
        '"unterminated OR AND (',
      );

      expect(rows, isEmpty);
    });
  });

  group('AI note search controller', () {
    late AppDatabase database;
    late ProviderContainer container;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      container.dispose();
      await database.close();
    });

    ProviderContainer buildContainer({
      required GeminiTransport transport,
      GeminiConfig? config,
    }) {
      final effectiveConfig = config ?? GeminiConfig.withKey('test-key');
      return ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          geminiConfigProvider.overrideWith((_) async => effectiveConfig),
          aiSearchServiceProvider.overrideWith(
            (_) async => GeminiAiService(
              effectiveConfig,
              transport: transport,
              modelChain: const ['gemini-3.1-flash-lite'],
              timeout: const Duration(seconds: 5),
            ),
          ),
        ],
      );
    }

    test(
      'retrieves locally, then answers with validated page sources',
      () async {
        final seeded = await _seedIndex(database);
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(
            200,
            _envelope(
              _answer(
                answer: 'Current flows in one direction across the junction.',
                grounded: true,
                sources: [
                  {'fileId': seeded.fileId, 'page': 12},
                ],
              ),
            ),
          ),
        );
        container = buildContainer(transport: transport);

        await container
            .read(aiSearchControllerProvider.notifier)
            .ask(_question);

        final status = container.read(aiSearchControllerProvider);
        expect(status.phase, AiNoteSearchPhase.success);
        expect(status.result!.answer, contains('one direction'));
        expect(status.result!.grounded, isTrue);
        expect(status.result!.sources.single.pageNumber, 12);
        expect(
          status.result!.sources.single.fileName,
          'Engineering Physics Notes',
          reason: 'the citation is labelled with the local file name',
        );

        // Only retrieved note text is sent: the prompt carries the page, and the
        // page's own wording is what the model saw.
        expect(transport.callCount, 1);
        expect(transport.lastBody, contains('depletion region'));
        expect(
          transport.lastBody,
          isNot(contains('Attendance Rules')),
          reason: 'pages that did not match the question are never uploaded',
        );
      },
    );

    test('drops a citation for a page that was not retrieved', () async {
      final seeded = await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _answer(
              answer: 'Answer with an invented reference.',
              grounded: true,
              sources: [
                {'fileId': seeded.fileId, 'page': 12},
                {'fileId': seeded.fileId, 'page': 4200},
              ],
            ),
          ),
        ),
      );
      container = buildContainer(transport: transport);

      await container.read(aiSearchControllerProvider.notifier).ask(_question);

      final sources = container
          .read(aiSearchControllerProvider)
          .result!
          .sources;
      expect(sources.map((s) => s.pageNumber), [12]);
    });

    test('does not call Gemini when the local index has nothing', () async {
      final transport = _FakeTransport(
        (_) async => throw StateError('the model must not be called'),
      );
      container = buildContainer(transport: transport);

      await container
          .read(aiSearchControllerProvider.notifier)
          .ask('Explain the mating habits of Antarctic penguins');

      final status = container.read(aiSearchControllerProvider);
      expect(transport.callCount, 0);
      expect(status.phase, AiNoteSearchPhase.noContext);
      expect(status.message, contains("couldn't find"));
    });

    test('reports an offline failure and keeps local search usable', () async {
      await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => throw const SocketException('host unreachable'),
      );
      container = buildContainer(transport: transport);

      await container.read(aiSearchControllerProvider.notifier).ask(_question);

      final status = container.read(aiSearchControllerProvider);
      expect(status.phase, AiNoteSearchPhase.offline);
      expect(status.failure, AiFailure.offline);
      expect(status.message, contains('internet connection'));

      // The local keyword index is untouched by an AI failure.
      final local = await database.pdfSearchDao.search('depletion');
      expect(local, isNotEmpty);
    });

    test('reports a missing API key without any network attempt', () async {
      await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => throw StateError('the model must not be called'),
      );
      container = buildContainer(
        transport: transport,
        config: const GeminiConfig.empty(),
      );

      await container.read(aiSearchControllerProvider.notifier).ask(_question);

      final status = container.read(aiSearchControllerProvider);
      expect(transport.callCount, 0);
      expect(status.phase, AiNoteSearchPhase.apiError);
      expect(status.failure, AiFailure.notConfigured);
    });

    test('reports a timeout as an api error, not a crash', () async {
      await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => throw TimeoutException('slow'),
      );
      container = buildContainer(transport: transport);

      await container.read(aiSearchControllerProvider.notifier).ask(_question);

      final status = container.read(aiSearchControllerProvider);
      expect(status.phase, AiNoteSearchPhase.apiError);
      expect(status.failure, AiFailure.timeout);
    });

    test('blocks a duplicate identical request while one is running', () async {
      final seeded = await _seedIndex(database);
      final release = Completer<void>();
      final transport = _FakeTransport((_) async {
        await release.future;
        return GeminiHttpResponse(
          200,
          _envelope(
            _answer(
              answer: 'Slow but grounded answer.',
              grounded: true,
              sources: [
                {'fileId': seeded.fileId, 'page': 12},
              ],
            ),
          ),
        );
      });
      container = buildContainer(transport: transport);

      final notifier = container.read(aiSearchControllerProvider.notifier);
      final first = notifier.ask(_question);
      final second = notifier.ask(_question); // must not start a second request

      expect(
        container.read(aiSearchControllerProvider).phase,
        AiNoteSearchPhase.searching,
      );

      release.complete();
      await Future.wait([first, second]);

      expect(transport.callCount, 1);
      expect(
        container.read(aiSearchControllerProvider).phase,
        AiNoteSearchPhase.success,
      );
    });

    test(
      'serves a repeated identical question from the in-memory cache',
      () async {
        final seeded = await _seedIndex(database);
        final transport = _FakeTransport(
          (_) async => GeminiHttpResponse(
            200,
            _envelope(
              _answer(
                answer: 'Cached grounding.',
                grounded: true,
                sources: [
                  {'fileId': seeded.fileId, 'page': 12},
                ],
              ),
            ),
          ),
        );
        container = buildContainer(transport: transport);

        final notifier = container.read(aiSearchControllerProvider.notifier);
        await notifier.ask(_question);
        await notifier.ask(_question);

        expect(
          transport.callCount,
          1,
          reason: 'cost control: no duplicate call',
        );
        expect(
          container.read(aiSearchControllerProvider).phase,
          AiNoteSearchPhase.success,
        );
      },
    );

    test('reset returns the UI to idle', () async {
      final seeded = await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _answer(
              answer: 'Grounded.',
              grounded: true,
              sources: [
                {'fileId': seeded.fileId, 'page': 12},
              ],
            ),
          ),
        ),
      );
      container = buildContainer(transport: transport);

      final notifier = container.read(aiSearchControllerProvider.notifier);
      await notifier.ask(_question);
      expect(container.read(aiSearchControllerProvider).hasResult, isTrue);

      notifier.reset();
      final status = container.read(aiSearchControllerProvider);
      expect(status.phase, AiNoteSearchPhase.idle);
      expect(status.hasResult, isFalse);
    });

    test('a not-grounded answer is presented as "not in your notes"', () async {
      await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => GeminiHttpResponse(
          200,
          _envelope(
            _answer(
              answer: "I couldn't find this topic in your indexed notes.",
              grounded: false,
            ),
          ),
        ),
      );
      container = buildContainer(transport: transport);

      await container
          .read(aiSearchControllerProvider.notifier)
          .ask('Describe the offside rule in cricket');

      final status = container.read(aiSearchControllerProvider);
      expect(status.phase, AiNoteSearchPhase.noContext);
      expect(status.result!.grounded, isFalse);
      expect(status.result!.sources, isEmpty);
    });

    test('scopes retrieval to the supplied file ids', () async {
      final seeded = await _seedIndex(database);
      final transport = _FakeTransport(
        (_) async => throw StateError('out-of-scope files must not be sent'),
      );
      container = buildContainer(transport: transport);

      // Asking from inside the "Attendance Rules" subject scope must not pull in
      // the physics PDF, so the model is never called at all.
      await container
          .read(aiSearchControllerProvider.notifier)
          .ask(
            'How do depletion regions behave?',
            allowedFileIds: [seeded.otherFileId],
          );

      expect(transport.callCount, 0);
      expect(
        container.read(aiSearchControllerProvider).phase,
        AiNoteSearchPhase.noContext,
      );
    });
  });
}
