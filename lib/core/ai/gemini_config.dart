/// Compile-time configuration for the Gemini API.
///
/// **How to supply the key (development):**
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
/// ```
///
/// **How to supply the key (CI / release):**
/// Store the key in a secret, then pass `--dart-define` from the build script.
/// Never commit a real key to version control.
///
/// **Production path:** Replace the `fromEnvironment` factory with a call to
/// your own backend/proxy that signs requests server-side, so the key is never
/// shipped inside the APK.
class GeminiConfig {
  /// Ordered fallback chain of Gemini model identifiers.
  ///
  /// The service will attempt each model in order. If the current model
  /// returns a rate-limit (429) or quota-exceeded (429/503) error, it
  /// automatically retries the next model in the chain.
  ///
  /// Model order (cheapest / fastest first):
  ///   1. gemini-3.5-flash-lite  — "Gemini 3.5 Flash Lite"
  ///   2. gemini-3.1-flash-lite  — "Gemini 3.1 Flash Lite"
  ///   3. gemma-4-26b-it         — "Gemma 4 26B"
  static const List<String> modelChain = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemma-4-26b-it',
  ];

  /// Base URL for the Gemini generateContent REST endpoint.
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Maximum milliseconds to wait for a Gemini response before timing out.
  static const Duration timeout = Duration(seconds: 30);

  /// Maximum number of pages of context to include in a single request.
  /// Keeps prompts from ballooning on very long PDFs.
  /// Limit 1: Limit the maximum number of retrieved pages.
  static const int maxContextPages = 8;

  /// Maximum characters allowed per individual page.
  /// Limit 2 & 7: Prevents a single dense page (like a large table or code block) 
  /// from consuming the entire context budget. Very large pages will be safely truncated.
  static const int maxCharsPerPage = 4000;

  /// Maximum total characters allowed in the entire context payload.
  /// Limit 3 & 8: Protects against excessively large payloads which cause timeouts, 
  /// higher latency, and LLM confusion (lost-in-the-middle phenomenon). 
  /// Never send the complete PDF automatically.
  static const int maxTotalContextChars = 24000;

  // ---------------------------------------------------------------------------
  // Instance
  // ---------------------------------------------------------------------------

  /// The API key.  Never log or expose this value.
  final String _apiKey;

  const GeminiConfig._(this._apiKey);

  /// Creates a config from the compile-time `--dart-define=GEMINI_API_KEY=…`.
  ///
  /// Returns `null` when the key was not supplied at build time (e.g. in a
  /// debug run without the define), so callers can degrade gracefully instead
  /// of crashing.
  static GeminiConfig? fromEnvironment() {
    // dart-define values are inlined at compile time; this is safe.
    const key = String.fromEnvironment('GEMINI_API_KEY');
    if (key.isEmpty) return null;
    return GeminiConfig._(key);
  }

  /// Creates a config with an explicit key — for integration tests or runtime
  /// key injection (e.g. from a settings screen or a proxy response).
  ///
  /// The caller is responsible for sourcing the key securely.
  factory GeminiConfig.withKey(String apiKey) {
    return GeminiConfig._(apiKey);
  }

  /// Creates an empty config to represent a missing/invalid key gracefully.
  const GeminiConfig.empty() : _apiKey = '';

  /// The full endpoint URL for [model]'s generateContent method.
  /// The key is appended as a query parameter — never embedded in logs.
  Uri generateContentUriForModel(String model) => Uri.parse(
        '$_baseUrl/$model:generateContent?key=$_apiKey',
      );

  /// True when the config holds a non-empty key.
  bool get isValid => _apiKey.isNotEmpty;

  @override
  String toString() => 'GeminiConfig(models: ${modelChain.join(', ')}, keySet: $isValid)';
}
