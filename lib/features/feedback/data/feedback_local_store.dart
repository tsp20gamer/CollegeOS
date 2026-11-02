import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:path/path.dart' as p;

/// Keeps feedback state in its own folder inside the app's private storage.
///
/// Feedback lives beside the database rather than in it on purpose: the
/// install identity and unsent reports must never travel inside a backup or
/// be restored onto another phone, and keeping them out of the schema means
/// no migration touches the student's academic data. Each file is replaced
/// atomically (write to a temporary file, then rename), so a crash mid-write
/// leaves the previous version intact.
class FeedbackLocalStore {
  FeedbackLocalStore(this._root, {Random? random})
    : _random = random ?? Random.secure();

  /// The app support directory in the app; a temporary one in tests.
  final Future<Directory> Function() _root;
  final Random _random;

  Future<Directory> _directory() async {
    final directory = Directory(p.join((await _root()).path, 'feedback'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  /// Where queued screenshots are copied, so they survive the picker's cache
  /// being cleared before the report is sent.
  Future<Directory> screenshotDirectory() async {
    final directory = Directory(p.join((await _directory()).path, 'shots'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  /// This install's anonymous identity, made once on first use.
  Future<FeedbackInstall> loadOrCreateInstall() async {
    final file = File(p.join((await _directory()).path, 'install.json'));
    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString());
        if (json
            case {
              'install_id': final String id,
              'install_token': final String token,
            }
            when id.isNotEmpty && token.length >= 32) {
          return FeedbackInstall(installId: id, installToken: token);
        }
      } on FormatException {
        // A damaged identity is replaced; it only links this install to its
        // own earlier reports.
      }
    }
    final install = FeedbackInstall(
      installId: newUuidV4(_random),
      installToken: newInstallSecret(_random),
    );
    await _writeAtomically(
      file,
      jsonEncode({
        'install_id': install.installId,
        'install_token': install.installToken,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return install;
  }

  Future<List<QueuedFeedback>> readQueue() async {
    final file = File(p.join((await _directory()).path, 'queue.json'));
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (entry is Map<String, Object?>) QueuedFeedback.fromJson(entry),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<void> writeQueue(List<QueuedFeedback> queue) async {
    final file = File(p.join((await _directory()).path, 'queue.json'));
    await _writeAtomically(
      file,
      jsonEncode([for (final item in queue) item.toJson()]),
    );
  }

  /// The name the student last sent a report with, offered next time.
  Future<String?> readLastName() async {
    final file = File(p.join((await _directory()).path, 'sender.json'));
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString());
      return json is Map ? cleanFeedbackName(json['name'] as String?) : null;
    } on Object {
      return null;
    }
  }

  /// Remembers [name] for the next report; an empty name forgets it.
  ///
  /// Never called for anonymous reports, so sending one anonymously leaves
  /// the remembered name as it was.
  Future<void> writeLastName(String? name) async {
    final file = File(p.join((await _directory()).path, 'sender.json'));
    final cleaned = cleanFeedbackName(name);
    if (cleaned == null) {
      if (await file.exists()) await file.delete();
      return;
    }
    await _writeAtomically(file, jsonEncode({'name': cleaned}));
  }

  /// The last list of reports read from the service, shown while offline.
  Future<List<FeedbackItem>> readMineCache() async {
    final file = File(p.join((await _directory()).path, 'mine.json'));
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (entry is Map<String, Object?>) FeedbackItem.fromJson(entry),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<void> writeMineCache(List<FeedbackItem> items) async {
    final file = File(p.join((await _directory()).path, 'mine.json'));
    await _writeAtomically(
      file,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }

  /// True when anything is waiting, read without creating the folder, so an
  /// app that never used feedback does no work at launch.
  Future<bool> hasQueue() async {
    final file = File(p.join((await _root()).path, 'feedback', 'queue.json'));
    return file.exists();
  }

  Future<void> _writeAtomically(File file, String contents) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(file.path);
  }
}

/// A random RFC 4122 version 4 UUID.
String newUuidV4([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// 32 random bytes as unpadded base64url (43 characters).
String newInstallSecret([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => source.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
