# CollegeOS Architecture

## 1. Current environment inspection

Initial inspection date: **12 August 2026**. Phase 0 and the Phase 1 foundation were completed on the same date. The repository remains on branch `master` with no commits.

### Verified locally

| Component | Observed state |
|---|---|
| OS | 64-bit Windows, build 26200, approximately 16 GB RAM |
| Git | 2.55.0.windows.2 |
| Android Studio | 2026.1.3, build `AI-261.26222.65.2613.15948027` |
| Flutter | 3.44.9 stable at `C:\Users\Admin\development\flutter` |
| Dart | 3.12.2 (bundled with Flutter) |
| Android SDK | `C:\Users\Admin\AppData\Local\Android\Sdk`; licenses accepted |
| Installed platforms | Android API 36 and API 37.0 |
| Build tools | 36.0.0 |
| Platform tools / ADB | 37.0.1 |
| Command-line tools | 22.0 (`cmdline-tools;latest`) |
| Emulator | 37.1.11; Pixel 7 `CollegeOS_API_36` phone AVD |
| Bundled Java | Android Studio JBR OpenJDK 25.0.2 |

User-scoped `FLUTTER_ROOT`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `JAVA_HOME`, and tool `PATH` entries are configured. `flutter doctor -v` passes the Android toolchain. Its only remaining issue is missing Visual Studio for Windows desktop builds, which is outside the Android-first scope. The generated Gradle wrapper is authoritative; no system Gradle is required. The current Gradle/AGP toolchain accepts the Android Studio JBR 25 runtime while compiling Java/Kotlin bytecode at Java 17.

## 2. Architectural style

Use a pragmatic feature-first clean architecture:

```text
Presentation (screens, widgets)
        ↓ watches/commands
Application (Riverpod controllers, use-case orchestration)
        ↓ depends on contracts
Domain (entities, value objects, calculators, repository interfaces)
        ↑ implemented by
Data (Drift DAOs, repository implementations, platform adapters)
        ↓
SQLite and Android platform services
```

Rules:

- Dependencies point inward toward domain concepts.
- Widgets never issue raw SQL, schedule platform notifications, open pickers, or manipulate archives.
- Drift row classes do not escape repositories when doing so would couple the UI to persistence.
- Riverpod providers own lifetimes and dependency wiring; they do not become a global dumping ground for business rules.
- Pure calculations such as attendance metrics stay synchronous, deterministic, and testable without Flutter.
- Cross-feature actions such as deleting a subject are coordinated in an application service and executed transactionally.

## 3. Proposed folder layout

```text
lib/
  main.dart                         # binding + bootstrap call only
  app/
    app.dart                        # MaterialApp.router
    bootstrap.dart                  # database/services initialization
    app_providers.dart              # root dependency wiring
  core/
    database/
      app_database.dart
      connection/
      tables/
      daos/
      migrations/
      schema_versions/
    routing/
      app_router.dart
      route_names.dart
      navigation_shell.dart
    theme/
      app_theme.dart
      color_tokens.dart
      spacing.dart
      typography.dart
    services/
      notifications/
      clock/
      file_system/
    utils/
      date_only.dart
      time_of_day_value.dart
      result.dart
  features/
    onboarding/
    home/
    semesters/
    subjects/
    attendance/
    timetable/
    tasks/
    exams/
    marks/
    backup/
    settings/
  shared/
    widgets/
      app_scaffold.dart
      empty_state.dart
      error_state.dart
      loading_state.dart
      confirmation_sheet.dart
    extensions/
    formatters/
```

Each non-trivial feature follows the same internal shape:

```text
feature/
  domain/
    entities/
    repositories/
    services/
  data/
    repositories/
    mappers/
  application/
    controllers/
    providers.dart
  presentation/
    screens/
    widgets/
```

Do not create empty layers merely for symmetry. Small features can combine nearby files while retaining dependency direction. Tests mirror `lib/`; database migration fixtures live under `test/fixtures/databases/`, and Android end-to-end tests live under `integration_test/`.

## 4. State management

- Use `Provider` for repositories, clocks, calculators, and platform-service abstractions.
- Use stream-backed providers for Drift watch queries such as active semester, today's timetable, attendance summaries, and open tasks.
- Use `AsyncNotifier`/`Notifier` controllers for forms and commands that have loading, success, and failure states.
- Keep ephemeral UI state (selected tab subfilter, expanded card) local unless multiple screens require it.
- Invalidate or update only affected providers after commands; reactive Drift streams should handle most refreshes.
- Surface domain failures as typed failures with user-actionable messages. Unexpected exceptions are logged locally only during development and never sent off device.

Android notifications use a versioned high-importance `CollegeOS reminders`
channel. Channel migrations remove obsolete CollegeOS channel IDs after creating
the current channel so an old broken configuration cannot silently absorb new
reminders. Permission checks initialize the plugin and channel first, then read
Android's runtime permission and the active channel directly. This avoids OEM
aggregate-permission probes incorrectly blocking delivery after the user has
already granted the visible Android permission. The test action only reports
success when both the Android runtime permission and active channel are enabled.
The monochrome Android small icon is stored as `@drawable/ic_notification` and
is explicitly retained in `res/raw/keep.xml`, because the notification plugin
resolves its name dynamically and the release resource shrinker cannot infer
that reference from Dart code.

During device verification, Settings exposes a deliberately temporary local
diagnostics panel. It reports the persisted CollegeOS preference separately from
Android permission, reminder-channel importance, pending OS projections, local
timezone, Android API, and battery-optimization status. The panel does not log,
upload, or persist diagnostics and can be removed without changing the stable
notification scheduling contract.

Riverpod code generation is intentionally omitted at first to reduce generators and dependencies. Drift remains the only required code generator. Reconsider only if hand-written provider maintenance becomes materially worse.

## 5. Navigation design

The bottom navigation bar spans the full width, sits flush with the bottom edge,
and paints behind the system inset itself. All five destinations keep their icon
and label at every width: labels are clamped to a 1.3 text scale factor, matching
Material's own `NavigationBar`, and scaled down to fit their slot instead of
being truncated or hidden. Selection slides one rounded indicator between
equal-width slots while the icon cross-fades to its filled variant. The retained
tab subtree makes a 150 ms translation of 1.2% of its width with no full-page
opacity or blur layer. Android reduced-motion and accessible-navigation settings
disable this decorative movement.

Because the shell uses `Scaffold.extendBody`, the bar's total height is folded
into `MediaQuery.padding.bottom` for the body, so `AppLayout.scaffoldBottomPadding`
derives content clearance from the resolved padding. A route pushed above the
shell sees only the system inset, which is what makes the same helper correct
both inside and outside the shell.

Settings is deliberately not a destination. Each tab header exposes it through
`AppScaffold.showSettingsAction`, and `/settings` is a top-level route that pushes
over the shell so it keeps a back button. `AppScaffold` also supplies a back
affordance to every pushed screen, and wraps its header actions so a compact
phone with several actions at a large text scale wraps instead of overflowing.

Use `GoRouter` with an onboarding redirect and a `StatefulShellRoute.indexedStack` for persistent tab state.

```text
/startup
/onboarding
/onboarding/setup
/restore-backup
/getting-started
/notes/subject/:subjectId
/ (StatefulShellRoute.indexedStack, five destinations)
  /home
  /attendance
    /attendance/pending
    /attendance/analytics
    /attendance/planner
    /attendance/subject/:subjectId
  /timetable
    /timetable/exceptions
  /tasks
  /notes
    /notes/search
/settings
  /settings/semesters
  /settings/subjects
  /settings/exams-marks
    /settings/exams-marks/subject/:subjectId
  /settings/college-information
  /settings/data-backup
  /settings/academic-calendar
  /settings/reports
  /settings/help
```

Settings management routes can nest their own create/edit/detail screens. Stable route names and typed ID parsing are required. Missing or deleted IDs show a recoverable not-found state. Notification payloads contain only a route kind and local entity ID, never serialized user content. Router redirects depend only on the local onboarding-complete provider; there is no authentication redirect.

## 6. Package baseline

The versions below were resolved locally on 12 August 2026 with Flutter 3.44.9 / Dart 3.12.2 and are locked in `pubspec.lock`. The solver proved two cross-package constraints: `share_plus 13.x` conflicts with `file_picker 11.0.3` over `win32`, and `build_runner 2.15.2+` conflicts with Flutter's `meta 1.18.0` pin. The table therefore uses the newest stable versions that solve together without dependency overrides.

### Runtime dependencies

| Package | Candidate constraint | Purpose |
|---|---:|---|
| `flutter_riverpod` | `^3.4.2` | State, dependency wiring, async states |
| `go_router` | `^17.5.0` | Routing and persistent navigation shell |
| `drift` | `2.34.0` | Typed reactive database and migrations; aligned with the compatible generator |
| `drift_flutter` | `^0.3.1` | Supported Flutter-native Drift connection setup |
| `path` | `^1.9.1` | Safe cross-platform path composition |
| `path_provider` | `^2.1.6` | App support/temp directories |
| `file_picker` | `10.3.10` | Latest stable release verified to compile its Kotlin plugin under Flutter 3.44.9/AGP 9 legacy-KGP mode |
| `share_plus` | `12.0.2` | Android share sheet; latest stable compatible with the selected `file_picker` (`win32` 5.x) |
| `archive` | `^4.0.9` | ZIP-compatible `.collegeos` encoding and bounded inspection |
| `crypto` | `^3.0.7` | SHA-256 backup integrity hashes |
| `package_info_plus` | `9.0.1` | Installed application version in backup manifests |
| `home_widget` | `^0.9.3` | Android home-screen projection for next class and today's attendance |
| `flutter_local_notifications` | `^22.3.0` | Offline local reminders |
| `timezone` | `^0.11.1` | Timezone-aware scheduling |
| `flutter_timezone` | `^5.1.0` | Device IANA timezone discovery |
| `intl` | `^0.20.3` | Locale-aware date, time, number formatting |

Flutter itself supplies Material 3. No third-party UI kit, font downloader, chart library, object mapper, or model generator is planned. Progress rings and bars are simple reusable Flutter widgets.

`sqlite3_flutter_libs` must **not** be added directly. Its current `0.6.0+eol` release is a no-op migration marker and its publisher says SQLite 3.x packages no longer require it. `drift`/`drift_flutter` bring the supported SQLite 3 runtime transitively. Do not pin a second SQLite binary package without a demonstrated need.

### Development dependencies

| Package | Candidate constraint | Purpose |
|---|---:|---|
| `flutter_test` | SDK | Unit and widget tests |
| `integration_test` | SDK | Android end-to-end tests |
| `flutter_lints` | `^6.0.0` | Analyzer baseline |
| `drift_dev` | `2.34.0` | Latest stable compatible generator with Flutter 3.44.9's analyzer/meta pins |
| `build_runner` | `2.15.1` | Latest stable compatible runner before analyzer 13.3/meta 1.18.3 requirement |
| `mocktail` | `^1.0.5` | Lightweight mocks for platform/repository boundaries |

Before accepting the set, verify the resolved `drift`, `drift_dev`, `sqlite3`, analyzer, and build packages together. Drift runtime `2.34.3` was tested, but its matching generator requires Analyzer 13, which conflicts with this Flutter SDK's pinned test stack and the selected Riverpod/build runner. Runtime and generator are therefore both pinned to `2.34.0` without dependency overrides.

## 7. Android configuration decisions

- Proposed `minSdk`: 24, driven by the selected current `path_provider` baseline.
- `compileSdk`: at least 35 for local notifications; use the stable SDK level generated/supported by Flutter after Phase 0. The machine has API 37 installed but still needs toolchain validation.
- Target the current stable Android API supported by Flutter at implementation time.
- Enable core-library desugaring and Java/Kotlin 17 bytecode for scheduled notifications.
- Add only notification permissions/receivers actually used. Do not add `INTERNET` to the release manifest.
- Prefer scoped storage and Android system pick/share flows. Do not request broad storage permissions.
- Use app-internal support storage for the live database and temp storage for staged backups.
- Store automatic recovery archives in application-private support storage, with no background service or broad storage permission. Drift changes are coalesced in-process and app pause/detach supplies the lifecycle checkpoint.
- Add a phone AVD (minimum supported API 24 plus a current API image) or use physical devices for integration tests.

## 8. Data flow examples

### Record attendance

1. The attendance engine projects the selected date's eligible timetable slots inside the active semester.
2. A whole-day action upserts one sparse `scheduled_class_attendance` record per projected class; a class action upserts only that class.
3. Calendar, Classes, Home, and subject history watch the same Drift-backed repository snapshot.
4. Day state is derived from explicit class marks plus any holiday/college-closed override.
5. Subject percentages count only explicit present/absent classes. Unmarked, cancelled, holiday, and college-closed classes are excluded.

Legacy `attendance_sessions` and `daily_attendance_records` remain isolated for upgrade and older-backup compatibility. The current UI never treats a calendar day as the attendance percentage source of truth.

### Edit a task deadline

1. Task repository updates the task.
2. Application service updates/invalidates related persisted reminders in the same logical operation.
3. Notification service cancels old OS notification IDs and schedules future enabled reminders.
4. If OS scheduling fails, task data remains saved and the UI reports the reminder-specific failure with a retry action.

### Notification projection

- SQLite stores only reminder intent (`reminder_at`) and the global enabled preference. Android pending notifications are disposable projections.
- Task and exam notification IDs occupy disjoint deterministic ranges derived from the local record ID, preventing collisions and duplicates without another mapping table.
- Creation/edit commands persist first, then schedule or cancel the matching projection. Completion and deletion always cancel it. Scheduling failure never rolls back or loses the task/exam itself.
- App startup initializes timezone data and reconciles all future reminder intent, cancelling stale CollegeOS IDs. Reconciliation also covers app updates, restore, timezone changes observed on launch, and schedules lost by the OS.
- On Android 12 and newer, CollegeOS offers the system-managed precise-alarm access when notifications are enabled or the first reminder is created. Scheduling uses `exactAllowWhileIdle` when that access is available and safely falls back to `inexactAllowWhileIdle` otherwise. Runtime notification permission is still requested only in context. No permanent background service is used.
- Payloads contain only a typed local route (`task:<id>` or `exam:<id>`). Taps route to the relevant Tasks or Exams screen, which remains recoverable if the record was removed.

## 9. Error handling and observability

- Define typed expected failures: validation, not found, permission denied, unsupported backup, corrupt backup, file access, database migration, and notification scheduling.
- Show contextual recovery: retry, open settings, choose another file, or keep current data.
- In debug builds, use local console logging with redacted values. Do not persist a growing log containing private notes and do not add remote crash reporting.
- A top-level Flutter error boundary presents a restart-safe screen; it never wipes or recreates the database automatically.

## 10. Quality gates

For every implementation slice:

1. Update plan and migration impact first.
2. Generate Drift code and confirm no stale generated output.
3. Format changed Dart files.
4. Run `flutter analyze` with no errors or warnings accepted by policy.
5. Run relevant unit/widget/database tests; run the full suite before milestone completion.
6. Run Android integration tests for platform work.
7. Build a debug APK regularly and a release APK at release milestones.
8. Inspect the release manifest to confirm there is no internet permission or unapproved SDK.

## 11. Reports and guidance

- Attendance reports are pure projections of the linked attendance engine, filtered by week, month, semester, and optional subject. They preserve the same exclusion and unmarked rules as the live UI.
- Offline Help is static application content. The post-setup guide appears immediately after successful first setup, while Help remains available from Settings later.

## 12. Android home-screen widget

- The widget is a read-only projection of the existing timetable and linked attendance engine; it owns no database and never writes attendance.
- Flutter persists only display-ready strings into Android widget preferences and redraws the native `RemoteViews` widget when visible data changes while CollegeOS is active.
- Identical projections are deduplicated to avoid repeated platform writes from the minute clock. Android may redraw the saved projection periodically, but CollegeOS does not run a permanent background service.
- At a date boundary, stale attendance is replaced with an explicit “Open CollegeOS to refresh” state rather than showing yesterday's totals as today's.
- Adding the widget uses Android's supported pin-widget flow from Settings, with the launcher widget menu as a fallback. Tapping the widget opens CollegeOS.
- This adds no schema, migration, backup-format, permission, network, analytics, or cloud change.

### Timetable CSV import

- Smart timetable import is an offline, preview-first adapter over the existing
  subject and timetable tables; it is not a second schedule model.
- CSV headers are matched case-insensitively with common aliases. Day, start,
  end, and subject are required; code, lecturer, room, and note are optional.
- Existing subjects are matched by short code and then name. Missing subjects
  are created with the current default attendance target only when the user
  confirms the preview.
- Exact duplicate slots are skipped. Overlaps are highlighted but remain
  importable, matching CollegeOS's unusual-schedule policy.
- Subject creation and timetable insertion share one Drift transaction. Imported
  entries are bounded to the active semester dates, and no historical attendance
  or timetable version is modified.
- This adds no schema, migration, backup-format, network, or cloud change.

## 13. Forecasting and academic-calendar automation

- Attendance forecasting is a pure domain projection over `AttendanceMetrics`. It evaluates one hypothetical future present class and one hypothetical future absent class through the same integer-safe calculator used everywhere else; it never writes or pre-generates attendance.
- Attendance planning generalizes forecasting to explicit future attend/miss counts while remaining a transient, read-only projection. Streaks and perfect-day insights are derived from exclusion-aware linked class records and are never persisted as analytics data.
- One-day timetable exceptions reuse inclusive effective dates for extra classes and sparse `cancelled` attendance for cancellations. This preserves recurring schedules, history, schema-v7 storage, and backup-format-v1 compatibility.
- The Android home widget adapts to compact and expanded launcher sizes. Compact mode prioritizes the next class; expanded mode adds today’s marking status and a completion bar. Its values remain disposable projections of local Drift data.
- Affected UI follows Android text scaling, high-contrast semantics, screen-reader descriptions, 48dp actions, and the platform reduced-motion flag. Decorative motion is disabled when `MediaQuery.disableAnimations` or accessible navigation requests it.
- “At risk” includes subjects already below target and fragile subjects that are currently on target but would fall below after one more absence.
- Academic-calendar impact previews project the existing versioned timetable across the selected date range and report how many class days/classes a holiday or closure will hide.
- Holiday, vacation, and study-leave presets reuse the existing `holiday` event type; exam periods remain informational. Existing calendar-event rows, schema version 7, and backup format 1 remain unchanged.

Implementation commands are defined in `ROADMAP.md`. Flutter 3.44.9 and the Android toolchain are now installed; Phase 1 and Phase 2 persistence commands run locally.
