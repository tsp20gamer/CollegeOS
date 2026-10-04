import 'package:college_os/features/ai/domain/ai_context_limits.dart';

/// Compile-time configuration for the Gemini API.
///
/// This class is the **only** place that knows how a credential is obtained.
/// Retrieval and UI code never touch it beyond passing the value through, so
/// replacing direct API access with a backend/proxy later means changing this
/// file plus [GeminiTransport] — nothing else.
///
/// **How to supply the key (development):**
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
/// ```
///
/// **How to supply the key (CI / release):**
/// Keep the key in a CI secret and pass it with `--dart-define` from the build
/// script, or use `--dart-define-from-file=gemini.json` with a file that is
/// listed in `.gitignore`. Never commit a real key.
///
/// **Security note:** a client-side key embedded in a distributed APK cannot be
/// considered truly secret — anyone can extract it from the binary. It is
/// therefore kept out of Git, logs, UI and error messages, and isolated behind
/// this abstraction so a server-side proxy can take over without touching the
/// retrieval architecture or the UI.
///
/// **Production path:** swap [fromEnvironment] for a call that fetches a
/// short-lived token from your own backend, and point [baseUrl] at that proxy.
class GeminiConfig {
  /// Ordered fallback chain of Gemini model identifiers.
  ///
  /// The service tries each model in order and moves to the next one only when
  /// the current model reports a rate limit (429) or an overloaded/quota
  /// condition (503). Every entry below is a *current, stable* model ID taken
  /// from the official model list — no retired names.
  ///
  /// Order (cheapest / fastest first):
  ///   1. gemini-3.1-flash-lite — "Gemini 3.1 Flash-Lite", the default model
  ///   2. gemini-3.5-flash-lite — newer Flash-Lite generation
  ///   3. gemini-3.5-flash      — full Flash, last resort for quota errors
  static const List<String> modelChain = [
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash-lite',
    'gemini-3.5-flash',
  ];

  /// The model used unless a caller overrides it.
  static const String defaultModel = 'gemini-3.1-flash-lite';

  /// Base URL for the Gemini `generateContent` REST endpoint.
  ///
  /// The model is appended as `models/<model>:generateContent`. The API key is
  /// sent as a header, never as a query parameter, so it cannot leak through
  /// exception messages, URL logging or intermediary request logs.
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Maximum time to wait for a single Gemini call before failing.
  static const Duration timeout = Duration(seconds: 30);

  /// Maximum number of pages of context included in one request.
  ///
  /// Delegates to [AiContextLimits] so retrieval, assembly and the model call
  /// all agree on one number.
  static const int maxContextPages = AiContextLimits.defaultMaxContextPages;

  /// Maximum characters taken from a single page. See [AiContextLimits].
  static const int maxCharsPerPage = AiContextLimits.defaultMaxCharsPerPage;

  /// Maximum characters across the entire context payload.
  static const int maxTotalContextChars =
      AiContextLimits.defaultMaxTotalContextChars;

  /// Sets the API key as a request header on [request].
  ///
  /// Google's documented header is `x-goog-api-key`. Using it (instead of
  /// `?key=`) means the secret never appears in a URI, and URIs are exactly
  /// what ends up in stack traces and HTTP logs.
  static const String apiKeyHeader = 'x-goog-api-key';

  // ---------------------------------------------------------------------------
  // Instance
  // ---------------------------------------------------------------------------

  /// The API key. Never logged, printed, displayed or persisted.
  final String _apiKey;

  /// Optional proxy base URL. When set, requests go to a backend that holds the
  /// real key, and the local key may be empty.
  final String? proxyBaseUrl;

  const GeminiConfig._(this._apiKey, this.proxyBaseUrl);

  /// Creates a config from the compile-time `--dart-define=GEMINI_API_KEY=…`.
  ///
  /// Returns `null` when the key was not supplied at build time (a plain
  /// `flutter run` without the define), so callers can degrade gracefully
  /// instead of crashing or sending an unauthenticated request.
  static GeminiConfig? fromEnvironment() {
    const key = String.fromEnvironment('GEMINI_API_KEY');
    const override = String.fromEnvironment('GEMINI_API_BASE_URL');
    if (key.isEmpty) return null;
    return GeminiConfig._(key, override.isEmpty ? null : override);
  }

  /// Creates a config with an explicit key — for tests, for runtime key
  /// injection from a settings screen, or for a proxy that returns a token.
  ///
  /// The caller is responsible for sourcing the key securely.
  factory GeminiConfig.withKey(String apiKey, {String? proxyBaseUrl}) {
    return GeminiConfig._(apiKey, proxyBaseUrl);
  }

  /// Represents a missing/invalid key gracefully.
  const GeminiConfig.empty() : _apiKey = '', proxyBaseUrl = null;

  /// Parameters shared by every request: authentication and content type.
  ///
  /// Returns an empty map when no key is set, and deliberately never contains
  /// the key in any value that is safe to log.
  Map<String, String> requestHeaders() {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (_apiKey.isNotEmpty) apiKeyHeader: _apiKey,
    };
  }

  /// The `generateContent` endpoint for [model].
  ///
  /// Contains no credential material.
  Uri generateContentUriForModel(String model) =>
      Uri.parse('${proxyBaseUrl ?? baseUrl}/$model:generateContent');

  /// True when the config holds a non-empty key.
  bool get isValid => _apiKey.isNotEmpty;

  /// True when requests are routed through a proxy base URL.
  bool get isProxied => proxyBaseUrl != null;

  @override
  String toString() =>
      'GeminiConfig(models: ${modelChain.join(', ')}, keySet: $isValid, '
      'proxied: $isProxied)';
}
