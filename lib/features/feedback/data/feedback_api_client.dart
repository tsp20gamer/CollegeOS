import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Where the feedback service answers.
const String feedbackPrimaryBaseUrl =
    'https://feedback-api.collegeos.tspop.cyou';

/// The same service on its workers.dev address, used only when the primary
/// host cannot be reached at all (DNS, TLS or connection failure).
const String feedbackFallbackBaseUrl =
    'https://collegeos-feedback.steja3471.workers.dev';

/// The anonymous identity a report is filed under.
///
/// No account, no name: a random id and a random secret made on this install.
/// The service stores only a hash of the secret, and only someone holding it
/// can read this install's reports and replies.
@immutable
class FeedbackInstall {
  const FeedbackInstall({required this.installId, required this.installToken});

  final String installId;
  final String installToken;
}

/// One screenshot as it is uploaded.
@immutable
class FeedbackUpload {
  const FeedbackUpload({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final List<int> bytes;
  final String mimeType;
  final String fileName;
}

/// What the service answered to a submitted report.
@immutable
class FeedbackReceipt {
  const FeedbackReceipt({
    required this.id,
    required this.token,
    this.attachments = 0,
    this.duplicate = false,
  });

  final String id;
  final String token;
  final int attachments;

  /// True when the service had already filed this report's client id.
  final bool duplicate;
}

/// Why a request did not succeed, and what the queue should do about it.
class FeedbackApiException implements Exception {
  const FeedbackApiException({
    required this.retryable,
    required this.message,
    this.code,
    this.statusCode,
    this.retryAfter,
  });

  /// True for no connection, a timeout, 429 and 5xx: try again later.
  /// False for any other refusal: the report will never be accepted as is.
  final bool retryable;

  /// Readable text for the student.
  final String message;

  /// The service's error code, such as `message_too_long`.
  final String? code;
  final int? statusCode;
  final Duration? retryAfter;

  @override
  String toString() =>
      'FeedbackApiException($statusCode, $code, retryable: $retryable): $message';
}

/// Talks to the CollegeOS feedback service.
///
/// The only requests it makes are the ones the student starts: sending a
/// report and reading the status of their own reports. Nothing is sent in
/// the background unless a report is waiting in the queue.
class FeedbackApiClient {
  FeedbackApiClient({
    this.client,
    List<String> baseUrls = const [
      feedbackPrimaryBaseUrl,
      feedbackFallbackBaseUrl,
    ],
    this.timeout = const Duration(seconds: 30),
  }) : baseUrls = List.unmodifiable(baseUrls);

  /// Injected by tests; the app uses `http`'s one-shot requests instead, as
  /// the updater does.
  final http.Client? client;

  /// Tried in order; the next one only after a connection-level failure.
  final List<String> baseUrls;
  final Duration timeout;

  /// Files one report as multipart form data.
  Future<FeedbackReceipt> submit({
    required FeedbackInstall install,
    required QueuedFeedback feedback,
    List<FeedbackUpload> screenshots = const [],
  }) async {
    final response = await _withFallback((base) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/api/v1/feedback'),
      );
      request.headers.addAll(_headers(install));
      request.fields.addAll({
        'source': 'app',
        'type': feedback.type.wire,
        'message': feedback.message,
        'install_id': install.installId,
        'client_id': feedback.clientId,
        'app_version': feedback.appVersion,
        if (feedback.rating case final rating?) 'rating': '$rating',
        if (feedback.contact case final contact? when contact.isNotEmpty)
          'contact': contact,
        if (feedback.deviceModel case final model? when model.isNotEmpty)
          'device_model': model,
        if (feedback.androidVersion case final version? when version.isNotEmpty)
          'android_version': version,
      });
      for (final shot in screenshots) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'screenshots',
            shot.bytes,
            filename: shot.fileName,
            contentType: MediaType.parse(shot.mimeType),
          ),
        );
      }
      return request;
    });
    final body = _decode(response);
    final id = body['id'];
    final token = body['token'];
    if (id == null || token is! String) {
      throw const FeedbackApiException(
        retryable: true,
        message: 'The feedback service gave an unexpected answer.',
      );
    }
    return FeedbackReceipt(
      id: '$id',
      token: token,
      attachments: (body['attachments'] as num?)?.toInt() ?? 0,
      duplicate: body['duplicate'] == true,
    );
  }

  /// Reads this install's own reports, newest first.
  Future<List<FeedbackItem>> fetchMine(FeedbackInstall install) async {
    final response = await _withFallback(
      (base) => http.Request(
        'GET',
        Uri.parse(
          '$base/api/v1/feedback/mine',
        ).replace(queryParameters: {'install_id': install.installId}),
      )..headers.addAll(_headers(install)),
    );
    final body = _decode(response);
    final items = body['items'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, Object?>) FeedbackItem.fromJson(item),
    ];
  }

  Map<String, String> _headers(FeedbackInstall install) => {
    'Accept': 'application/json',
    'X-Install-Token': install.installToken,
  };

  /// Sends a fresh request to each base URL until one is reachable.
  ///
  /// Only a failure to reach a host moves on to the next one; any HTTP answer,
  /// even an error, is the service speaking and is returned as is.
  Future<http.Response> _withFallback(
    http.BaseRequest Function(String baseUrl) build,
  ) async {
    Object? lastError;
    for (final base in baseUrls) {
      final request = build(base);
      try {
        final client = this.client;
        final streamed =
            await (client == null ? request.send() : client.send(request))
                .timeout(timeout);
        return await http.Response.fromStream(streamed).timeout(timeout);
      } on TimeoutException {
        // The host answered the connection but not in time; another host would
        // reach the same service, so this is a "try later", not a fallback.
        throw const FeedbackApiException(
          retryable: true,
          message: 'The feedback service took too long to answer.',
        );
      } on Object catch (error) {
        if (!_isConnectionFailure(error)) rethrow;
        debugPrint('[Feedback] $base unreachable: $error');
        lastError = error;
      }
    }
    debugPrint('[Feedback] no feedback host reachable: $lastError');
    throw const FeedbackApiException(
      retryable: true,
      message:
          'No internet connection. It will be sent when you are back online.',
    );
  }

  static bool _isConnectionFailure(Object error) =>
      error is http.ClientException ||
      error is SocketException ||
      error is HandshakeException ||
      error is TlsException ||
      error is HttpException;

  Map<String, Object?> _decode(http.Response response) {
    Map<String, Object?>? body;
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, Object?>) body = decoded;
    } on FormatException {
      body = null;
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300 && body != null && body['ok'] != false) {
      return body;
    }

    final code = body?['error'] as String?;
    final serverMessage = body?['message'] as String?;
    final retryAfter = _retryAfter(response, body);
    final retryable =
        status == 429 || status >= 500 || (status >= 200 && status < 300);
    throw FeedbackApiException(
      retryable: retryable,
      statusCode: status,
      code: code,
      retryAfter: retryAfter,
      message: switch (status) {
        429 =>
          'Too many reports in a short time. It will be sent a little later.',
        >= 500 =>
          'The feedback service is having trouble. It will be sent later.',
        _ when serverMessage != null && serverMessage.trim().isNotEmpty =>
          serverMessage.trim(),
        _ => 'The feedback service could not accept this report ($status).',
      },
    );
  }

  static Duration? _retryAfter(
    http.Response response,
    Map<String, Object?>? body,
  ) {
    final seconds =
        (body?['retry_after'] as num?)?.toInt() ??
        int.tryParse(response.headers['retry-after'] ?? '');
    return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
  }
}
