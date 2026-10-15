import 'dart:convert';

import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/updates/application/update_providers.dart';
import 'package:college_os/features/updates/data/update_repository.dart';
import 'package:college_os/features/updates/presentation/widgets/update_dialog.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Settings is where a student can ask for an update on purpose.
void main() {
  testWidgets('Settings checks for updates on demand', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await DriftOnboardingRepository(database).completeSetup(
      CollegeSetup(
        studentName: 'Alexandria Student',
        collegeName: 'City College of Engineering and Technology',
        course: 'Bachelor of Technology',
        branch: 'Computer Science and Engineering',
        semesterNumber: 5,
        academicYear: '2026-2027',
        semesterStartDate: DateTime(2026, 8, 1),
        semesterEndDate: DateTime(2026, 12, 20),
        defaultAttendanceTarget: 0.75,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appVersionProvider.overrideWith((ref) async => '1.11.0+32'),
          // The whole app graph talks to this instead of the network, so the
          // launch check on Home runs too and finds nothing new.
          updateRepositoryProvider.overrideWithValue(
            UpdateRepository(
              client: MockClient(
                (_) async => http.Response.bytes(
                  utf8.encode(
                    json.encode({
                      'latest_version': '1.11.0',
                      'apk_url':
                          'https://github.com/tsp20gamer/CollegeOS/releases/download/v1.11.0/app-release.apk',
                      'changelog': '• CollegeOS 1.11.0',
                      'force_update': false,
                    }),
                  ),
                  200,
                ),
              ),
            ),
          ),
        ],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('home_dashboard_ready')),
    );

    try {
      await tester.tap(find.byKey(const Key('open_settings_button')));
      await _pumpUntilFound(tester, find.byKey(const Key('settings_list')));

      // The tile sits with the app information, below the first screenful.
      final tile = find.byKey(const Key('check_for_updates_tile'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.descendant(
          of: find.byKey(const Key('settings_list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();

      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.text('CollegeOS 1.11.0+32 is up to date.'), findsOneWidget);
      expect(find.byType(UpdateDialog), findsNothing);
    } finally {
      // Always take the app down: a mounted shell keeps test teardown waiting.
      // The extra frames let the zero-duration Drift stream-close timers that
      // ProviderScope disposal schedules fire before the invariant check.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    }
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(AppDurations.fast);
  }
  expect(finder, findsOneWidget);
}
