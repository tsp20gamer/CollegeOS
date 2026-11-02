import 'dart:async';
import 'dart:convert';

import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _install = FeedbackInstall(
  installId: '0f8fad5b-d9cb-469f-a165-70867728950e',
  installToken: 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG',
);

final _feedback = QueuedFeedback(
  clientId: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
  createdAt: DateTime.utc(2026, 11, 1),
  type: FeedbackType.bug,
  message: 'Timetable crashes when I rotate',
  rating: 4,
  contact: 'me@example.com',
  appVersion: '1.15.0+36',
  deviceModel: 'Google Pixel 8',
  androidVersion: '15 (SDK 35)',
);

http.Response _json(int status, Object body, {Map<String, String>? headers}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json', ...?headers},
    );

void main() {
  group('submit', () {
    test(
      'posts multipart with every field, the token header and files',
      () async {
        late http.Request seen;
        final api = FeedbackApiClient(
          client: MockClient((request) async {
            seen = request;
            return _json(201, {
              'ok': true,
              'id': 'fb_123',
              'token': 'item-secret',
              'attachments': 1,
              'duplicate': false,
            });
          }),
        );

        final receipt = await api.submit(
          install: _install,
          feedback: _feedback,
          screenshots: const [
            FeedbackUpload(
              bytes: [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3],
              mimeType: 'image/jpeg',
              fileName: 'shot_0.jpg',
            ),
          ],
        );

        expect(receipt.id, 'fb_123');
        expect(receipt.token, 'item-secret');
        expect(receipt.attachments, 1);
        expect(receipt.duplicate, isFalse);

        expect(seen.method, 'POST');
        expect(
          seen.url.toString(),
          'https://feedback-api.collegeos.tspop.cyou/api/v1/feedback',
        );
        expect(seen.headers['X-Install-Token'], _install.installToken);
        expect(
          seen.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );

        final body = latin1.decode(seen.bodyBytes);
        String? field(String name) =>
            RegExp('name="$name"\r\n\r\n([^\r]*)\r\n')
                .firstMatch(body)
                ?.group(1);
        expect(field('source'), 'app');
        expect(field('type'), 'bug');
        expect(field('message'), 'Timetable crashes when I rotate');
        expect(field('rating'), '4');
        expect(field('contact'), 'me@example.com');
        expect(field('install_id'), _install.installId);
        expect(field('client_id'), _feedback.clientId);
        expect(field('app_version'), '1.15.0+36');
        expect(field('device_model'), 'Google Pixel 8');
        expect(field('android_version'), '15 (SDK 35)');
        expect(body, contains('name="screenshots"; filename="shot_0.jpg"'));
        expect(body, contains('content-type: image/jpeg'));
        expect(RegExp('name="screenshots"').allMatches(body), hasLength(1));
      },
    );

    test('leaves out optional fields that are empty', () async {
      late http.Request seen;
      final api = FeedbackApiClient(
        client: MockClient((request) async {
          seen = request;
          return _json(201, {'ok': true, 'id': 9, 'token': 't'});
        }),
      );
      final bare = QueuedFeedback(
        clientId: 'c',
        createdAt: DateTime.utc(2026),
        type: FeedbackType.idea,
        message: 'Dark mode widget',
        appVersion: '1.15.0+36',
      );
      final receipt = await api.submit(install: _install, feedback: bare);
      final body = latin1.decode(seen.bodyBytes);
      expect(receipt.id, '9');
      for (final name in [
        'rating',
        'contact',
        'device_model',
        'android_version',
        'screenshots',
      ]) {
        expect(body, isNot(contains('name="$name"')), reason: name);
      }
    });

    String? fieldOf(String body, String name) =>
        RegExp('name="$name"\r\n\r\n([^\r]*)\r\n').firstMatch(body)?.group(1);

    Future<String> bodyFor(QueuedFeedback feedback) async {
      late http.Request seen;
      final api = FeedbackApiClient(
        client: MockClient((request) async {
          seen = request;
          return _json(201, {'ok': true, 'id': 'fb_1', 'token': 't'});
        }),
      );
      await api.submit(install: _install, feedback: feedback);
      return latin1.decode(seen.bodyBytes);
    }

    QueuedFeedback withSender({String? name, required bool anonymous}) =>
        QueuedFeedback(
          clientId: 'c-1',
          createdAt: DateTime.utc(2026, 11, 1),
          type: FeedbackType.idea,
          message: 'Weekly view',
          contact: 'me@example.com',
          name: name,
          anonymous: anonymous,
          appVersion: '1.15.1+45',
        );

    test('a named report sends name, contact and anonymous=0', () async {
      final body = await bodyFor(withSender(name: 'Asha', anonymous: false));
      expect(fieldOf(body, 'name'), 'Asha');
      expect(fieldOf(body, 'contact'), 'me@example.com');
      expect(fieldOf(body, 'anonymous'), '0');
    });

    test('an anonymous report sends anonymous=1 and drops name and contact, '
        'even if they were set', () async {
      final body = await bodyFor(withSender(name: 'Asha', anonymous: true));
      expect(fieldOf(body, 'anonymous'), '1');
      expect(body, isNot(contains('name="name"')));
      expect(body, isNot(contains('name="contact"')));
      expect(body, isNot(contains('Asha')));
      expect(body, isNot(contains('me@example.com')));
      expect(fieldOf(body, 'message'), 'Weekly view');
    });

    test('reports a duplicate the service already had', () async {
      final api = FeedbackApiClient(
        client: MockClient(
          (_) async => _json(200, {
            'ok': true,
            'id': 'fb_1',
            'token': 't',
            'duplicate': true,
          }),
        ),
      );
      final receipt = await api.submit(install: _install, feedback: _feedback);
      expect(receipt.duplicate, isTrue);
    });
  });

  group('error mapping', () {
    Future<FeedbackApiException> failWith(http.Response response) async {
      final api = FeedbackApiClient(client: MockClient((_) async => response));
      try {
        await api.submit(install: _install, feedback: _feedback);
      } on FeedbackApiException catch (error) {
        return error;
      }
      fail('expected a FeedbackApiException');
    }

    test(
      'a validation refusal is final and carries the service message',
      () async {
        final error = await failWith(
          _json(400, {
            'ok': false,
            'error': 'message_too_long',
            'message': 'Message is longer than 3000 characters.',
          }),
        );
        expect(error.retryable, isFalse);
        expect(error.statusCode, 400);
        expect(error.code, 'message_too_long');
        expect(error.message, 'Message is longer than 3000 characters.');
      },
    );

    test('415 and 413 are final', () async {
      expect(
        (await failWith(_json(415, {'ok': false, 'error': 'image_type'})))
            .retryable,
        isFalse,
      );
      expect(
        (await failWith(
          _json(413, {'ok': false, 'error': 'payload_too_large'}),
        )).retryable,
        isFalse,
      );
    });

    test('429 is retried later, honouring retry_after', () async {
      final error = await failWith(
        _json(
          429,
          {'ok': false, 'error': 'rate_limited', 'retry_after': 120},
          headers: {'retry-after': '120'},
        ),
      );
      expect(error.retryable, isTrue);
      expect(error.code, 'rate_limited');
      expect(error.retryAfter, const Duration(seconds: 120));
    });

    test('Retry-After header alone is read too', () async {
      final error = await failWith(
        http.Response('slow down', 429, headers: {'retry-after': '30'}),
      );
      expect(error.retryAfter, const Duration(seconds: 30));
    });

    test('5xx and HTML error pages are retried later', () async {
      expect((await failWith(_json(500, {'ok': false}))).retryable, isTrue);
      expect(
        (await failWith(http.Response('<html>Bad gateway</html>', 502)))
            .retryable,
        isTrue,
      );
    });

    test('a 2xx without an id is retried, not trusted', () async {
      expect((await failWith(_json(201, {'ok': true}))).retryable, isTrue);
    });
  });

  group('hosts', () {
    test(
      'falls back to workers.dev only when the primary is unreachable',
      () async {
        final hosts = <String>[];
        final api = FeedbackApiClient(
          client: MockClient((request) async {
            hosts.add(request.url.host);
            if (request.url.host == 'feedback-api.collegeos.tspop.cyou') {
              throw http.ClientException('Failed host lookup', request.url);
            }
            return _json(201, {'ok': true, 'id': 'fb_2', 'token': 't'});
          }),
        );
        final receipt = await api.submit(
          install: _install,
          feedback: _feedback,
        );
        expect(receipt.id, 'fb_2');
        expect(hosts, [
          'feedback-api.collegeos.tspop.cyou',
          'collegeos-feedback.steja3471.workers.dev',
        ]);
      },
    );

    test(
      'an HTTP error from the primary is not retried on the fallback',
      () async {
        final hosts = <String>[];
        final api = FeedbackApiClient(
          client: MockClient((request) async {
            hosts.add(request.url.host);
            return _json(503, {'ok': false, 'error': 'server_error'});
          }),
        );
        await expectLater(
          api.submit(install: _install, feedback: _feedback),
          throwsA(
            isA<FeedbackApiException>().having(
              (e) => e.retryable,
              'retryable',
              isTrue,
            ),
          ),
        );
        expect(hosts, ['feedback-api.collegeos.tspop.cyou']);
      },
    );

    test('no reachable host is a retryable offline error', () async {
      final api = FeedbackApiClient(
        client: MockClient(
          (request) async => throw http.ClientException('offline', request.url),
        ),
      );
      await expectLater(
        api.submit(install: _install, feedback: _feedback),
        throwsA(
          isA<FeedbackApiException>()
              .having((e) => e.retryable, 'retryable', isTrue)
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });

    test('a timeout is retryable and does not hop hosts', () async {
      final hosts = <String>[];
      final api = FeedbackApiClient(
        timeout: const Duration(milliseconds: 20),
        client: MockClient((request) {
          hosts.add(request.url.host);
          return Completer<http.Response>().future;
        }),
      );
      await expectLater(
        api.submit(install: _install, feedback: _feedback),
        throwsA(
          isA<FeedbackApiException>().having(
            (e) => e.retryable,
            'retryable',
            isTrue,
          ),
        ),
      );
      expect(hosts, hasLength(1));
    });
  });

  group('fetchMine', () {
    test('asks for this install only and reads status and reply', () async {
      late http.Request seen;
      final api = FeedbackApiClient(
        client: MockClient((request) async {
          seen = request;
          return _json(200, {
            'ok': true,
            'items': [
              {
                'id': 'fb_9',
                'created_at': '2026-11-01T09:00:00Z',
                'updated_at': '2026-11-01T10:00:00Z',
                'type': 'idea',
                'message': 'Widget for next class',
                'rating': 5,
                'status': 'in_progress',
                'admin_reply': 'Working on it!',
                'replied_at': '2026-11-01T10:00:00Z',
                'attachments': 2,
                'display_name': 'Asha',
                'anonymous': 0,
              },
              {
                'id': 'fb_8',
                'created_at': '2026-10-30T09:00:00Z',
                'type': 'bug',
                'message': 'Typo',
                'status': 'wont_fix',
                'admin_reply': null,
                'attachments': [],
                'display_name': null,
                'anonymous': 1,
              },
            ],
          });
        }),
      );

      final items = await api.fetchMine(_install);

      expect(seen.method, 'GET');
      expect(seen.url.path, '/api/v1/feedback/mine');
      expect(seen.url.queryParameters, {'install_id': _install.installId});
      expect(seen.headers['X-Install-Token'], _install.installToken);
      expect(items, hasLength(2));
      expect(items.first.status, FeedbackStatus.inProgress);
      expect(items.first.status.label, 'In progress');
      expect(items.first.adminReply, 'Working on it!');
      expect(items.first.attachments, 2);
      expect(items.first.type, FeedbackType.idea);
      expect(items.last.status.label, 'Not planned');
      expect(items.last.adminReply, isNull);
      expect(items.first.displayName, 'Asha');
      expect(items.first.anonymous, isFalse);
      expect(items.last.displayName, isNull);
      expect(items.last.anonymous, isTrue);
    });

    test('items from before names existed read as unnamed, not anonymous', () {
      final item = FeedbackItem.fromJson({
        'id': 1,
        'created_at': '2026-11-01T09:00:00Z',
        'type': 'bug',
        'message': 'Old',
        'status': 'new',
      });
      expect(item.displayName, isNull);
      expect(item.anonymous, isFalse);
      final cached = FeedbackItem.fromJson(
        FeedbackItem.fromJson({
          'id': 2,
          'created_at': '2026-11-01T09:00:00Z',
          'type': 'idea',
          'message': 'New',
          'status': 'new',
          'display_name': 'Ravi',
          'anonymous': false,
        }).toJson(),
      );
      expect(cached.displayName, 'Ravi');
      expect(cached.anonymous, isFalse);
    });

    test('a wrong token is reported as a final error', () async {
      final api = FeedbackApiClient(
        client: MockClient(
          (_) async => _json(401, {
            'ok': false,
            'error': 'unauthorized',
            'message': 'Unauthorized',
          }),
        ),
      );
      await expectLater(
        api.fetchMine(_install),
        throwsA(
          isA<FeedbackApiException>().having(
            (e) => e.retryable,
            'retryable',
            isFalse,
          ),
        ),
      );
    });
  });
}
