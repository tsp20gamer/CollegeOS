import 'dart:async';
import 'dart:io';

import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/data/feedback_local_store.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// A report the student has written, before it is queued.
@immutable
class FeedbackDraft {
  const FeedbackDraft({
    required this.type,
    required this.message,
    required this.device,
    this.includeDeviceInfo = true,
    this.rating,
    this.contact,
    this.name,
    this.anonymous = false,
    this.screenshots = const [],
  });

  final FeedbackType type;
  final String message;
  final int? rating;
  final String? contact;

  /// Optional; ignored when [anonymous] is on.
  final String? name;

  /// Send with no name and no contact.
  final bool anonymous;
  final FeedbackDeviceInfo device;
  final bool includeDeviceInfo;

  /// Already-compressed screenshots.
  final List<FeedbackUpload> screenshots;
}

/// What happened to one report on one attempt.
enum FeedbackSendOutcome {
  /// The service filed it; it has left the queue.
  sent,

  /// Not reachable or busy; it stays queued for the next attempt.
  queued,

  /// The service refused it for good.
  rejected,
}

@immutable
class FeedbackSendResult {
  const FeedbackSendResult(this.outcome, {this.receipt, this.message});

  final FeedbackSendOutcome outcome;
  final FeedbackReceipt? receipt;
  final String? message;
}

@immutable
class FeedbackFlushResult {
  const FeedbackFlushResult({this.sent = 0, this.kept = 0, this.rejected = 0});

  final int sent;
  final int kept;
  final int rejected;
}

/// The on-device outbox for feedback.
///
/// Every report is saved before the first attempt and leaves the outbox only
/// once the service has filed it. A connection problem, a timeout, 429 or a
/// 5xx keeps it for later; any other refusal marks it as not sent, with the
/// service's reason, and frees its screenshots. Attempts never overlap, so a
/// launch retry and a tap on Send cannot file the same report twice — and if a
/// response is lost anyway, the report's client id lets the service answer
/// with the report it already has.
class FeedbackQueue {
  FeedbackQueue({
    required this.store,
    required this.api,
    DateTime Function()? clock,
    String Function()? newClientId,
  }) : _clock = clock ?? DateTime.now,
       _newClientId = newClientId ?? newUuidV4;

  final FeedbackLocalStore store;
  final FeedbackApiClient api;
  final DateTime Function() _clock;
  final String Function() _newClientId;

  Future<void> _lock = Future.value();

  final _changes = StreamController<void>.broadcast();

  /// Fires after the outbox changes, so lists can reload.
  Stream<void> get changes => _changes.stream;

  /// Runs [action] after every earlier outbox operation has finished.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<List<QueuedFeedback>> items() => store.readQueue();

  /// Saves a draft to the outbox and returns it, without sending.
  ///
  /// [clientId] lets a caller re-enqueue the same report idempotently.
  Future<QueuedFeedback> enqueue(FeedbackDraft draft, {String? clientId}) =>
      _serialized(() async {
        final id = clientId ?? _newClientId();
        final queue = await store.readQueue();
        final existing = queue.where((item) => item.clientId == id).firstOrNull;
        if (existing != null) return existing;

        final directory = await store.screenshotDirectory();
        final names = <String>[];
        for (final (index, shot) in draft.screenshots.indexed) {
          final name = '${id}_$index${_extension(shot.mimeType)}';
          await File(p.join(directory.path, name))
              .writeAsBytes(shot.bytes, flush: true);
          names.add(name);
        }

        final contact = draft.anonymous ? null : draft.contact?.trim();
        final item = QueuedFeedback(
          clientId: id,
          createdAt: _clock().toUtc(),
          type: draft.type,
          message: draft.message.trim(),
          rating: draft.rating,
          contact: contact == null || contact.isEmpty ? null : contact,
          name: draft.anonymous ? null : cleanFeedbackName(draft.name),
          anonymous: draft.anonymous,
          appVersion: draft.device.appVersion,
          deviceModel: draft.includeDeviceInfo
              ? draft.device.deviceModel
              : null,
          androidVersion: draft.includeDeviceInfo
              ? draft.device.androidVersion
              : null,
          screenshots: names,
        );
        await store.writeQueue([...queue, item]);
        _changes.add(null);
        return item;
      });

  /// Sends one queued report now, whatever its retry time.
  Future<FeedbackSendResult> sendNow(String clientId) => _serialized(() async {
    final queue = await store.readQueue();
    final item = queue.where((entry) => entry.clientId == clientId).firstOrNull;
    if (item == null) {
      return const FeedbackSendResult(FeedbackSendOutcome.sent);
    }
    return _attempt(item);
  });

  /// Tries every pending report whose retry time has come.
  ///
  /// Never throws: the outbox is a convenience that must not disturb launch.
  Future<FeedbackFlushResult> flush({bool force = false}) => _serialized(
    () async {
      try {
        if (!await store.hasQueue()) return const FeedbackFlushResult();
        final now = _clock();
        final due = (await store.readQueue()).where(
          (item) =>
              item.state == QueuedFeedbackState.pending &&
              (force ||
                  item.nextAttemptAt == null ||
                  !item.nextAttemptAt!.isAfter(now)),
        );
        var sent = 0, kept = 0, rejected = 0;
        for (final item in due.toList()) {
          final result = await _attempt(item);
          switch (result.outcome) {
            case FeedbackSendOutcome.sent:
              sent++;
            case FeedbackSendOutcome.queued:
              kept++;
              // The host is unreachable or busy; the rest would fail alike.
              return FeedbackFlushResult(
                sent: sent,
                kept: kept,
                rejected: rejected,
              );
            case FeedbackSendOutcome.rejected:
              rejected++;
          }
        }
        return FeedbackFlushResult(sent: sent, kept: kept, rejected: rejected);
      } catch (error) {
        debugPrint('[Feedback] outbox flush failed: $error');
        return const FeedbackFlushResult();
      }
    },
  );

  /// Removes a report the student no longer wants, sent or not.
  Future<void> discard(String clientId) => _serialized(() async {
    final queue = await store.readQueue();
    final item = queue.where((entry) => entry.clientId == clientId).firstOrNull;
    if (item == null) return;
    await _deleteScreenshots(item);
    await store.writeQueue([
      for (final entry in queue)
        if (entry.clientId != clientId) entry,
    ]);
    _changes.add(null);
  });

  Future<FeedbackSendResult> _attempt(QueuedFeedback item) async {
    try {
      final install = await store.loadOrCreateInstall();
      final uploads = await _uploads(item);
      final receipt = await api.submit(
        install: install,
        feedback: item,
        screenshots: uploads,
      );
      await _replace(item.clientId, null);
      await _deleteScreenshots(item);
      return FeedbackSendResult(FeedbackSendOutcome.sent, receipt: receipt);
    } on FeedbackApiException catch (error) {
      if (error.retryable) {
        await _replace(
          item.clientId,
          item.copyWith(
            attempts: item.attempts + 1,
            lastError: error.message,
            nextAttemptAt: error.retryAfter == null
                ? null
                : _clock().add(error.retryAfter!),
            clearNextAttempt: error.retryAfter == null,
          ),
        );
        return FeedbackSendResult(
          FeedbackSendOutcome.queued,
          message: error.message,
        );
      }
      await _deleteScreenshots(item);
      await _replace(
        item.clientId,
        item.copyWith(
          state: QueuedFeedbackState.failed,
          attempts: item.attempts + 1,
          lastError: error.message,
          screenshots: const [],
          clearNextAttempt: true,
        ),
      );
      return FeedbackSendResult(
        FeedbackSendOutcome.rejected,
        message: error.message,
      );
    } on Object catch (error) {
      // Anything unexpected (a malformed answer, a file problem) keeps the
      // report: losing what the student wrote is the one outcome to avoid.
      debugPrint('[Feedback] attempt failed: $error');
      await _replace(
        item.clientId,
        item.copyWith(
          attempts: item.attempts + 1,
          lastError: 'Could not send yet. It will be tried again.',
        ),
      );
      return const FeedbackSendResult(
        FeedbackSendOutcome.queued,
        message: 'Could not send yet. It will be tried again.',
      );
    }
  }

  Future<List<FeedbackUpload>> _uploads(QueuedFeedback item) async {
    final directory = await store.screenshotDirectory();
    final uploads = <FeedbackUpload>[];
    for (final name in item.screenshots) {
      final file = File(p.join(directory.path, name));
      if (!await file.exists()) continue;
      uploads.add(
        FeedbackUpload(
          bytes: await file.readAsBytes(),
          mimeType: _mimeType(name),
          fileName: name,
        ),
      );
    }
    return uploads;
  }

  /// Writes [replacement] in place of the item, or removes it when null.
  Future<void> _replace(String clientId, QueuedFeedback? replacement) async {
    final queue = await store.readQueue();
    await store.writeQueue([
      for (final entry in queue)
        if (entry.clientId != clientId) entry else ?replacement,
    ]);
    _changes.add(null);
  }

  Future<void> _deleteScreenshots(QueuedFeedback item) async {
    final directory = await store.screenshotDirectory();
    for (final name in item.screenshots) {
      try {
        await File(p.join(directory.path, name)).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  Future<void> dispose() => _changes.close();

  static String _extension(String mimeType) => switch (mimeType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => '.jpg',
  };

  static String _mimeType(String name) => switch (p.extension(name)) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
