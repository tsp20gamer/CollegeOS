# CollegeOS personal Android release checklist

## Cutting a release

1. Bump `version:` in `pubspec.yaml` — both the name and the build number. Android
   refuses to install a lower `versionCode` over an installed build, and the
   updater compares version *names*, so both must move forward.
2. Update `CHANGELOG.md`, commit, and push to `main`.
3. Tag the same version the pubspec now carries and push the tag:

   ```bash
   git tag v1.12.0 && git push origin v1.12.0
   ```

4. `.github/workflows/release.yml` does the rest: it fails if the tag and the
   pubspec version disagree, runs the gates below, builds the release APK,
   publishes it on the tag's GitHub Release, and commits the new `version.json`
   to `main`. The update is live as soon as that commit lands.

Repository secrets the workflow needs (Settings → Secrets and variables →
Actions):

| Secret | What it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 android/collegeos-release.jks` — the keystore installed builds already trust |
| `ANDROID_STORE_PASSWORD` | The keystore password from `android/key.properties` |
| `ANDROID_KEY_ALIAS` | The key alias from `android/key.properties` |
| `ANDROID_KEY_PASSWORD` | The key password from `android/key.properties` |
| `GEMINI_API_KEY` | Optional. Without it the release ships with AI search off and everything else unchanged |
| `GEMINI_API_BASE_URL` | Optional. Only needed when a proxy replaces direct API access |

The workflow never writes the API key into `env.json`; it passes it as a
`--dart-define`, and it creates the file itself only because `env.json` is a
declared asset that is deliberately gitignored.

## Automated gates

The pipeline runs these on every tag, and they are worth running locally too:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- Inspect the merged release manifest: it must carry only the permissions the app
  uses — `INTERNET` (the opt-in AI query and the release check),
  `REQUEST_INSTALL_PACKAGES` (the updater), notifications, exact alarms, boot and
  the data-sync foreground service — and no storage or media reads, analytics,
  trackers, or cloud SDKs.
- Confirm package `com.collegeos.app`, version, minimum SDK, target SDK, signing
  certificate, APK size, and SHA-256 — and that the published `version.json`
  names the version this APK reports.

## Upgrade and data safety

- Install over the previous signed personal build; do not uninstall when preserving device data.
- Open an existing schema-v7 database and verify settings, timetable, attendance, tasks, exams, and marks.
- Export a `.collegeos` backup, restore it into a clean test database, and compare all relationships.
- Confirm older backup-format-1 archives remain accepted.

## Update channel checks

- With an older build installed, launch the app and confirm it offers the newer
  release once, silently, without blocking the dashboard.
- Settings → Check for Updates reports "up to date" on the newest build, and a
  clear message when the device is offline.
- Update now downloads with visible progress, opens Android's installer, and
  installs over the existing app without losing data. Declining, cancelling, or
  losing the connection leaves the installed build exactly as it was.

## Device checks

- Fresh onboarding and restart persistence.
- Light/dark themes at 360–430 logical pixels.
- Add and refresh the home-screen widget using the device launcher.
- Mark a timetable date as holiday; verify classes disappear from Attendance, Home, and widget, then undo and verify prior marks return.
- Verify task/exam notification permission, scheduling, editing, completion, deletion, and notification taps.
- Verify backup export/import through Android’s system file workflow.

## Release policy

Every piece of user data stays on the device. A release must not contain login,
accounts, Firebase, Supabase, backend services, cloud sync, advertisements,
trackers, or analytics.

Exactly two features reach the network on their own:

- **AI note search**, only with a configured key and only when the student asks a
  question; retrieval and keyword search stay offline.
- **The release check**, which reads a public `version.json` that describes the
  newest published build. It sends no data about the device or the student, and
  it downloads nothing unless the student taps Update.

Both failures are non-fatal: without a connection, CollegeOS behaves exactly as
it always has.
