import 'package:college_os/features/updates/domain/update_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseVersion', () {
    test('reads tags, build metadata and pre-release suffixes', () {
      expect(parseVersion('1.11.0'), [1, 11, 0]);
      expect(parseVersion('v1.11.0'), [1, 11, 0]);
      expect(parseVersion(' 1.11 '), [1, 11]);
      // Build numbers and pre-release tags do not order releases here.
      expect(parseVersion('1.11.0+32'), [1, 11, 0]);
      expect(parseVersion('v1.11.0-beta.2'), [1, 11, 0]);
    });

    test('refuses anything it cannot order', () {
      expect(parseVersion(''), isNull);
      expect(parseVersion('v'), isNull);
      expect(parseVersion('latest'), isNull);
      expect(parseVersion('3.x'), isNull);
      expect(parseVersion('1.11.x'), isNull);
    });
  });

  group('compareVersions', () {
    test('orders numerically, not alphabetically', () {
      expect(compareVersions([1, 11], [1, 9]), greaterThan(0));
      expect(compareVersions([1, 9], [1, 11]), lessThan(0));
      expect(compareVersions([2, 0], [1, 99]), greaterThan(0));
    });

    test('treats missing segments as zero', () {
      expect(compareVersions([1, 11], [1, 11, 0]), 0);
      expect(compareVersions([1, 11, 1], [1, 11]), greaterThan(0));
    });
  });

  group('UpdateInfo.fromJson', () {
    Map<String, Object?> manifest([
      Map<String, Object?> changes = const {},
    ]) => {
      'latest_version': '1.11.1',
      'apk_url':
          'https://github.com/tsp20gamer/CollegeOS/releases/download/v1.11.1/app-release.apk',
      'changelog': '• Faster timetable\n• Fixed attendance rounding',
      'force_update': false,
      ...changes,
    };

    test('reads the release the workflow publishes', () {
      final info = UpdateInfo.fromJson(manifest());

      expect(info.latestVersion, '1.11.1');
      expect(info.versionLabel, 'v1.11.1');
      expect(
        info.apkUrl.toString(),
        'https://github.com/tsp20gamer/CollegeOS/releases/download/v1.11.1/app-release.apk',
      );
      expect(info.changelog, contains('Faster timetable'));
      expect(info.forceUpdate, isFalse);
    });

    test('defaults the changelog and reads a forced release', () {
      final info = UpdateInfo.fromJson(
        manifest({'changelog': '  ', 'force_update': true}),
      );

      expect(info.changelog, 'Bug fixes and improvements.');
      expect(info.forceUpdate, isTrue);
    });

    test('refuses a manifest it cannot turn into an update', () {
      expect(
        () => UpdateInfo.fromJson(manifest({'latest_version': ''})),
        throwsA(isA<UpdateManifestFailure>()),
      );
      expect(
        () => UpdateInfo.fromJson(manifest({'latest_version': 'latest'})),
        throwsA(isA<UpdateManifestFailure>()),
      );
      expect(
        () => UpdateInfo.fromJson(manifest({'apk_url': 42})),
        throwsA(isA<UpdateManifestFailure>()),
      );
      expect(
        () => UpdateInfo.fromJson(
          manifest({'apk_url': 'http://example.com/app-release.apk'}),
        ),
        throwsA(isA<UpdateManifestFailure>()),
        reason: 'an update must never be fetched over plain http',
      );
    });
  });

  group('isNewerThan', () {
    UpdateInfo release(String version) => UpdateInfo(
      latestVersion: version,
      apkUrl: Uri.parse('https://example.com/app-release.apk'),
      changelog: 'notes',
      forceUpdate: false,
    );

    test('compares the published release against the installed build', () {
      expect(release('1.11.1').isNewerThan('1.11.0+32'), isTrue);
      expect(release('2.0.0').isNewerThan('1.11.0+32'), isTrue);
      expect(release('1.11.0').isNewerThan('1.11.0+32'), isFalse);
      expect(release('1.10.9').isNewerThan('1.11.0+32'), isFalse);
    });

    test('never offers a downgrade from an unreadable version', () {
      expect(release('latest').isNewerThan('1.11.0'), isFalse);
      expect(release('1.11.1').isNewerThan('unknown'), isFalse);
    });
  });
}
