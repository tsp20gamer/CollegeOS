/// Single source of truth for how much locally retrieved note text is allowed
/// to reach the AI model.
///
/// These values are deliberately *not* hardcoded at the call sites: the context
/// builder and the retrieval layer both read them from here, and a different
/// profile can be injected in tests (see [AiContextLimits.tiny]).
///
/// Limits exist because a single dense textbook page can be ~200 KB of text.
/// Sending several of them would blow cost, latency and the model's ability to
/// stay grounded ("lost in the middle").
class AiContextLimits {
  const AiContextLimits({
    this.maxContextPages = defaultMaxContextPages,
    this.maxCharsPerPage = defaultMaxCharsPerPage,
    this.maxTotalContextChars = defaultMaxTotalContextChars,
  });

  /// The `MAX_CONTEXT_PAGES` default from the feature spec.
  static const int defaultMaxContextPages = 8;

  /// Characters taken from a single page before truncation.
  static const int defaultMaxCharsPerPage = 4000;

  /// Characters allowed across one whole request.
  static const int defaultMaxTotalContextChars = 24000;

  /// Maximum number of locally retrieved pages handed to the model in one
  /// request. This is the `MAX_CONTEXT_PAGES` knob from the feature spec.
  final int maxContextPages;

  /// Maximum characters taken from any single page before it is truncated.
  /// Prevents one huge page from consuming the whole budget.
  final int maxCharsPerPage;

  /// Maximum characters across *all* pages in one request. Pages are added in
  /// FTS5 relevance order and the first page that would exceed this budget ends
  /// the assembly, so lower-ranked pages are dropped rather than squeezed.
  final int maxTotalContextChars;

  /// Default production profile.
  static const AiContextLimits defaults = AiContextLimits();

  /// A deliberately small profile for tests and for very constrained devices.
  static const AiContextLimits tiny = AiContextLimits(
    maxContextPages: 2,
    maxCharsPerPage: 50,
    maxTotalContextChars: 80,
  );

  /// Marker appended to a page that had to be cut short, so the model knows the
  /// text is incomplete instead of assuming the page ended there.
  static const String truncationMarker = '\n…[page truncated]';

  @override
  String toString() =>
      'AiContextLimits(pages: $maxContextPages, '
      'charsPerPage: $maxCharsPerPage, charsTotal: $maxTotalContextChars)';
}
