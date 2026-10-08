import 'package:college_os/core/database/database_enums.dart';
import 'package:college_os/core/services/notifications/notification_models.dart';
import 'package:college_os/core/services/notifications/notification_platform.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/notifications/application/notification_coordinator.dart';
import 'package:college_os/features/settings/domain/settings_repository.dart';
import 'package:college_os/features/tasks/domain/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 13, 9);

  test(
    'attendance reminder updates independently and cancels when disabled',
    () async {
      final platform = _FakePlatform();
      final settings = _FakeSettings(enabled: true);
      final coordinator = NotificationCoordinator(
        platform: platform,
        tasks: _FakeTasks(const []),
        exams: _FakeExams(const []),
        settings: settings,
        now: () => now,
      );
      final CollegeOsNotification reminder = (
        type: NotificationEntityType.attendance,
        entityId: 1,
        title: 'Attendance',
        body: '2 classes',
        scheduledAt: now.add(const Duration(hours: 2)),
      );
      await coordinator.syncAttendanceReminder(reminder);
      expect(platform.scheduled[0], reminder);
      platform.pendingItems.add((id: 0, payload: 'attendance:1'));
      await coordinator.reconcile();
      expect(platform.scheduled[0], reminder);
      await coordinator.syncAttendanceReminder(null);
      expect(platform.scheduled[0], isNull);
      await coordinator.syncAttendanceReminder(reminder);
      await coordinator.disable();
      await coordinator.syncAttendanceReminder(reminder);
      expect(platform.scheduled[0], isNull);
    },
  );

  test('task and exam IDs are stable, disjoint, and payloads are typed', () {
    expect(notificationId(NotificationEntityType.task, 42), 42);
    expect(notificationId(NotificationEntityType.exam, 42), -42);
    expect(parseNotificationPayload('task:42'), (
      type: NotificationEntityType.task,
      entityId: 42,
    ));
    expect(parseNotificationPayload('exam:42'), (
      type: NotificationEntityType.exam,
      entityId: 42,
    ));
    expect(parseNotificationPayload('bad:42'), isNull);
  });

  test('class reminders keep a disjoint, positive notification ID band', () {
    expect(
      notificationId(NotificationEntityType.classReminder, 7),
      classReminderNotificationIdBase + 7,
    );
    expect(parseNotificationPayload('classReminder:7'), (
      type: NotificationEntityType.classReminder,
      entityId: 7,
    ));
    final ids = {
      for (final type in NotificationEntityType.values) notificationId(type, 1),
    };
    expect(
      ids,
      hasLength(NotificationEntityType.values.length),
      reason: 'every entity type owns its own ID',
    );
    expect(
      notificationId(NotificationEntityType.classReminder, 1),
      greaterThan(0),
      reason: 'Android notification IDs stay positive inside the band',
    );
    expect(
      () => notificationId(NotificationEntityType.classReminder, 0),
      throwsArgumentError,
    );
  });

  test('class reminders project once, update in place and cancel stale', () async {
    final platform = _FakePlatform();
    final settings = _FakeSettings(enabled: true);
    final coordinator = NotificationCoordinator(
      platform: platform,
      tasks: _FakeTasks(const []),
      exams: _FakeExams(const []),
      settings: settings,
      now: () => now,
    );
    final firstId = notificationId(NotificationEntityType.classReminder, 1);
    final secondId = notificationId(NotificationEntityType.classReminder, 2);
    final first = _classReminder(id: 1, minutesBefore: 10);
    final second = _classReminder(id: 2, minutesBefore: 30);

    await coordinator.syncClassReminders([first, second]);
    expect(platform.scheduled.keys, containsAll([firstId, secondId]));

    // Android reports both alarms as pending, so an unchanged projection is not
    // re-scheduled on the next clock tick.
    platform.pendingItems.addAll([
      (id: firstId, payload: 'classReminder:1'),
      (id: secondId, payload: 'classReminder:2'),
    ]);
    platform.scheduled.clear();
    await coordinator.syncClassReminders([first, second]);
    expect(platform.scheduled, isEmpty);

    // A dropped class is cancelled, and a changed lead time is replaced.
    await coordinator.syncClassReminders([first]);
    expect(platform.cancelled, [
      (type: NotificationEntityType.classReminder, id: 2),
    ]);
    expect(platform.scheduled.containsKey(firstId), isFalse);

    final later = _classReminder(id: 1, minutesBefore: 60);
    await coordinator.syncClassReminders([later]);
    expect(platform.scheduled[firstId], later);

    // Switching notifications off clears the whole namespace, and a later sync
    // cannot put anything back while they stay off.
    await coordinator.disable();
    expect(platform.scheduled, isEmpty);
    await coordinator.syncClassReminders([later]);
    expect(platform.scheduled, isEmpty);
  });

  test('startup reconcile leaves class alarms to the class channel', () async {
    final classId = notificationId(NotificationEntityType.classReminder, 3);
    final platform = _FakePlatform()
      ..pendingItems.add((id: classId, payload: 'classReminder:3'))
      ..pendingItems.add((id: 999, payload: 'task:999'));
    final coordinator = NotificationCoordinator(
      platform: platform,
      tasks: _FakeTasks(const []),
      exams: _FakeExams(const []),
      settings: _FakeSettings(enabled: true),
      now: () => now,
    );

    await coordinator.initialize((_) {});

    expect(
      platform.cancelled,
      [(type: NotificationEntityType.task, id: 999)],
      reason: 'a valid class projection must survive the startup sweep',
    );
  });

  test(
    'startup reconciles future intent without requesting permission',
    () async {
      final platform = _FakePlatform()
        ..pendingItems.add((id: 999, payload: 'task:999'));
      final settings = _FakeSettings(enabled: true);
      final tasks = _FakeTasks([
        _task(id: 1, reminder: now.add(const Duration(hours: 2))),
        _task(
          id: 2,
          reminder: now.add(const Duration(hours: 3)),
          completed: true,
        ),
        _task(id: 3, reminder: now.subtract(const Duration(minutes: 1))),
      ]);
      final exams = _FakeExams([
        _exam(id: 1, reminder: now.add(const Duration(days: 1))),
      ]);
      final coordinator = NotificationCoordinator(
        platform: platform,
        tasks: tasks,
        exams: exams,
        settings: settings,
        now: () => now,
      );

      await coordinator.initialize((_) {});

      expect(platform.permissionRequests, 0);
      expect(platform.scheduled.keys, {1, -1});
      expect(platform.cancelled, [
        (type: NotificationEntityType.task, id: 999),
      ]);
    },
  );

  test(
    'editing replaces the same ID and completion or deletion cancels it',
    () async {
      final platform = _FakePlatform();
      final coordinator = NotificationCoordinator(
        platform: platform,
        tasks: _FakeTasks(const []),
        exams: _FakeExams(const []),
        settings: _FakeSettings(enabled: true),
        now: () => now,
      );
      await coordinator.syncTask(
        id: 8,
        title: 'First title',
        type: CollegeTaskType.assignment,
        reminderAt: now.add(const Duration(hours: 1)),
        completed: false,
      );
      await coordinator.syncTask(
        id: 8,
        title: 'Edited title',
        type: CollegeTaskType.assignment,
        reminderAt: now.add(const Duration(hours: 2)),
        completed: false,
      );
      expect(platform.scheduled, hasLength(1));
      expect(platform.scheduled[8]!.body, 'Edited title');

      await coordinator.syncTask(
        id: 8,
        title: 'Edited title',
        type: CollegeTaskType.assignment,
        reminderAt: now.add(const Duration(hours: 2)),
        completed: true,
      );
      await coordinator.cancel(NotificationEntityType.exam, 4);
      expect(platform.cancelled, [
        (type: NotificationEntityType.task, id: 8),
        (type: NotificationEntityType.exam, id: 4),
      ]);
    },
  );

  test(
    'permission is requested only on explicit enable and disable clears pending',
    () async {
      final platform = _FakePlatform()
        ..allowed = false
        ..permissionResult = true
        ..pendingItems.addAll([
          (id: 1, payload: 'task:1'),
          (id: -2, payload: 'exam:2'),
          (id: 77, payload: 'another-app'),
        ]);
      final settings = _FakeSettings(enabled: false);
      final coordinator = NotificationCoordinator(
        platform: platform,
        tasks: _FakeTasks(const []),
        exams: _FakeExams(const []),
        settings: settings,
        now: () => now,
      );

      expect(await coordinator.enableWithPermission(), isTrue);
      expect(platform.permissionRequests, 1);
      expect(platform.exactAlarmPermissionRequests, 1);
      expect((await settings.get()).notificationsEnabled, isTrue);
      await coordinator.disable();
      expect((await settings.get()).notificationsEnabled, isFalse);
      expect(platform.cancelled, [
        (type: NotificationEntityType.task, id: 1),
        (type: NotificationEntityType.exam, id: 2),
      ]);
    },
  );

  test(
    'test notification requests permission and displays immediately',
    () async {
      final platform = _FakePlatform()
        ..allowed = false
        ..permissionResult = true;
      final coordinator = NotificationCoordinator(
        platform: platform,
        tasks: _FakeTasks(const []),
        exams: _FakeExams(const []),
        settings: _FakeSettings(enabled: false),
        now: () => now,
      );

      expect(await coordinator.sendTestNotification(), isTrue);
      expect(platform.permissionRequests, 1);
      expect(platform.testNotifications, 1);
    },
  );

  test('blocked channel does not falsely report a successful test', () async {
    final platform = _FakePlatform()
      ..allowed = false
      ..permissionResult = true
      ..permissionChangesAllowed = false;
    final settings = _FakeSettings(enabled: true);
    final coordinator = NotificationCoordinator(
      platform: platform,
      tasks: _FakeTasks(const []),
      exams: _FakeExams(const []),
      settings: settings,
      now: () => now,
    );

    expect(await coordinator.sendTestNotification(), isFalse);
    expect(platform.permissionRequests, 1);
    expect(platform.testNotifications, 0);
    expect((await settings.get()).notificationsEnabled, isTrue);
  });

  test('final Android state wins over a stale permission result', () async {
    final platform = _FakePlatform()
      ..allowed = false
      ..permissionResult = false
      ..allowedAfterPermissionRequest = true;
    final settings = _FakeSettings(enabled: false);
    final coordinator = NotificationCoordinator(
      platform: platform,
      tasks: _FakeTasks(const []),
      exams: _FakeExams(const []),
      settings: settings,
      now: () => now,
    );

    expect(await coordinator.sendTestNotification(), isTrue);
    expect(platform.permissionRequests, 1);
    expect(platform.testNotifications, 1);
    expect((await settings.get()).notificationsEnabled, isTrue);
  });

  test(
    'startup schedules enabled reminders despite a false OEM probe',
    () async {
      final platform = _FakePlatform()..allowed = false;
      final coordinator = NotificationCoordinator(
        platform: platform,
        tasks: _FakeTasks([
          _task(id: 9, reminder: now.add(const Duration(hours: 1))),
        ]),
        exams: _FakeExams(const []),
        settings: _FakeSettings(enabled: true),
        now: () => now,
      );

      await coordinator.initialize((_) {});

      expect(platform.permissionRequests, 0);
      expect(platform.scheduled, contains(9));
    },
  );
}

final class _FakePlatform implements NotificationPlatform {
  bool allowed = true;
  bool permissionResult = true;
  bool permissionChangesAllowed = true;
  bool? allowedAfterPermissionRequest;
  int permissionRequests = 0;
  int exactAlarmPermissionRequests = 0;
  int testNotifications = 0;
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
    if (permissionChangesAllowed) {
      allowed = allowedAfterPermissionRequest ?? permissionResult;
    }
    return permissionResult;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    exactAlarmPermissionRequests++;
    return true;
  }

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> showTestNotification() async {
    testNotifications++;
  }

  @override
  Future<void> schedule(CollegeOsNotification notification) async {
    scheduled[notificationId(notification.type, notification.entityId)] =
        notification;
  }

  @override
  Future<void> cancel(NotificationEntityType type, int entityId) async {
    cancelled.add((type: type, id: entityId));
    scheduled.remove(notificationId(type, entityId));
    pendingItems.removeWhere(
      (item) => item.id == notificationId(type, entityId),
    );
  }

  @override
  Future<List<PendingCollegeOsNotification>> pending() async =>
      List.of(pendingItems);
}

final class _FakeSettings implements SettingsRepository {
  _FakeSettings({required bool enabled})
    : _value = (
        studentName: 'Test Student',
        collegeName: 'College',
        course: 'B.Tech',
        branch: 'CSE',
        academicYearStartDate: DateTime(2026, 8, 1),
        academicYearEndDate: DateTime(2027, 4, 30),
        defaultAttendanceTarget: 0.75,
        themeMode: CollegeThemeMode.system,
        onboardingCompleted: true,
        notificationsEnabled: enabled,
        automaticLocalBackup: true,
      );

  CollegeSettings _value;

  @override
  Future<CollegeSettings> get() async => _value;

  @override
  Future<void> save(CollegeSettings settings) async => _value = settings;

  @override
  Stream<CollegeSettings> watch() => Stream.value(_value);
}

final class _FakeTasks implements TaskRepository {
  _FakeTasks(this.values);
  final List<CollegeTask> values;

  @override
  Future<List<CollegeTask>> getAllWithReminders() async => values;
  @override
  Future<int> create(NewCollegeTask task) => throw UnimplementedError();
  @override
  Future<void> delete(int id) => throw UnimplementedError();
  @override
  Future<void> setCompleted(int id, {required bool completed}) =>
      throw UnimplementedError();
  @override
  Future<void> update(CollegeTask task) => throw UnimplementedError();
  @override
  Stream<List<CollegeTask>> watchForSemester(
    int semesterId, {
    bool? completed,
  }) => throw UnimplementedError();
}

final class _FakeExams implements ExamRepository {
  _FakeExams(this.values);
  final List<Exam> values;

  @override
  Future<List<Exam>> getAllWithReminders() async => values;
  @override
  Future<int> create(NewExam exam) => throw UnimplementedError();
  @override
  Future<void> delete(int id) => throw UnimplementedError();
  @override
  Future<void> update(Exam exam) => throw UnimplementedError();
  @override
  Stream<List<Exam>> watchForSemester(int semesterId) =>
      throw UnimplementedError();
}

CollegeOsNotification _classReminder({
  required int id,
  required int minutesBefore,
}) => (
  type: NotificationEntityType.classReminder,
  entityId: id,
  title: 'Class $id',
  body: 'Starts soon',
  scheduledAt: DateTime.utc(2026, 8, 13, 11).add(
    Duration(minutes: minutesBefore),
  ),
);

CollegeTask _task({
  required int id,
  required DateTime reminder,
  bool completed = false,
}) => (
  id: id,
  semesterId: 1,
  subjectId: null,
  title: 'Task $id',
  description: '',
  type: CollegeTaskType.assignment,
  priority: TaskPriority.medium,
  dueDate: reminder,
  dueTime: null,
  reminderAt: reminder,
  isCompleted: completed,
  completedAt: completed ? reminder : null,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

Exam _exam({required int id, required DateTime reminder}) => (
  id: id,
  semesterId: 1,
  subjectId: 1,
  name: 'Exam $id',
  examType: 'Written',
  examDate: reminder,
  startTime: 600,
  endTime: 720,
  room: '',
  syllabus: '',
  maxMarks: null,
  obtainedMarks: null,
  reminderAt: reminder,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);
