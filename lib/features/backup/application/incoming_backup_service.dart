import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class IncomingBackupEvent {
  const IncomingBackupEvent();
}

final class IncomingBackupFile extends IncomingBackupEvent {
  const IncomingBackupFile(this.path);

  final String path;
}

final class IncomingBackupFailure extends IncomingBackupEvent {
  const IncomingBackupFailure(this.message);

  final String message;
}

final incomingBackupServiceProvider = Provider<IncomingBackupService>((ref) {
  final service = IncomingBackupService();
  ref.onDispose(service.dispose);
  return service;
});

final class IncomingBackupService {
  IncomingBackupService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.collegeos.app/incoming_backup';

  final MethodChannel _channel;
  final _events = StreamController<IncomingBackupEvent>.broadcast();
  final _deliveredPaths = <String>{};
  bool _initialized = false;

  Stream<IncomingBackupEvent> get events => _events.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleNativeCall);
    try {
      final path = await _channel.invokeMethod<String>('takePendingBackup');
      if (path != null && path.isNotEmpty) {
        _emitPath(path);
      }
    } on MissingPluginException {
      // Native file intents are Android-only. Other platforms keep the picker.
    } on PlatformException catch (error) {
      _events.add(
        IncomingBackupFailure(
          error.message ?? 'CollegeOS could not open that backup file.',
        ),
      );
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'incomingBackup':
        final path = call.arguments;
        if (path is String && path.isNotEmpty) {
          _emitPath(path);
          unawaited(
            _channel
                .invokeMethod<void>('acknowledgeBackup', {'path': path})
                .catchError((_) {}),
          );
        }
      case 'incomingBackupError':
        _events.add(
          IncomingBackupFailure(
            call.arguments is String
                ? call.arguments as String
                : 'CollegeOS could not open that backup file.',
          ),
        );
    }
  }

  void _emitPath(String path) {
    if (_deliveredPaths.add(path)) {
      _events.add(IncomingBackupFile(path));
    }
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}
