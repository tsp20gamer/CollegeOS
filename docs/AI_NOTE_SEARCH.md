# AI note search

AI note search answers a natural-language question from the user's **own indexed
PDF pages**. It is an addition to the offline keyword search, never a
replacement for it.

```text
question
   ↓
local FTS5 retrieval (pdf_page_fts)          ← offline, unchanged index
   ↓
bounded context assembly                     ← page labels + size limits
   ↓
Gemini generateContent (text only)           ← needs internet
   ↓
validated citations                          ← pages checked against what was sent
   ↓
answer + source pages
```

Gemini never performs the document search. It only ever sees the handful of
pages the on-device index already selected.

## Supplying the API key

The key is read at **compile time** and is never written to source, the
database, logs, UI text or error messages.

```bash
# Recommended: a local file that .gitignore already excludes (env.json)
cp env.json.example env.json      # then paste the real key
flutter run --dart-define-from-file=env.json
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

Without the define the app behaves exactly as before: keyword search works, and
"Ask AI" explains that AI search is not configured. No request is attempted.

| Variable | Required | Purpose |
| --- | --- | --- |
| `GEMINI_API_KEY` | yes, for AI | Google AI Studio API key |
| `GEMINI_API_BASE_URL` | no | Point the client at a backend/proxy instead of Google |

### Why this is isolated

A key embedded in a distributed APK is extractable, so it is treated as a
credential of limited value rather than a secret:

- `lib/core/ai/gemini_config.dart` is the **only** place that knows how a key is
  obtained. It also builds the request headers, and the key travels in the
  `x-goog-api-key` header — never a URL query parameter, because URLs end up in
  stack traces and HTTP logs.
- `GeminiTransport` is the only place that performs HTTP. Pointing
  `GEMINI_API_BASE_URL` at your own backend replaces direct Google access
  without touching retrieval, prompting, state handling or the UI.

## Limits

| Setting | Default | Where |
| --- | --- | --- |
| Pages per request | 8 | `AiContextLimits.maxContextPages` |
| Characters per page | 4000 | `AiContextLimits.maxCharsPerPage` |
| Characters per request | 24000 | `AiContextLimits.maxTotalContextChars` |
| Request timeout | 30 s | `GeminiConfig.timeout` |
| Model | `gemini-3.1-flash-lite` | `GeminiConfig.modelChain` |

Lower-ranked pages are dropped rather than squeezed once the total budget is
exhausted, so every page in the prompt keeps its own labelled block and page
boundaries never blur.

## Grounding

The prompt asks for JSON matching a fixed schema (`answer`, `grounded`,
`sources`) and the system instruction forbids outside knowledge. Grounding is
then enforced locally rather than trusted:

- **No context, no call.** An empty or all-blank retrieval short-circuits to
  "I couldn't find this topic in your indexed notes." The model is never given
  an empty context, which is what invites a plausible invention.
- **Citations are verified.** A returned source is kept only when its
  `(fileId, page)` pair is in the set of pages actually sent. A model citing
  page 99 when pages 12–14 were supplied loses that citation.
- **File names come from the database**, not from the model, so a fabricated
  document name can never be displayed next to a real page.
- A free-text response (schema ignored) is still parsed, and its
  `[Source N]` / `[File:X Page:Y]` markers are validated the same way.

## States

`AiNoteSearchPhase`: `idle`, `searching`, `contextFound`, `generating`,
`success`, `noContext`, `offline`, `apiError`.

Traversal failures are classified (`AiFailure`) into offline, timeout,
rate-limited, unauthorised, server and malformed-response, each with a
user-facing message. Nothing appends raw request detail, and the raw error is
never surfaced.

## Offline behaviour

`ACCESS_NETWORK_STATE` is deliberately stripped from the manifest, so the app
does not ask Android for connectivity state. Offline is detected from the
transport failure itself (`SocketException` / `HandshakeException`), which needs
no permission and keeps the release manifest as small as it was.

Keyword search runs entirely on-device and is unaffected by any AI failure.

## Concurrency and cost

- Identical question + identical retrieved context is served from a 16-entry
  in-memory cache. Nothing is persisted.
- A duplicate identical request returns immediately while the first is in
  flight; a response for a superseded question is discarded instead of
  overwriting newer state.
- Rate-limit (429) and overload (503) responses fall back to the next model in
  the chain. Other errors are not retried.

## Tests

`test/features/ai/` covers query building, context assembly, prompt
construction, structured parsing, citation rejection, empty context, offline,
timeout, missing key and the success path. Every test runs against a fake
`GeminiTransport`; no automated test contacts Gemini.
