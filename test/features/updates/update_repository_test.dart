import 'dart:async';
import 'dart:convert';

import 'package:college_os/features/updates/data/update_repository.dart';
import 'package:college_os/features/updates/domain/update_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The manifest exactly as the release workflow writes it, bullets included.
const _manifest = '''
{
  "latest_version": "1.11.1",
  "apk_url": "https://github.com/tsp20gamer/CollegeOS/releases/download/v1.11.1/app-release.apk",
  "changelog": "• CollegeOS 1.11.1\\n• Performance improvements and bug fixes",
  "force_update": false
}
''';

void main() {
  test('reads the published manifest', () async {
    Uri? requested;
    final repository = UpdateRepository(
      client: MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(
          utf8.encode(_manifest),
          200,
          headers: {'content-type': 'text/plain'},
        );
      }),
    );

    final info = await repository.fetchLatest();

    expect(info.latestVersion, '1.11.1');
    expect(info.forceUpdate, isFalse);
    expect(info.changelog, startsWith('• CollegeOS 1.11.1'));
    expect(
      requested.toString(),
      startsWith(defaultUpdateManifestUrl),
      reason: 'the check reads the manifest the release workflow commits',
    );
    expect(
      requested!.queryParameters,
      contains('t'),
      reason: 'GitHub caches raw files, so the request must bust the cache',
    );
  });

  test('reports an unexpected status instead of offering an update', () async {
    final repository = UpdateRepository(
      client: MockClient((_) async => http.Response('Not Found', 404)),
    );

    await expectLater(
      repository.fetchLatest(),
      throwsA(
        isA<UpdateCheckFailure>().having(
          (failure) => failure.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('reports a manifest that is not JSON', () async {
    final repository = UpdateRepository(
      client: MockClient((_) async => http.Response('<html>oops</html>', 200)),
    );

    await expectLater(
      repository.fetchLatest(),
      throwsA(isA<UpdateCheckFailure>()),
    );
  });

  test('reports an incomplete manifest', () async {
    final repository = UpdateRepository(
      client: MockClient(
        (_) async => http.Response('{"latest_version": "1.11.1"}', 200),
      ),
    );

    await expectLater(
      repository.fetchLatest(),
      throwsA(isA<UpdateCheckFailure>()),
    );
  });

  test('reports an unreachable server', () async {
    final repository = UpdateRepository(
      client: MockClient((_) async => throw const SocketFailure()),
    );

    await expectLater(
      repository.fetchLatest(),
      throwsA(
        isA<UpdateCheckFailure>().having(
          (failure) => failure.message,
          'message',
          contains('connection'),
        ),
      ),
    );
  });

  test('gives up on a request that never answers', () async {
    final repository = UpdateRepository(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 30),
    );

    await expectLater(
      repository.fetchLatest(),
      throwsA(
        isA<UpdateCheckFailure>().having(
          (failure) => failure.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}

/// Stands in for a socket that cannot be reached at all.
class SocketFailure implements Exception {
  const SocketFailure();
}
