import 'dart:io';

import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/features/feedback/application/feedback_providers.dart';
import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/data/feedback_local_store.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:college_os/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:college_os/features/feedback/presentation/screens/my_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The form files a report, then My feedback shows it with the reply.
///
/// The disk store and the HTTP client are replaced by in-memory fakes so the
/// screens run on the test's fake clock; both real ones are covered by
/// feedback_queue_test.dart and feedback_api_client_test.dart.
void main() {
  late _MemoryStore store;
  late _FakeApi api;

  setUp(() {
    store = _MemoryStore();
    api = _FakeApi();
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: RoutePaths.feedback,
      routes: [
        GoRoute(
          path: RoutePaths.feedback,
          builder: (context, state) => const FeedbackScreen(),
        ),
        GoRoute(
          path: RoutePaths.myFeedback,
          builder: (context, state) => const MyFeedbackScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        feedbackLocalStoreProvider.overrideWithValue(store),
        feedbackApiClientProvider.overrideWithValue(api),
        feedbackDeviceInfoProvider.overrideWith(
          (ref) async => const FeedbackDeviceInfo(
            appVersion: '1.15.0+36',
            deviceModel: 'Google Pixel 8',
            androidVersion: '15 (SDK 35)',
          ),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('sends a report and shows its status and reply', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    api.mine = [
      FeedbackItem(
        id: 'fb_1',
        createdAt: DateTime.utc(2026, 11, 1, 9),
        type: FeedbackType.idea,
        message: 'Please add a weekly view',
        rating: 5,
        status: FeedbackStatus.planned,
        adminReply: 'Great idea, coming in 1.16!',
        repliedAt: DateTime.utc(2026, 11, 1, 10),
      ),
    ];

    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('Included with your report'), findsOneWidget);
    expect(find.text('Google Pixel 8'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('feedback_send')))
          .onPressed,
      isNull,
      reason: 'nothing to send yet',
    );

    await tester.tap(find.byKey(const Key('feedback_type_idea')));
    await tester.enterText(
      find.byKey(const Key('feedback_message')),
      '  Please add a weekly view ',
    );
    await tester.tap(find.byKey(const Key('feedback_star_5')));
    await tester.tap(find.byKey(const Key('feedback_include_device')));
    await tester.pump();
    expect(find.text('Not included'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('feedback_send')));
    await settle(tester);

    expect(find.byKey(const Key('feedback_sent')), findsOneWidget);
    final sent = api.submitted.single;
    expect(sent.type, FeedbackType.idea);
    expect(sent.message, 'Please add a weekly view');
    expect(sent.rating, 5);
    expect(sent.appVersion, '1.15.0+36');
    expect(sent.deviceModel, isNull);
    expect(sent.androidVersion, isNull);
    expect(store.queue, isEmpty);

    await tester.tap(find.text('View my feedback'));
    await settle(tester);

    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Great idea, coming in 1.16!'), findsOneWidget);
  });

  testWidgets('offline sends are saved and shown as waiting', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    api.offline = true;

    await tester.pumpWidget(app());
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('feedback_message')),
      'Crash on rotate',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('feedback_send')));
    await settle(tester);

    expect(find.byKey(const Key('feedback_queued')), findsOneWidget);
    expect(store.queue.single.message, 'Crash on rotate');

    await tester.tap(find.text('View my feedback'));
    await settle(tester);

    expect(find.text('Waiting to send'), findsOneWidget);
    expect(find.text('Crash on rotate'), findsOneWidget);
  });

  testWidgets('a refused report keeps the text and shows why', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    api.refusal = 'Message looks like spam.';

    await tester.pumpWidget(app());
    await settle(tester);
    await tester.enterText(find.byKey(const Key('feedback_message')), 'hello');
    await tester.pump();
    await tester.tap(find.byKey(const Key('feedback_send')));
    await settle(tester);

    expect(find.text('Message looks like spam.'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(store.queue, isEmpty);
  });

  testWidgets(
    'sending anonymously disables and clears name and contact, and sends neither',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      store.lastName = 'Asha';

      await tester.pumpWidget(app());
      await settle(tester);

      TextField field(String key) =>
          tester.widget<TextField>(find.byKey(Key(key)));
      expect(
        field('feedback_name').controller!.text,
        'Asha',
        reason: 'the last name is offered again',
      );
      expect(field('feedback_name').enabled, isTrue);
      expect(find.byKey(const Key('feedback_anonymous_note')), findsNothing);
      expect(
        find.text(
          'Device info is still included unless you turn it off below.',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('feedback_contact')),
        'asha@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('feedback_message')),
        'Exam reminders fire twice',
      );
      await tester.tap(find.byKey(const Key('feedback_anonymous')));
      await tester.pump();

      expect(field('feedback_name').enabled, isFalse);
      expect(field('feedback_contact').enabled, isFalse);
      expect(field('feedback_name').controller!.text, isEmpty);
      expect(field('feedback_contact').controller!.text, isEmpty);
      expect(find.byKey(const Key('feedback_anonymous_note')), findsOneWidget);
      expect(find.text("Your name and contact won't be sent."), findsOneWidget);
      // Device details stay independent of the anonymous switch.
      expect(find.text('Google Pixel 8'), findsOneWidget);

      await tester.tap(find.byKey(const Key('feedback_send')));
      await settle(tester);

      final sent = api.submitted.single;
      expect(sent.anonymous, isTrue);
      expect(sent.name, isNull);
      expect(sent.contact, isNull);
      expect(sent.deviceModel, 'Google Pixel 8');
      expect(store.lastName, 'Asha', reason: 'anonymous never saves a name');
    },
  );

  testWidgets('switching anonymous off brings the name back; a named report '
      'remembers it and My feedback says who sent what', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    api.mine = [
      FeedbackItem(
        id: 'fb_named',
        createdAt: DateTime.utc(2026, 11, 1, 9),
        type: FeedbackType.idea,
        message: 'Weekly view please',
        status: FeedbackStatus.received,
        displayName: 'Ravi',
      ),
      FeedbackItem(
        id: 'fb_anon',
        createdAt: DateTime.utc(2026, 11, 1, 8),
        type: FeedbackType.bug,
        message: 'Crash on rotate',
        status: FeedbackStatus.seen,
        anonymous: true,
      ),
    ];

    await tester.pumpWidget(app());
    await settle(tester);

    await tester.enterText(find.byKey(const Key('feedback_name')), ' Ravi ');
    await tester.tap(find.byKey(const Key('feedback_anonymous')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('feedback_anonymous')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback_name')))
          .controller!
          .text,
      'Ravi',
    );

    await tester.enterText(
      find.byKey(const Key('feedback_message')),
      'Weekly view please',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('feedback_send')));
    await settle(tester);

    final sent = api.submitted.single;
    expect(sent.anonymous, isFalse);
    expect(sent.name, 'Ravi');
    expect(store.lastName, 'Ravi');

    await tester.tap(find.text('View my feedback'));
    await settle(tester);
    expect(find.text('Sent as Ravi'), findsOneWidget);
    expect(find.text('Anonymous'), findsOneWidget);
  });
}

class _FakeApi extends FeedbackApiClient {
  _FakeApi() : super(baseUrls: const []);

  bool offline = false;
  String? refusal;
  List<FeedbackItem> mine = const [];
  final submitted = <QueuedFeedback>[];

  @override
  Future<FeedbackReceipt> submit({
    required FeedbackInstall install,
    required QueuedFeedback feedback,
    List<FeedbackUpload> screenshots = const [],
  }) async {
    if (offline) {
      throw const FeedbackApiException(retryable: true, message: 'offline');
    }
    if (refusal case final message?) {
      throw FeedbackApiException(
        retryable: false,
        statusCode: 400,
        message: message,
      );
    }
    submitted.add(feedback);
    return const FeedbackReceipt(id: 'fb_1', token: 't');
  }

  @override
  Future<List<FeedbackItem>> fetchMine(FeedbackInstall install) async {
    if (offline) {
      throw const FeedbackApiException(retryable: true, message: 'offline');
    }
    return mine;
  }
}

/// Keeps the outbox in memory so the widget test runs on the fake clock.
class _MemoryStore extends FeedbackLocalStore {
  _MemoryStore() : super(() async => Directory('/feedback-test-unused'));

  List<QueuedFeedback> queue = [];
  List<FeedbackItem> mine = [];
  String? lastName;

  @override
  Future<String?> readLastName() async => lastName;

  @override
  Future<void> writeLastName(String? name) async =>
      lastName = cleanFeedbackName(name);

  @override
  Future<FeedbackInstall> loadOrCreateInstall() async => const FeedbackInstall(
    installId: '0f8fad5b-d9cb-469f-a165-70867728950e',
    installToken: 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG',
  );

  @override
  Future<Directory> screenshotDirectory() async =>
      Directory('/feedback-test-unused/shots');

  @override
  Future<bool> hasQueue() async => queue.isNotEmpty;

  @override
  Future<List<QueuedFeedback>> readQueue() async => List.of(queue);

  @override
  Future<void> writeQueue(List<QueuedFeedback> items) async =>
      queue = List.of(items);

  @override
  Future<List<FeedbackItem>> readMineCache() async => mine;

  @override
  Future<void> writeMineCache(List<FeedbackItem> items) async => mine = items;
}
