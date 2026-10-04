import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Settings test notification requests permission and displays', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.settingsDao.save(
      const AppSettingsCompanion(
        onboardingCompleted: Value(true),
        notificationsEnabled: Value(false),
      ),
    );
    final platform = _TestNotificationPlatform();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notificationPlatformProvider.overrideWithValue(platform),
          appVersionProvider.overrideWith((ref) async => '1.5.1+10'),
        ],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('open_settings_button')),
    );
    await tester.tap(find.byKey(const Key('open_settings_button')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('settings_list')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification_settings_tile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('send_test_notification')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send_test_notification')));
    await tester.pumpAndSettle();

    expect(platform.permissionRequests, 1);
    expect(platform.testNotifications, 1);
    expect(
      (await database.settingsDao.getSettings()).notificationsEnabled,
      isTrue,
    );
    expect(
      find.text('Test sent. Check your notification shade.'),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('enable_precise_reminders')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('enable_precise_reminders')));
    await tester.pump();
    expect(platform.exactAlarmPermissionRequests, 1);
    await tester.ensureVisible(
      find.byKey(const Key('open_notification_battery_settings')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('open_notification_battery_settings')),
    );
    await tester.pump();
    expect(platform.batterySettingsOpens, 1);
    await tester.tap(
      find.byKey(const Key('open_android_notification_settings')),
    );
    await tester.pump();
    expect(platform.settingsOpens, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

final class _TestNotificationPlatform
    implements NotificationPlatform, NotificationDiagnosticsPlatform {
  var allowed = false;
  var permissionRequests = 0;
  var testNotifications = 0;
  var settingsOpens = 0;
  var exactAlarmPermissionRequests = 0;
  var batterySettingsOpens = 0;

  @override
  Future<String?> initialize(void Function(String payload) onTap) async => null;

  @override
  Future<bool> notificationsEnabled() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    allowed = true;
    return true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    exactAlarmPermissionRequests++;
    return true;
  }

  @override
  Future<void> openNotificationSettings() async {
    settingsOpens++;
  }

  @override
  Future<void> openBatterySettings() async {
    batterySettingsOpens++;
  }

  @override
  Future<void> showTestNotification() async {
    testNotifications++;
  }

  @override
  Future<void> schedule(CollegeOsNotification notification) async {}

  @override
  Future<void> cancel(NotificationEntityType type, int entityId) async {}

  @override
  Future<List<PendingCollegeOsNotification>> pending() async => const [];

  @override
  Future<NotificationDiagnostics> diagnostics() async =>
      NotificationDiagnostics(
        permissionEnabled: allowed,
        channelExists: true,
        channelEnabled: allowed,
        channelImportance: 'Maximum',
        pendingReminderCount: 0,
        timezone: 'Asia/Calcutta',
        androidSdk: 36,
        batteryOptimizationExempt: false,
        exactAlarmAllowed: false,
      );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
