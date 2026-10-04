/// Turns a natural-language question into an FTS5 `MATCH` expression.
///
/// The keyword search path builds `"word1* word2*"`, which FTS5 interprets as
/// **AND** — every word must appear on the page. That is right for a keyword
/// box, but it fails for a question: `"What is the working principle of a PN
/// junction diode?"` would demand that a page literally contain "what", "is",
/// "the" and "of" alongside the physics terms, so it matches nothing.
///
/// For AI context retrieval we instead drop the question words that carry no
/// retrieval signal and **OR** the remaining terms together, letting FTS5's
/// BM25 ranking surface pages that match the most meaningful terms first.
///
/// The builder is pure and synchronous, so it is cheap to unit test and can be
/// used from the repository before it touches the database.
class AiQueryBuilder {
  const AiQueryBuilder._();

  /// Words that appear in almost every question and therefore add noise rather
  /// than signal. Kept intentionally small — over-filtering loses real content
  /// words, under-filtering recreates the AND problem.
  static const Set<String> stopwords = {
    'a',
    'an',
    'the',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'am',
    'do',
    'does',
    'did',
    'doing',
    'have',
    'has',
    'had',
    'having',
    'what',
    'which',
    'who',
    'whom',
    'whose',
    'when',
    'where',
    'why',
    'how',
    'of',
    'in',
    'on',
    'at',
    'to',
    'for',
    'from',
    'by',
    'with',
    'without',
    'about',
    'into',
    'over',
    'under',
    'between',
    'during',
    'through',
    'and',
    'or',
    'but',
    'if',
    'then',
    'than',
    'that',
    'this',
    'these',
    'those',
    'there',
    'here',
    'it',
    'its',
    'as',
    'so',
    'such',
    'not',
    'no',
    'yes',
    'can',
    'could',
    'should',
    'would',
    'will',
    'shall',
    'may',
    'might',
    'must',
    'my',
    'me',
    'i',
    'we',
    'our',
    'you',
    'your',
    'they',
    'their',
    'he',
    'she',
    'his',
    'her',
    'them',
    'us',
    'also',
    'any',
    'all',
    'some',
    'more',
    'most',
    'other',
    'please',
    'give',
    'tell',
    'explain',
    'discuss',
    'write',
    'short',
    'long',
    'answer',
    'notes',
    'note',
    'topic',
    'chapter',
    'according',
    'using',
    'use',
    'used',
    'make',
    'made',
    'need',
    'want',
    'know',
    'list',
    'mention',
    'state',
    'define',
    'briefly',
    'brief',
    'detail',
    'details',
    'summary',
    'summarize',
    'summarise',
    'important',
    'main',
    'key',
  };

  /// Minimum token length kept as a search term.
  ///
  /// One-character tokens are noise (`a`, `I`) and FTS5 prefix queries on them
  /// match nearly everything.
  static const int minTokenLength = 2;

  /// Upper bound on terms in the generated expression.
  ///
  /// A long question would otherwise OR together 30+ terms, matching a large
  /// slice of the index and pushing genuinely relevant pages down the ranking.
  static const int defaultMaxTerms = 12;

  /// Splits [question] into candidate search terms, in the order they appear.
  ///
  /// Stopwords and very short tokens are removed, duplicates are collapsed, and
  /// at most [maxTerms] terms are returned.
  ///
  /// A question made only of stopwords (`"what is this"`) yields no terms: it
  /// carries no retrieval signal, and searching for the stopwords would match
  /// an arbitrary slice of the index. The caller treats that as "nothing found",
  /// which is the honest outcome.
  static List<String> extractTerms(
    String question, {
    int maxTerms = defaultMaxTerms,
  }) {
    final all = _tokenize(question);
    if (all.isEmpty) return const [];

    final meaningful = all.where((t) => !stopwords.contains(t)).toList();

    final seen = <String>{};
    final terms = <String>[];
    for (final term in meaningful) {
      if (!seen.add(term)) continue;
      terms.add(term);
      if (terms.length >= maxTerms) break;
    }
    return terms;
  }

  /// Builds the FTS5 `MATCH` expression for [question], or `null` when the
  /// question contains nothing searchable.
  ///
  /// Every emitted term is `[a-z0-9]`-only and suffixed with `*`, so the result
  /// can never contain FTS5 syntax and can be passed to the DAO as-is.
  static String? buildFtsExpression(
    String question, {
    int maxTerms = defaultMaxTerms,
  }) {
    final terms = extractTerms(question, maxTerms: maxTerms);
    if (terms.isEmpty) return null;
    return terms.map((t) => '$t*').join(' OR ');
  }

  /// Lowercases [input] and keeps only Unicode letters and digits.
  ///
  /// Mirrors the sanitising the keyword path already does, which is what makes
  /// the generated expression safe.
  static List<String> _tokenize(String input) {
    final normalised = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim();
    if (normalised.isEmpty) return const [];
    return normalised
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= minTokenLength)
        .toList();
  }
}
