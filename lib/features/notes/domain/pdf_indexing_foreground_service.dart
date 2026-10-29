import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'pdf_indexing_task_handler.dart';

class PdfIndexingForegroundService {
  /// Checks permissions, configures the channel, and starts the service.
  /// If a service is already running, this will do nothing (only one PDF at a time).
  static Future<void> startIndexing(int fileId, String relativeFilePath) async {
    if (!Platform.isAndroid) return;

    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      debugPrint(
        'PdfIndexingForegroundService: already running, skipping start for $fileId',
      );
      return;
    }

    final finished = Completer<void>();
    void onTaskData(Object data) {
      if (data is! Map || data['fileId'] != fileId) return;
      if (data['event'] == 'complete' || data['event'] == 'error') {
        if (!finished.isCompleted) finished.complete();
      }
    }

    FlutterForegroundTask.addTaskDataCallback(onTaskData);

    try {
      // 1. Request required permissions (Android 13+ POST_NOTIFICATIONS)
      final NotificationPermission notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // 2. Initialize the service configuration
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'pdf_indexing',
          channelName: 'PDF Indexing',
          channelDescription: 'Shows progress of background PDF extraction',
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );

      // 3. Save parameters for the TaskHandler to read
      await FlutterForegroundTask.saveData(
        key: 'pdf_file_id',
        value: fileId.toString(),
      );
      await FlutterForegroundTask.saveData(
        key: 'pdf_file_path',
        value: relativeFilePath,
      );

      // 4. Start and wait for this file to finish so a caller can safely queue
      // the next file in the same library pass.
      await FlutterForegroundTask.startService(
        serviceId: 201, // arbitrary unique ID for this service type
        notificationTitle: 'CollegeOS',
        notificationText: 'Preparing to index PDF...',
        callback: pdfIndexingStartCallback,
      );
      final startupWatch = Stopwatch()..start();
      var observedRunning = false;
      while (!finished.isCompleted) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (finished.isCompleted) break;
        final stillRunning = await FlutterForegroundTask.isRunningService;
        if (stillRunning) {
          observedRunning = true;
        } else if (observedRunning ||
            startupWatch.elapsed > const Duration(seconds: 30)) {
          throw StateError('The PDF indexing service stopped unexpectedly.');
        }
      }
      final stopDeadline = DateTime.now().add(const Duration(seconds: 10));
      while (await FlutterForegroundTask.isRunningService &&
          DateTime.now().isBefore(stopDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    } finally {
      FlutterForegroundTask.removeTaskDataCallback(onTaskData);
    }
  }

  /// Sets up a callback in the main isolate to listen for progress updates
  /// sent from the background isolate via `sendDataToMain`.
  static void listenToProgress(void Function(Object data) onData) {
    FlutterForegroundTask.addTaskDataCallback(onData);
  }
}
