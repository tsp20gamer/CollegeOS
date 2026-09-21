// Named public constructor parameters intentionally initialize private fields.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:college_os/features/backup/data/recovery_backup_service.dart';

final class AutomaticBackupCoordinator {
  AutomaticBackupCoordinator({
    required RecoveryBackupManager recoveryService,
    required Stream<bool> enabledChanges,
    required Stream<Object?> dataChanges,
    required Future<String> Function() appVersion,
    void Function()? onCreated,
    this.debounceDuration = const Duration(minutes: 5),
  }) : _recoveryService = recoveryService,
       _enabledChanges = enabledChanges,
       _dataChanges = dataChanges,
       _appVersion = appVersion,
       _onCreated = onCreated;

  final RecoveryBackupManager _recoveryService;
  final Stream<bool> _enabledChanges;
  final Stream<Object?> _dataChanges;
  final Future<String> Function() _appVersion;
  final void Function()? _onCreated;
  final Duration debounceDuration;

  StreamSubscription<bool>? _settingsSubscription;
  StreamSubscription<Object?>? _dataSubscription;
  Timer? _debounce;
  bool _enabled = false;
  bool _dirty = false;
  bool _running = false;
  bool _disposed = false;

  void start() {
    if (_settingsSubscription != null) return;
    _settingsSubscription = _enabledChanges.distinct().listen((enabled) {
      _enabled = enabled;
      if (!enabled) {
        _debounce?.cancel();
      } else {
        unawaited(ensureBaseline());
        if (_dirty) _schedule();
      }
    });
    _dataSubscription = _dataChanges.listen((_) {
      _dirty = true;
      if (_enabled) _schedule();
    });
  }

  Future<void> ensureBaseline() async {
    if (!_enabled || _running || _disposed) return;
    try {
      final existing = await _recoveryService.list();
      if (existing.isEmpty) {
        _dirty = true;
        await checkpoint();
      }
    } catch (_) {
      // A platform storage failure must not interrupt app startup. A later
      // data or lifecycle checkpoint will try again.
      _dirty = true;
    }
  }

  Future<void> updateEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      _debounce?.cancel();
      return;
    }
    await ensureBaseline();
    if (_dirty) _schedule();
  }

  Future<void> checkpoint() async {
    _debounce?.cancel();
    if (!_enabled || !_dirty || _running || _disposed) return;
    _running = true;
    try {
      final version = await _appVersion();
      await _recoveryService.create(version);
      _dirty = false;
      _onCreated?.call();
    } catch (_) {
      // Keep dirty state so the next lifecycle checkpoint can retry. Automatic
      // recovery must never interrupt ordinary CollegeOS work.
    } finally {
      _running = false;
    }
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(debounceDuration, () => unawaited(checkpoint()));
  }

  Future<void> dispose() async {
    _disposed = true;
    _debounce?.cancel();
    await _settingsSubscription?.cancel();
    await _dataSubscription?.cancel();
  }
}
