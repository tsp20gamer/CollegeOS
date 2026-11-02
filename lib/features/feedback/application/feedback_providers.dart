import 'dart:async';
import 'dart:io';

import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/feedback/application/feedback_queue.dart';
import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/data/feedback_local_store.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// The feedback service client. Overridden in tests with a local mock.
final feedbackApiClientProvider = Provider<FeedbackApiClient>(
  (ref) => FeedbackApiClient(),
);

/// Where feedback files live. Overridden in tests with a temporary folder.
final feedbackLocalStoreProvider = Provider<FeedbackLocalStore>(
  (ref) => FeedbackLocalStore(getApplicationSupportDirectory),
);

final feedbackQueueProvider = Provider<FeedbackQueue>((ref) {
  final queue = FeedbackQueue(
    store: ref.watch(feedbackLocalStoreProvider),
    api: ref.watch(feedbackApiClientProvider),
  );
  ref.onDispose(queue.dispose);
  return queue;
});

/// The version, device and Android release shown before a report is sent.
final feedbackDeviceInfoProvider = FutureProvider<FeedbackDeviceInfo>((
  ref,
) async {
  final version = await ref.watch(appVersionProvider.future);
  String? model;
  String? android;
  try {
    if (!kIsWeb && Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final maker = info.manufacturer.trim();
      final name = info.model.trim();
      model = name.toLowerCase().startsWith(maker.toLowerCase())
          ? name
          : '${_capitalize(maker)} $name'.trim();
      android = '${info.version.release} (SDK ${info.version.sdkInt})';
    }
  } catch (error) {
    debugPrint('[Feedback] device info unavailable: $error');
  }
  return FeedbackDeviceInfo(
    appVersion: version,
    deviceModel: model,
    androidVersion: android,
  );
});

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// Reports still on this phone: waiting to send, or refused.
final queuedFeedbackProvider = StreamProvider<List<QueuedFeedback>>((
  ref,
) async* {
  final queue = ref.watch(feedbackQueueProvider);
  yield await _safeItems(queue);
  await for (final _ in queue.changes) {
    yield await _safeItems(queue);
  }
});

Future<List<QueuedFeedback>> _safeItems(FeedbackQueue queue) async {
  try {
    final items = await queue.items();
    return items.reversed.toList();
  } catch (_) {
    return const [];
  }
}

/// The student's reports as the service holds them.
@immutable
class MyFeedbackState {
  const MyFeedbackState({
    required this.items,
    this.offline = false,
    this.message,
  });

  final List<FeedbackItem> items;

  /// True when the list is the last copy saved on the phone.
  final bool offline;
  final String? message;
}

final myFeedbackProvider =
    AsyncNotifierProvider<MyFeedbackController, MyFeedbackState>(
      MyFeedbackController.new,
    );

final class MyFeedbackController extends AsyncNotifier<MyFeedbackState> {
  @override
  Future<MyFeedbackState> build() => _load();

  Future<void> refresh() async {
    state = AsyncData(await _load());
  }

  Future<MyFeedbackState> _load() async {
    final store = ref.read(feedbackLocalStoreProvider);
    final queue = ref.read(feedbackQueueProvider);
    // Anything still waiting goes first, so the list reflects it.
    await queue.flush(force: true);
    try {
      final install = await store.loadOrCreateInstall();
      final items = await ref
          .read(feedbackApiClientProvider)
          .fetchMine(install);
      unawaited(store.writeMineCache(items).catchError((_) {}));
      return MyFeedbackState(items: items);
    } on FeedbackApiException catch (error) {
      final cached = await _cached(store);
      return MyFeedbackState(
        items: cached,
        offline: true,
        message: error.retryable
            ? 'Offline — showing what was saved on this phone.'
            : error.message,
      );
    } catch (error) {
      debugPrint('[Feedback] could not read my feedback: $error');
      return MyFeedbackState(
        items: await _cached(store),
        offline: true,
        message: 'Could not load replies right now.',
      );
    }
  }

  Future<List<FeedbackItem>> _cached(FeedbackLocalStore store) async {
    try {
      return await store.readMineCache();
    } catch (_) {
      return const [];
    }
  }
}

/// What the form is doing.
enum FeedbackFormPhase { editing, sending, sent, queued }

@immutable
class FeedbackFormState {
  const FeedbackFormState({this.phase = FeedbackFormPhase.editing, this.error});

  final FeedbackFormPhase phase;

  /// The service's reason when it refused the report; the form keeps the text.
  final String? error;
}

final feedbackSubmitControllerProvider =
    NotifierProvider.autoDispose<FeedbackSubmitController, FeedbackFormState>(
      FeedbackSubmitController.new,
    );

final class FeedbackSubmitController extends Notifier<FeedbackFormState> {
  @override
  FeedbackFormState build() => const FeedbackFormState();

  /// Saves the report to the outbox, then tries to send it straight away.
  Future<FeedbackSendOutcome> submit(FeedbackDraft draft) async {
    state = const FeedbackFormState(phase: FeedbackFormPhase.sending);
    final queue = ref.read(feedbackQueueProvider);
    try {
      if (!draft.anonymous) {
        // A convenience only; a failure here must not stop the report.
        try {
          await ref.read(feedbackLocalStoreProvider).writeLastName(draft.name);
        } catch (error) {
          debugPrint('[Feedback] could not remember the name: $error');
        }
      }
      final item = await queue.enqueue(draft);
      final result = await queue.sendNow(item.clientId);
      if (!ref.mounted) return result.outcome;
      switch (result.outcome) {
        case FeedbackSendOutcome.sent:
          state = const FeedbackFormState(phase: FeedbackFormPhase.sent);
          ref.invalidate(myFeedbackProvider);
        case FeedbackSendOutcome.queued:
          state = const FeedbackFormState(phase: FeedbackFormPhase.queued);
        case FeedbackSendOutcome.rejected:
          // The form still holds the words, so the refused copy is not kept.
          await queue.discard(item.clientId);
          if (!ref.mounted) return result.outcome;
          state = FeedbackFormState(
            error: result.message ?? 'The report could not be sent.',
          );
      }
      return result.outcome;
    } catch (error) {
      debugPrint('[Feedback] could not save report: $error');
      if (ref.mounted) {
        state = const FeedbackFormState(
          error: 'Could not save the report on this phone. Please try again.',
        );
      }
      return FeedbackSendOutcome.rejected;
    }
  }

  void reset() => state = const FeedbackFormState();
}
