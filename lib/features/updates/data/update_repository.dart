import 'dart:async';
import 'dart:convert';

import 'package:college_os/features/updates/domain/update_info.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Where the release manifest is published.
///
/// The file lives at the repository root and the release workflow rewrites it on
/// every tag, so `main` always describes the newest published build. The check
/// therefore needs no API key and reveals nothing about the student.
const String defaultUpdateManifestUrl =
    'https://raw.githubusercontent.com/tsp20gamer/CollegeOS/main/version.json';

/// Reads the release manifest.
///
/// This is the only request CollegeOS makes that the student did not ask for
/// content from: it fetches a public file describing the newest published build.
/// No user data, no identifiers and no analytics are involved, the APK is
/// downloaded only after the student taps Update, and every failure is a
/// [UpdateCheckFailure] the caller reports or swallows — never an error that
/// interrupts using the app offline.
class UpdateRepository {
  const UpdateRepository({
    this.client,
    this.manifestUrl = defaultUpdateManifestUrl,
    this.timeout = const Duration(seconds: 10),
  });

  /// Injected by tests; the app reuses `http`'s one-shot request instead.
  final http.Client? client;

  /// The published manifest's location.
  final String manifestUrl;

  /// How long a request may take before it counts as unreachable.
  final Duration timeout;

  /// Fetches the newest published release.
  ///
  /// Throws [UpdateCheckFailure] when the manifest cannot be read: offline,
  /// timed out, an unexpected status, or a manifest this build cannot use.
  Future<UpdateInfo> fetchLatest() async {
    // GitHub serves raw files through a cache, and a release must be visible as
    // soon as it is published, so the request carries a cache-busting stamp.
    final uri = Uri.parse(manifestUrl).replace(
      queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
    );

    final http.Response response;
    try {
      final client = this.client;
      response = await (client == null ? http.get(uri) : client.get(uri))
          .timeout(timeout);
    } on TimeoutException {
      throw const UpdateCheckFailure(
        'The update check timed out. Try again when you have a connection.',
      );
    } catch (error) {
      debugPrint('[UpdateService] manifest request failed: $error');
      throw const UpdateCheckFailure(
        'Could not reach the update server. Check your connection and try again.',
      );
    }

    if (response.statusCode != 200) {
      throw UpdateCheckFailure(
        'The update server answered ${response.statusCode}. Try again later.',
      );
    }

    final Object? decoded;
    try {
      // Decoded from bytes as UTF-8: the manifest's changelog carries bullets,
      // and the response charset is not guaranteed to say so.
      decoded = json.decode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      debugPrint('[UpdateService] manifest is not JSON: $error');
      throw const UpdateCheckFailure(
        'The published release manifest is not readable.',
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw const UpdateCheckFailure(
        'The published release manifest is not readable.',
      );
    }

    try {
      return UpdateInfo.fromJson(decoded);
    } on UpdateManifestFailure catch (failure) {
      debugPrint('[UpdateService] manifest rejected: ${failure.reason}');
      throw const UpdateCheckFailure(
        'The published release manifest is incomplete, so no update can be '
        'offered right now.',
      );
    }
  }
}
