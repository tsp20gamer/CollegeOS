import 'package:flutter/foundation.dart';

/// The longest message the feedback service accepts, after trimming.
const int feedbackMessageMaxLength = 3000;

/// The longest optional contact the feedback service accepts.
const int feedbackContactMaxLength = 200;

/// The longest optional name the feedback service accepts.
const int feedbackNameMaxLength = 60;

/// Trims [value], drops control characters and caps it at
/// [feedbackNameMaxLength]; null when nothing is left.
String? cleanFeedbackName(String? value) {
  if (value == null) return null;
  final cleaned = value
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return null;
  final runes = cleaned.runes.toList();
  return runes.length <= feedbackNameMaxLength
      ? cleaned
      : String.fromCharCodes(runes.take(feedbackNameMaxLength)).trim();
}

/// Reads the service's anonymous flag, sent as 0/1, true/false or "1"/"0".
bool _readFlag(Object? value) => switch (value) {
  final bool flag => flag,
  final num number => number != 0,
  final String text => text == '1' || text.toLowerCase() == 'true',
  _ => false,
};

/// How many screenshots one report may carry.
const int feedbackMaxScreenshots = 3;

/// The largest screenshot the service accepts, after client compression.
const int feedbackMaxScreenshotBytes = 1536 * 1024;

/// What a report is about.
enum FeedbackType {
  bug('bug', 'Bug'),
  idea('idea', 'Idea'),
  other('other', 'Other');

  const FeedbackType(this.wire, this.label);

  /// The value the feedback service expects.
  final String wire;

  /// What the student reads on the chip.
  final String label;

  static FeedbackType fromWire(String? value) => FeedbackType.values.firstWhere(
    (type) => type.wire == value,
    orElse: () => FeedbackType.other,
  );
}

/// Where the developer has taken a report.
enum FeedbackStatus {
  received('new', 'Received'),
  seen('seen', 'Seen'),
  planned('planned', 'Planned'),
  inProgress('in_progress', 'In progress'),
  done('done', 'Done'),
  wontFix('wont_fix', 'Not planned');

  const FeedbackStatus(this.wire, this.label);

  final String wire;
  final String label;

  static FeedbackStatus fromWire(String? value) =>
      FeedbackStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => FeedbackStatus.received,
      );
}

/// The facts that ride with a report unless the student switches them off.
@immutable
class FeedbackDeviceInfo {
  const FeedbackDeviceInfo({
    required this.appVersion,
    this.deviceModel,
    this.androidVersion,
  });

  /// Installed build, as `1.15.0+36`.
  final String appVersion;

  /// Maker and model, as `Samsung SM-S911B`.
  final String? deviceModel;

  /// Release and API level, as `14 (SDK 34)`.
  final String? androidVersion;
}

/// Where a report waiting on the device stands.
enum QueuedFeedbackState {
  /// Not sent yet; it goes out on the next attempt.
  pending,

  /// The service refused it for good; kept so the student can read why.
  failed,
}

/// A report saved on the device before it reaches the service.
///
/// Every report is written here first, so closing the app, losing the
/// connection or a crashed request never loses what the student wrote.
/// [clientId] travels with every attempt so a retry after a lost response
/// is recognised by the service instead of creating a second report.
@immutable
class QueuedFeedback {
  const QueuedFeedback({
    required this.clientId,
    required this.createdAt,
    required this.type,
    required this.message,
    required this.appVersion,
    this.rating,
    this.contact,
    this.name,
    this.anonymous = false,
    this.deviceModel,
    this.androidVersion,
    this.screenshots = const [],
    this.state = QueuedFeedbackState.pending,
    this.attempts = 0,
    this.lastError,
    this.nextAttemptAt,
  });

  final String clientId;
  final DateTime createdAt;
  final FeedbackType type;
  final String message;
  final int? rating;
  final String? contact;

  /// The name the student chose to send with the report, if any.
  final String? name;

  /// When true the report carries no name and no contact, here or on the
  /// service.
  final bool anonymous;
  final String appVersion;
  final String? deviceModel;
  final String? androidVersion;

  /// File names inside the queue's own screenshot folder.
  final List<String> screenshots;
  final QueuedFeedbackState state;
  final int attempts;
  final String? lastError;

  /// Set from the service's Retry-After; earlier attempts are skipped.
  final DateTime? nextAttemptAt;

  QueuedFeedback copyWith({
    List<String>? screenshots,
    QueuedFeedbackState? state,
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt,
    bool clearNextAttempt = false,
  }) => QueuedFeedback(
    clientId: clientId,
    createdAt: createdAt,
    type: type,
    message: message,
    rating: rating,
    contact: contact,
    name: name,
    anonymous: anonymous,
    appVersion: appVersion,
    deviceModel: deviceModel,
    androidVersion: androidVersion,
    screenshots: screenshots ?? this.screenshots,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: lastError ?? this.lastError,
    nextAttemptAt: clearNextAttempt
        ? null
        : nextAttemptAt ?? this.nextAttemptAt,
  );

  Map<String, Object?> toJson() => {
    'client_id': clientId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'type': type.wire,
    'message': message,
    'rating': rating,
    'contact': contact,
    'name': name,
    'anonymous': anonymous,
    'app_version': appVersion,
    'device_model': deviceModel,
    'android_version': androidVersion,
    'screenshots': screenshots,
    'state': state.name,
    'attempts': attempts,
    'last_error': lastError,
    'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
  };

  static QueuedFeedback fromJson(Map<String, Object?> json) => QueuedFeedback(
    clientId: json['client_id']! as String,
    createdAt: DateTime.parse(json['created_at']! as String),
    type: FeedbackType.fromWire(json['type'] as String?),
    message: json['message']! as String,
    rating: (json['rating'] as num?)?.toInt(),
    contact: json['contact'] as String?,
    // Reports saved before names existed carry neither key.
    name: json['name'] as String?,
    anonymous: _readFlag(json['anonymous']),
    appVersion: json['app_version'] as String? ?? '',
    deviceModel: json['device_model'] as String?,
    androidVersion: json['android_version'] as String?,
    screenshots: [
      for (final name in (json['screenshots'] as List?) ?? const [])
        name as String,
    ],
    state: json['state'] == QueuedFeedbackState.failed.name
        ? QueuedFeedbackState.failed
        : QueuedFeedbackState.pending,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    lastError: json['last_error'] as String?,
    nextAttemptAt: switch (json['next_attempt_at']) {
      final String value => DateTime.tryParse(value),
      _ => null,
    },
  );
}

/// A report as the service holds it, with the developer's answer.
@immutable
class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.message,
    required this.status,
    this.updatedAt,
    this.rating,
    this.adminReply,
    this.repliedAt,
    this.attachments = 0,
    this.displayName,
    this.anonymous = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final FeedbackType type;
  final String message;
  final int? rating;
  final FeedbackStatus status;
  final String? adminReply;
  final DateTime? repliedAt;
  final int attachments;

  /// The name the report was sent with; null when none was given.
  final String? displayName;

  /// True when the report was sent without a name or contact.
  final bool anonymous;

  static FeedbackItem fromJson(Map<String, Object?> json) => FeedbackItem(
    id: '${json['id']}',
    createdAt:
        _date(json['created_at']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: _date(json['updated_at']),
    type: FeedbackType.fromWire(json['type'] as String?),
    message: json['message'] as String? ?? '',
    rating: (json['rating'] as num?)?.toInt(),
    status: FeedbackStatus.fromWire(json['status'] as String?),
    adminReply: switch (json['admin_reply']) {
      final String reply when reply.trim().isNotEmpty => reply.trim(),
      _ => null,
    },
    repliedAt: _date(json['replied_at']),
    attachments: switch (json['attachments']) {
      final num count => count.toInt(),
      final List<Object?> list => list.length,
      _ => 0,
    },
    displayName: switch (json['display_name']) {
      final String name when name.trim().isNotEmpty => name.trim(),
      _ => null,
    },
    anonymous: _readFlag(json['anonymous']),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt?.toUtc().toIso8601String(),
    'type': type.wire,
    'message': message,
    'rating': rating,
    'status': status.wire,
    'admin_reply': adminReply,
    'replied_at': repliedAt?.toUtc().toIso8601String(),
    'attachments': attachments,
    'display_name': displayName,
    'anonymous': anonymous ? 1 : 0,
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
