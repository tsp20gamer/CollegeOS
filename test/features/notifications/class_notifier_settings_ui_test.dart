import 'package:college_os/app/app.dart';
import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/features/notifications/application/notification_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:college_os/features/subjects/data/drift_subject_repository.dart';
import 'package:college_os/features/timetable/data/drift_timetable_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Settings class notifier controls class reminders end to end', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final classIds = await _seedClasses(database, notificationsEnabled: true);
    final platform = _TestNotificationPlatform();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notificationPlatformProvider.overrideWithValue(platform),
        ],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _openSettings(tester);

    // The switch reflects the stored preference and starts on.
    final switchFinder = find.byKey(const Key('class_notifier_switch'));
    await _scrollUntilFound(tester, switchFinder);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(find.textContaining('10 min before every class'), findsOneWidget);

    // Startup projected an alarm for each class that carries a reminder.
    expect(
      platform.pendingItems.map(
        (item) => parseNotificationPayload(item.payload),
      ),
      containsAll(
        classIds.map(
          (id) => (type: NotificationEntityType.classReminder, entityId: id),
        ),
      ),
    );

    // A custom time is saved from the shared picker.
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('class_reminder_time_tile')),
    );
    await tester.tap(find.byKey(const Key('class_reminder_time_tile')));
    await tester.pumpAndSettle();
    expect(find.text('Reminder time'), findsWidgets);
    await tester.tap(find.byKey(const Key('class_notifier_minutes_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').last);
    await tester.pumpAndSettle();
    expect(find.text('Reminds you 20 min before.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('class_notifier_save_button')));
    await tester.pumpAndSettle();

    expect(
      (await database.settingsDao.getSettings()).classReminderMinutesBefore,
      20,
    );
    expect(find.textContaining('Reminder time saved'), findsOneWidget);
    // Let the save message finish so the next one is not queued behind it.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Applying it rewrites every class in the active semester.
    await _scrollUntilFound(
      tester,
      find.byKey(const Key('class_notifier_apply_all_tile')),
    );
    await tester.tap(find.byKey(const Key('class_notifier_apply_all_tile')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('will remind you 20 min before'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm_apply_class_reminders')));
    await tester.pumpAndSettle();

    final applied = await database.select(database.timetableEntries).get();
    expect(
      applied.map((row) => row.reminderMinutesBefore).toSet(),
      {20},
      reason: 'every class now uses the class-notifier time',
    );
    expect(find.text('Reminder time applied to 2 classes.'), findsOneWidget);

    // Switching the notifier off silences classes and clears their pending
    // alarms while the global notifications master stays on.
    await _scrollUntilFound(tester, switchFinder);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final settings = await database.settingsDao.getSettings();
    expect(settings.classRemindersEnabled, isFalse);
    expect(settings.notificationsEnabled, isTrue);
    expect(
      platform.pendingItems.where(
        (item) =>
            parseNotificationPayload(item.payload)?.type ==
            NotificationEntityType.classReminder,
      ),
      isEmpty,
      reason: 'no class alarm survives the switch being turned off',
    );
    expect(
      platform.cancelled
          .where((entry) => entry.type == NotificationEntityType.classReminder)
          .map((entry) => entry.id)
          .toSet(),
      classIds.toSet(),
      reason: 'both class alarms are cancelled when the notifier goes off',
    );
    expect(
      find.textContaining('Your timetable classes stay silent'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('class notifier explains that global notifications are off', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await _seedClasses(database, notificationsEnabled: false);
    // Android has not granted permission yet, so turning notifications on here
    // exercises the real request path.
    final platform = _TestNotificationPlatform(allowed: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notificationPlatformProvider.overrideWithValue(platform),
        ],
        child: const CollegeOsApp(enableStartupAnimation: false),
      ),
    );
    await _openSettings(tester);

    await _scrollUntilFound(
      tester,
      find.byKey(const Key('class_notifier_notifications_off_notice')),
    );
    expect(
      find.text('Class reminders stay paused until notifications are on.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('class_notifier_turn_on_notifications')),
    );
    await tester.pumpAndSettle();

    expect(platform.permissionRequests, 1);
    expect(
      (await database.settingsDao.getSettings()).notificationsEnabled,
      isTrue,
    );
    expect(
      find.byKey(const Key('class_notifier_notifications_off_notice')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<List<int>> _seedClasses(
  AppDatabase database, {
  required bool notificationsEnabled,
}) async {
  await DriftOnboardingRepository(database).completeSetup(
    CollegeSetup(
      studentName: 'Test Student',
      collegeName: 'City College',
      course: 'B.Tech',
      branch: 'Computer Science',
      semesterNumber: 1,
      academicYear: '2026-2027',
      semesterStartDate: DateTime(2026, 8, 1),
      semesterEndDate: DateTime(2026, 12, 20),
      defaultAttendanceTarget: 0.75,
    ),
  );
  await database.settingsDao.save(
    AppSettingsCompanion(notificationsEnabled: Value(notificationsEnabled)),
  );
  final semester = await database.semestersDao.findActive();
  final subjectId = await DriftSubjectRepository(database.subjectsDao).create((
    semesterId: semester!.id,
    name: 'Operating Systems',
    shortCode: 'OS',
    professor: 'Dr Rao',
    room: 'A-101',
    attendanceTarget: 0.75,
    displayColor: 0xFF2563EB,
  ));
  final timetable = DriftTimetableRepository(database.timetableDao);
  return [
    await timetable.create((
      semesterId: semester.id,
      subjectId: subjectId,
      weekday: DateTime.monday,
      startTime: 9 * 60,
      endTime: 10 * 60,
      room: 'A-101',
      note: '',
      reminderMinutesBefore: 10,
    )),
    await timetable.create((
      semesterId: semester.id,
      subjectId: subjectId,
      weekday: DateTime.tuesday,
      startTime: 11 * 60,
      endTime: 12 * 60,
      room: 'B-204',
      note: '',
      reminderMinutesBefore: 5,
    )),
  ];
}

Future<void> _openSettings(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byKey(const Key('open_settings_button')));
  await tester.tap(find.byKey(const Key('open_settings_button')));
  await tester.pumpAndSettle();
}

/// Scrolls the Settings list until [finder] exists, then reveals it.
///
/// The list builds lazily, so a section below the fold has to be scrolled into
/// existence before it can be addressed.
Future<void> _scrollUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 25 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(
      find.byKey(const Key('settings_list')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

final class _TestNotificationPlatform implements NotificationPlatform {
  _TestNotificationPlatform({this.allowed = true});

  bool allowed;
  int permissionRequests = 0;
  final Map<int, CollegeOsNotification> scheduled = {};
  final List<({NotificationEntityType type, int id})> cancelled = [];
  final List<PendingCollegeOsNotification> pendingItems = [];

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
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> showTestNotification() async {}

  @override
  Future<void> schedule(CollegeOsNotification notification) async {
    final id = notificationId(notification.type, notification.entityId);
    scheduled[id] = notification;
    pendingItems.removeWhere((item) => item.id == id);
    pendingItems.add((
      id: id,
      payload: notificationPayload(notification.type, notification.entityId),
    ));
  }

  @override
  Future<void> cancel(NotificationEntityType type, int entityId) async {
    cancelled.add((type: type, id: entityId));
    final id = notificationId(type, entityId);
    scheduled.remove(id);
    pendingItems.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<PendingCollegeOsNotification>> pending() async =>
      List.of(pendingItems);
}
