import 'package:college_os/features/notes/domain/ai_context.dart';

/// The explicit lifecycle of one AI note-search request.
///
/// Every phase is observable on its own so the UI can show what is actually
/// happening (local retrieval vs. waiting on the model) instead of a single
/// anonymous spinner.
enum AiNoteSearchPhase {
  /// Nothing asked yet.
  idle,

  /// Querying the local FTS5 index.
  searching,

  /// Relevant pages were found locally; about to call the model.
  contextFound,

  /// Waiting for the model to answer.
  generating,

  /// A grounded answer is available.
  success,

  /// The local index had nothing to answer from, so the model was not called.
  noContext,

  /// The device is offline; the model cannot be reached.
  offline,

  /// The request failed (bad key, rate limit, server error, timeout, …).
  apiError,
}

/// Immutable snapshot of the AI search flow, consumed by the UI.
///
/// [message] is always safe to display: it is either a locally authored string
/// or a mapped error description. Raw exception text and credentials never
/// reach it.
class AiNoteSearchStatus {
  const AiNoteSearchStatus({
    required this.phase,
    this.question,
    this.result,
    this.message,
    this.sourcePageCount = 0,
    this.failure = AiFailure.none,
  });

  /// Initial state before anything has been asked.
  static const AiNoteSearchStatus initial = AiNoteSearchStatus(
    phase: AiNoteSearchPhase.idle,
  );

  final AiNoteSearchPhase phase;

  /// The question this status refers to.
  final String? question;

  /// Populated for [AiNoteSearchPhase.success].
  final AiSearchResult? result;

  /// User-facing explanation for a non-success phase, or `null`.
  final String? message;

  /// How many local pages matched, once retrieval finished. Lets the UI say
  /// "searched 3 pages" while the model is still thinking.
  final int sourcePageCount;

  /// Machine-readable reason when [phase] is [AiNoteSearchPhase.apiError],
  /// [AiNoteSearchPhase.offline] or [AiNoteSearchPhase.noContext].
  final AiFailure failure;

  /// True while the request is in flight, so the UI can disable duplicate
  /// submissions.
  bool get isBusy =>
      phase == AiNoteSearchPhase.searching ||
      phase == AiNoteSearchPhase.contextFound ||
      phase == AiNoteSearchPhase.generating;

  /// True when an answer (grounded or explicitly "not found") is on screen.
  bool get hasResult => result != null;

  /// Human-readable progress label for the busy phases.
  String? get progressLabel => switch (phase) {
    AiNoteSearchPhase.searching => 'Searching your indexed notes…',
    AiNoteSearchPhase.contextFound => 'Found relevant pages, asking AI…',
    AiNoteSearchPhase.generating => 'Asking AI…',
    _ => null,
  };

  AiNoteSearchStatus copyWith({
    AiNoteSearchPhase? phase,
    String? question,
    AiSearchResult? result,
    String? message,
    int? sourcePageCount,
    AiFailure? failure,
  }) {
    return AiNoteSearchStatus(
      phase: phase ?? this.phase,
      question: question ?? this.question,
      result: result ?? this.result,
      message: message ?? this.message,
      sourcePageCount: sourcePageCount ?? this.sourcePageCount,
      failure: failure ?? this.failure,
    );
  }

  @override
  String toString() =>
      'AiNoteSearchStatus(phase: $phase, '
      'matches: $sourcePageCount, failure: $failure)';
}
