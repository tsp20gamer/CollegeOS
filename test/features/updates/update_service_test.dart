import 'dart:convert';

import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/updates/application/update_providers.dart';
import 'package:college_os/features/updates/data/update_repository.dart';
import 'package:college_os/features/updates/presentation/widgets/update_dialog.dart';
import 'package:college_os/update_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// What the check does with a published release, seen from the screen that asks
/// for it. No test here leaves the device: the manifest comes from a mock
/// client and the installed version comes from a provider override.
void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required http.Client client,
    required String installedVersion,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateRepositoryProvider.overrideWithValue(
            UpdateRepository(client: client),
          ),
          appVersionProvider.overrideWith((ref) async => installedVersion),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const Key('check_for_updates'),
                  onPressed: () => UpdateService.checkForUpdate(
                    context,
                    showNoUpdateMessage: true,
                  ),
                  child: const Text('Check'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  http.Client manifestClient(String version) => MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(
        json.encode({
          'latest_version': version,
          'apk_url':
              'https://github.com/tsp20gamer/CollegeOS/releases/download/v$version/app-release.apk',
          'changelog': '• CollegeOS $version',
          'force_update': false,
        }),
      ),
      200,
    ),
  );

  testWidgets('offers a newer published build', (tester) async {
    await pumpHost(
      tester,
      client: manifestClient('1.11.1'),
      installedVersion: '1.11.0+32',
    );

    await tester.tap(find.byKey(const Key('check_for_updates')));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateDialog), findsOneWidget);
    expect(find.text('CollegeOS v1.11.1'), findsOneWidget);
    expect(find.text('• CollegeOS 1.11.1'), findsOneWidget);
    expect(find.byKey(const Key('update_dialog_install')), findsOneWidget);
    expect(find.byKey(const Key('update_dialog_later')), findsOneWidget);

    // Nothing is downloaded until the student asks for it.
    expect(find.byKey(const Key('update_dialog_progress')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('says nothing on launch when the build is current', (
    tester,
  ) async {
    // A silent check is what Home runs at startup: even a newer manifest and a
    // failing one must not interrupt the dashboard.
    await pumpHost(
      tester,
      client: manifestClient('1.11.0'),
      installedVersion: '1.11.0+32',
    );
    await updateServiceSilently(tester);

    expect(find.byType(UpdateDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tells the student a manual check found nothing new', (
    tester,
  ) async {
    await pumpHost(
      tester,
      client: manifestClient('1.11.0'),
      installedVersion: '1.11.0+32',
    );

    await tester.tap(find.byKey(const Key('check_for_updates')));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateDialog), findsNothing);
    expect(find.text('CollegeOS 1.11.0+32 is up to date.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tells the student when a manual check could not run', (
    tester,
  ) async {
    await pumpHost(
      tester,
      client: MockClient((_) async => http.Response('Not Found', 404)),
      installedVersion: '1.11.0+32',
    );

    await tester.tap(find.byKey(const Key('check_for_updates')));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateDialog), findsNothing);
    expect(find.textContaining('404'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Runs the check the way Home does: covered up, with no message either way.
Future<void> updateServiceSilently(WidgetTester tester) async {
  final context = tester.element(find.byKey(const Key('check_for_updates')));
  await UpdateService.checkForUpdate(context);
  await tester.pumpAndSettle();
}
