import 'dart:convert';
import 'dart:io';

import 'package:college_os/features/feedback/application/feedback_queue.dart';
import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/data/feedback_local_store.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _device = FeedbackDeviceInfo(
  appVersion: '1.15.0+36',
  deviceModel: 'Google Pixel 8',
  androidVersion: '15 (SDK 35)',
);

const _jpeg = FeedbackUpload(
  bytes: [0xFF, 0xD8, 0xFF, 0xE0, 0, 1, 2, 3],
  mimeType: 'image/jpeg',
  fileName: 'a.jpg',
);

/// A scripted feedback service: answers in order, records what it received.
class _Server {
  _Server(this.answers);

  final List<http.Response Function(http.Request)> answers;
  final requests = <http.Request>[];

  late final client = MockClient((request) async {
    requests.add(request);
    if (answers.isEmpty) throw StateError('unexpected request');
    return answers.removeAt(0)(request);
  });

  static http.Response created(http.Request request, {bool duplicate = false}) {
    final clientId = RegExp('name="client_id"\r\n\r\n([^\r]*)')
        .firstMatch(latin1.decode(request.bodyBytes))!
        .group(1);
    return http.Response(
      jsonEncode({
        'ok': true,
        'id': 'fb_$clientId',
        'token': 'item-token',
        'duplicate': duplicate,
      }),
      201,
    );
  }

  static http.Response offline(http.Request request) =>
      throw http.ClientException('Failed host lookup', request.url);

  static http.Response status(int code, String error, {int? retryAfter}) =>
      http.Response(
        jsonEncode({
          'ok': false,
          'error': error,
          'message': 'Refused: $error',
          'retry_after': ?retryAfter,
        }),
        code,
      );
}

void main() {
  late Directory root;
  var now = DateTime.utc(2026, 11, 1, 9);
  var ids = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('feedback_queue_test');
    now = DateTime.utc(2026, 11, 1, 9);
    ids = 0;
  });
  tearDown(() => root.delete(recursive: true));

  FeedbackQueue queueWith(_Server server) => FeedbackQueue(
    store: FeedbackLocalStore(() async => root),
    api: FeedbackApiClient(client: server.client),
    clock: () => now,
    newClientId: () => 'client-${++ids}',
  );

  FeedbackDraft draft({
    String message = '  Attendance shows 0%  ',
    List<FeedbackUpload> screenshots = const [],
    bool includeDevice = true,
  }) => FeedbackDraft(
    type: FeedbackType.bug,
    message: message,
    rating: 3,
    contact: '  ',
    device: _device,
    includeDeviceInfo: includeDevice,
    screenshots: screenshots,
  );

  List<File> shots() {
    final directory = Directory('${root.path}/feedback/shots');
    return directory.existsSync()
        ? directory.listSync().whereType<File>().toList()
        : const [];
  }

  test(
    'enqueue saves the report and its screenshots, surviving a restart',
    () async {
      final server = _Server([]);
      final item = await queueWith(server)
          .enqueue(draft(screenshots: const [_jpeg, _jpeg]));

      expect(item.clientId, 'client-1');
      expect(item.message, 'Attendance shows 0%');
      expect(item.contact, isNull);
      expect(item.screenshots, ['client-1_0.jpg', 'client-1_1.jpg']);
      expect(shots(), hasLength(2));
      expect(server.requests, isEmpty);

      // A new queue over the same folder is the app after a restart.
      final restarted = await queueWith(server).items();
      expect(restarted.single.clientId, 'client-1');
      expect(restarted.single.deviceModel, 'Google Pixel 8');
      expect(restarted.single.state, QueuedFeedbackState.pending);
    },
  );

  test('the device toggle keeps model and Android version out', () async {
    final item = await queueWith(_Server([]))
        .enqueue(draft(includeDevice: false));
    expect(item.appVersion, '1.15.0+36');
    expect(item.deviceModel, isNull);
    expect(item.androidVersion, isNull);
  });

  test(
    'install identity is a UUID v4 plus secret, stable across restarts',
    () async {
      final first = await FeedbackLocalStore(() async => root)
          .loadOrCreateInstall();
      final again = await FeedbackLocalStore(() async => root)
          .loadOrCreateInstall();
      expect(
        first.installId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(first.installToken.length, greaterThanOrEqualTo(32));
      expect(again.installId, first.installId);
      expect(again.installToken, first.installToken);
    },
  );

  test(
    'a successful send removes the report and frees its screenshots',
    () async {
      final server = _Server([_Server.created]);
      final queue = queueWith(server);
      await queue.enqueue(draft(screenshots: const [_jpeg]));

      final result = await queue.flush();

      expect(result.sent, 1);
      expect(await queue.items(), isEmpty);
      expect(shots(), isEmpty);
      final body = latin1.decode(server.requests.single.bodyBytes);
      expect(body, contains('client-1'));
      expect(body, contains('name="screenshots"; filename="client-1_0.jpg"'));
      final install = await FeedbackLocalStore(() async => root)
          .loadOrCreateInstall();
      expect(
        server.requests.single.headers['X-Install-Token'],
        install.installToken,
      );
    },
  );

  test('no connection keeps it queued, and the next flush sends it', () async {
    final server = _Server([_Server.offline, _Server.offline, _Server.created]);
    final queue = queueWith(server);
    await queue.enqueue(draft(screenshots: const [_jpeg]));

    final first = await queue.flush();
    expect(first.kept, 1);
    final kept = (await queue.items()).single;
    expect(kept.attempts, 1);
    expect(kept.state, QueuedFeedbackState.pending);
    expect(kept.lastError, contains('No internet'));
    expect(shots(), hasLength(1));

    final second = await queue.flush();
    expect(second.sent, 1);
    expect(await queue.items(), isEmpty);
    expect(shots(), isEmpty);
  });

  test('5xx keeps it queued', () async {
    final queue = queueWith(
      _Server([(_) => _Server.status(503, 'server_error')]),
    );
    await queue.enqueue(draft());
    expect((await queue.flush()).kept, 1);
    expect((await queue.items()).single.state, QueuedFeedbackState.pending);
  });

  test('429 waits for Retry-After before the next automatic attempt', () async {
    final server = _Server([
      (_) => _Server.status(429, 'rate_limited', retryAfter: 600),
      _Server.created,
    ]);
    final queue = queueWith(server);
    await queue.enqueue(draft());

    expect((await queue.flush()).kept, 1);
    expect(
      (await queue.items()).single.nextAttemptAt,
      now.add(const Duration(minutes: 10)),
    );

    now = now.add(const Duration(minutes: 5));
    expect((await queue.flush()).sent, 0);
    expect(server.requests, hasLength(1));

    now = now.add(const Duration(minutes: 6));
    expect((await queue.flush()).sent, 1);
    expect(await queue.items(), isEmpty);
  });

  test(
    'another 4xx is dropped: marked failed, screenshots freed, never retried',
    () async {
      final server = _Server([(_) => _Server.status(400, 'message_too_long')]);
      final queue = queueWith(server);
      await queue.enqueue(draft(screenshots: const [_jpeg]));

      final result = await queue.flush();

      expect(result.rejected, 1);
      final failed = (await queue.items()).single;
      expect(failed.state, QueuedFeedbackState.failed);
      expect(failed.lastError, 'Refused: message_too_long');
      expect(failed.screenshots, isEmpty);
      expect(shots(), isEmpty);

      await queue.flush(force: true);
      expect(server.requests, hasLength(1));

      await queue.discard(failed.clientId);
      expect(await queue.items(), isEmpty);
    },
  );

  test('a stopped report does not block the ones behind it', () async {
    final server = _Server([
      (_) => _Server.status(415, 'image_type'),
      _Server.created,
    ]);
    final queue = queueWith(server);
    await queue.enqueue(draft(message: 'first'));
    await queue.enqueue(draft(message: 'second'));

    final result = await queue.flush();
    expect(result.rejected, 1);
    expect(result.sent, 1);
  });

  test('re-enqueueing the same client id does not duplicate it', () async {
    final queue = queueWith(_Server([]));
    final a = await queue.enqueue(draft(), clientId: 'same');
    final b = await queue.enqueue(draft(message: 'changed'), clientId: 'same');
    expect(b.message, a.message);
    expect(await queue.items(), hasLength(1));
  });

  test(
    'a launch flush and a tap on Send never post the same report twice',
    () async {
      final server = _Server([_Server.created, _Server.created]);
      final queue = queueWith(server);
      final item = await queue.enqueue(draft());

      final results = await Future.wait([
        queue.flush(),
        queue.sendNow(item.clientId),
        queue.flush(),
      ]);

      expect(server.requests, hasLength(1));
      expect((results[0] as FeedbackFlushResult).sent, 1);
      expect(
        (results[1] as FeedbackSendResult).outcome,
        FeedbackSendOutcome.sent,
      );
      expect(await queue.items(), isEmpty);
    },
  );

  test(
    'every retry carries the same client id so the service can dedupe',
    () async {
      final server = _Server([
        (_) => _Server.status(502, 'server_error'),
        (request) => _Server.created(request, duplicate: true),
      ]);
      final queue = queueWith(server);
      await queue.enqueue(draft());
      await queue.flush();
      final result = await queue.flush();

      expect(result.sent, 1);
      String clientIdOf(http.Request request) =>
          RegExp('name="client_id"\r\n\r\n([^\r]*)')
              .firstMatch(latin1.decode(request.bodyBytes))!
              .group(1)!;
      expect(server.requests.map(clientIdOf).toSet(), {'client-1'});
    },
  );

  test('an empty outbox makes no request and creates no files', () async {
    final server = _Server([]);
    final result = await queueWith(server).flush();
    expect(result.sent + result.kept + result.rejected, 0);
    expect(server.requests, isEmpty);
    expect(Directory('${root.path}/feedback').existsSync(), isFalse);
  });

  test('a damaged queue file is read as empty instead of crashing', () async {
    await Directory('${root.path}/feedback').create();
    await File('${root.path}/feedback/queue.json').writeAsString('{not json');
    expect(await queueWith(_Server([])).items(), isEmpty);
  });

  group('name and anonymous', () {
    FeedbackDraft sender({
      String? name,
      String? contact,
      bool anonymous = false,
    }) => FeedbackDraft(
      type: FeedbackType.idea,
      message: 'Weekly view',
      contact: contact,
      name: name,
      anonymous: anonymous,
      device: _device,
    );

    test('a named report keeps its cleaned name across a restart', () async {
      await queueWith(
        _Server([]),
      ).enqueue(sender(name: '  Asha\u0007  Rao ', contact: 'a@example.com'));
      final reloaded = (await queueWith(_Server([])).items()).single;
      expect(reloaded.name, 'Asha Rao');
      expect(reloaded.contact, 'a@example.com');
      expect(reloaded.anonymous, isFalse);
    });

    test('an anonymous report stores no name and no contact, and posts '
        'anonymous=1 without them', () async {
      final server = _Server([_Server.created]);
      final queue = queueWith(server);
      await queue.enqueue(
        sender(name: 'Asha', contact: 'a@example.com', anonymous: true),
      );

      final saved = (await queueWith(_Server([])).items()).single;
      expect(saved.anonymous, isTrue);
      expect(saved.name, isNull);
      expect(saved.contact, isNull);
      final raw = await File('${root.path}/feedback/queue.json').readAsString();
      expect(raw, isNot(contains('Asha')));
      expect(raw, isNot(contains('a@example.com')));

      expect((await queue.flush()).sent, 1);
      final body = latin1.decode(server.requests.single.bodyBytes);
      expect(
        RegExp('name="anonymous"\r\n\r\n([^\r]*)').firstMatch(body)!.group(1),
        '1',
      );
      expect(body, isNot(contains('name="name"')));
      expect(body, isNot(contains('name="contact"')));
    });

    test('names are capped at 60 characters', () async {
      await queueWith(_Server([])).enqueue(sender(name: 'x' * 90));
      expect((await queueWith(_Server([])).items()).single.name, 'x' * 60);
    });

    test('reports saved by the earlier build, without the new keys, still '
        'load and send as unnamed', () async {
      await Directory('${root.path}/feedback').create();
      await File('${root.path}/feedback/queue.json').writeAsString(
        jsonEncode([
          {
            'client_id': 'legacy-1',
            'created_at': '2026-11-01T09:00:00.000Z',
            'type': 'bug',
            'message': 'Old report',
            'rating': null,
            'contact': 'old@example.com',
            'app_version': '1.15.1+44',
            'device_model': null,
            'android_version': null,
            'screenshots': <String>[],
            'state': 'pending',
            'attempts': 1,
            'last_error': null,
            'next_attempt_at': null,
          },
        ]),
      );
      final server = _Server([_Server.created]);
      final queue = queueWith(server);
      final legacy = (await queue.items()).single;
      expect(legacy.clientId, 'legacy-1');
      expect(legacy.name, isNull);
      expect(legacy.anonymous, isFalse);
      expect(legacy.contact, 'old@example.com');

      expect((await queue.flush()).sent, 1);
      final body = latin1.decode(server.requests.single.bodyBytes);
      expect(body, contains('old@example.com'));
      expect(body, isNot(contains('name="name"')));
    });

    test(
      'the last name is remembered, cleaned, and forgotten when emptied',
      () async {
        final store = FeedbackLocalStore(() async => root);
        expect(await store.readLastName(), isNull);
        await store.writeLastName('  Asha ');
        expect(
          await FeedbackLocalStore(() async => root).readLastName(),
          'Asha',
        );
        await store.writeLastName('   ');
        expect(await store.readLastName(), isNull);
      },
    );
  });
}
