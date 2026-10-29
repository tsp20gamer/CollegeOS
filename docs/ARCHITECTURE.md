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

Settings keeps a notification check sheet with the Android permission/channel
state, the count of scheduled CollegeOS reminders, a test action, a one-tap
reconciliation action, and the Android notification-settings shortcut.
`AndroidNotificationPlatform` owns the narrow native permission and
reminder-channel query it needs to decide whether reminders can actually be
delivered on this device.

Riverpod code generation is intentionally omitted at first to reduce generators and dependencies. Drift remains the only required code generator. Reconsider only if hand-written provider maintenance becomes materially worse.

## 5. Navigation design

The bottom navigation is a floating translucent dock. It keeps a 16 px margin
from the left and right screen edges and 12 px above the system inset, and paints
a 24 sigma backdrop blur under a white 8 % fill on the dark theme (75 % on light)
with one soft shadow and a hairline rim, at radius 28. Its content strip is
64 px tall (`AppLayout.navigationBarHeight`), which keeps the dock clear of a
pill radius while giving the icon, label and dot slot a little more room. All
five destinations keep
their icon and label at every width: labels are clamped to a 1.3 text scale factor
and all five are drawn at one type size measured from the widest name — the row
steps down together until that name fits its slot instead of each label shrinking
on its own, so "Home" and "Attendance" never read at two different sizes — and a
label is never truncated or hidden. Selection
paints no capsule: the chosen destination gets the cobalt icon, a cobalt label and
a 4 px cobalt dot, and its dot slot is reserved whether or not the dot is showing,
so no label ever moves. Each destination's glyph is a bundled Lottie animation
(`assets/lottie/`) painted in one colour through a `srcIn` filter — cobalt when
chosen, muted otherwise — so five animations with five different palettes speak
the dock's single accent in both themes. The five are one drawn family authored
for the dock: a 36 px artboard at 60 fps where the subject strokes and fills
itself in over 90 frames, with a shared 4.5 % settle at the end.The artwork
  carries a cyan → cobalt → violet gradient that the `srcIn` filter flattens, so
  the gradient lives only in the source files. Every outline, ring, panel and
  marked day also carries a soft glow stroke painted at 28 % opacity and roughly
  twice the line's own width — the halo is part of the family's weight, so a
  glyph drawn without it reads visibly lighter than its neighbours. Their held frames still draw their
subjects at different sizes, so each destination carries a measured `glyphScale`
that lands its held subject on the same ~19 px of ink inside the 24 px slot: Home,
Attendance, Timetable, Tasks and Notes read as one size, and no glyph looks smaller
than its neighbours. Each destination rests at 1 — the finished frame — because
every one of them begins on an empty
canvas; resting an unselected destination on frame 0 would leave it blank, and
choosing it therefore replays the drawing while the finished frame stays the
still image. Only the newly selected icon animates: it
plays its animation once, accelerated to `AppDurations.dockLottieMaxPlayback`
(600 ms), while it makes a 240 ms pop to 1.10 and back through 1.04 with a 2.5 px
lift, and then holds the animation's final frame; leaving a destination returns it
to its resting frame, and the destination that is already selected when the dock
mounts rests on its final frame instead of animating on launch. Meanwhile the
retained tab subtree makes a 150 ms translation of 1.2% of its width with no
full-page opacity layer. Android reduced-motion and accessible-navigation settings
disable all of that decorative movement — those destinations show the Material
icon the dock used before, as does any destination whose animation cannot be
loaded — while leaving the glass itself unchanged.

Because the shell uses `Scaffold.extendBody`, the dock's measured height — its
content plus the floating gap and the system inset — is folded into
`MediaQuery.padding.bottom` for the body, so `AppLayout.scaffoldBottomPadding`
derives content clearance from the resolved padding. A route pushed above the
shell sees only the system inset, which is what makes the same helper correct
both inside and outside the shell.

Navigation itself moves. Every pushed route fades in while rising the last 14 px
and settling from 0.985 scale, and sinks and fades away as it leaves — one
`CollegePageTransitionsBuilder`, mounted through `PageTransitionsTheme`, so no
screen defines its own. Beneath it, every `AppScaffold` screen's content settles
in once with a short fade-and-rise (`Entrance`), the screens a day is scanned
top-to-bottom — Home, Attendance, Notes and Tasks — stagger their sections in
40 ms steps so a screen assembles as a wave instead of appearing as one block,
the attendance ring counts its percentage up as the ring fills, and tappable
cards press in and spring back through the same `PressScale` the dock uses.
The dock's rise-and-settle is the app's icon gesture, not just the dock's:
`AppMotion.popScale` defines the one 1.0 → 1.10 → 1.04 → 1.0 sequence the
dock's chosen icon and every `IconPop` share, so a section header's coin and a
subject monogram grow into place as their card arrives, a completed task's tick
pops inside its box, and an attendance mark pops when it is chosen. Header
actions, the back button, extended FABs, Home's quick-action chips and the small
date and stepper controls all press in through `PressScale` too, and a finger
that slides past the touch slop releases the press so starting a scroll never
leaves a card held down. Every timing and distance lives in `AppDurations`,
`AppCurves` and `AppMotion` in `animation_tokens.dart`, `Entrance` and `IconPop`
are the two widgets staged reveals and icon pops go through, and each piece
renders its final frame immediately when Android asks for reduced motion or
screen-reader navigation.

A document is read full-screen. Every PDF opens through `PdfViewerScreen.open`,
which pushes on the root navigator so the floating dock cannot end up over the
page the student opened — the same reason Settings is a top-level route. The
viewer's right edge then carries the document's scroller: a 4 px groove with a
cobalt thumb that stays visible instead of fading out, is centred under the
finger while dragging, names the page in a bubble, and steps a page at a time
from slider semantics. Syncfusion's viewer owns its own scrolling and exposes no
pixel extent, so the rail is honest about what it can measure: it maps the
document's pages to the thumb's travel, and a tap or a drag anywhere on the rail
turns to that page.

Settings is deliberately not a destination. Each tab header exposes it through
`AppScaffold.showSettingsAction`, and `/settings` is a top-level route that pushes
over the shell so it keeps a back button. `AppScaffold` also supplies a back
affordance to every pushed screen, and wraps its header actions so a compact
phone with several actions at a large text scale wraps instead of overflowing.
It offers no notes-search action: the Notes destination owns the library and its
search field is the single entry point into PDF search, so every header carries
Settings alone and nothing competes with it on a compact phone.

The Attendance destination leads with its two tools as named entries instead of
header icons. Planner and Analytics each get a card-sized tile carrying a name, a
line of purpose and a 40 px icon coin, side by side while both names fit on two
lines each and stacked full width below the phone width in
`AppLayout.compactPhone` or at a large text scale. They sit above the Day/Subject
views and outside the semester's loading and empty states, because Analytics
projects every semester rather than only the active one.

The Notes destination is a library rather than a settings list. Its header card
holds the search field and the size of what is below it — subjects, files, pages
PDF search has indexed and space on the device — measured from one stream of the
student's files narrowed to the listed subjects, so the totals and the list can
never disagree. Each material chip counts what it holds. Each subject is one card
with a monogram in that subject's own display colour, its code, room, note and
file counts. File rows open on tap and have separate Open and Share actions; PDFs
open in the in-app reader and other formats use the device's file handler. A PDF
keeps the cobalt tile; other formats stay neutral and are told apart by their
glyph, so the library never invents a second accent.

The Timetable day bar keeps one strip one surface step above the canvas and one
cobalt circle on the selected day. The circle takes its diameter from the day
label's own line height plus its breathing room, so it always closes around the
word it marks and the selection stays legible on both the light and the dark
strip — a wide capsule at the strip's own contrast disappeared into the surface.
It glides between the equal-width Mon–Sat slots over 260 ms on an emphasized
curve while each label animates its colour and weight, and the chosen day's
heading and class list cross-fade and slide 2% of their width from the direction
of travel over 220 ms. Reduced motion collapses both to zero duration, and no day
paints a background of its own, so the circle is the only thing that moves and no
label ever shifts.

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
| `http` | `^1.6.0` | Reads the published release manifest for the update check |
| `dio` | `^5.11.1` | Streams the release APK download with progress and cancellation |
| `open_filex` | `^4.7.0` | Hands the downloaded APK to Android's package installer |
| `lottie` | `^3.6.1` | Plays the dock's bundled destination animations from local assets; no network path is used |

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
- Declare only the permissions the app actually uses: `INTERNET` (the release check), `REQUEST_INSTALL_PACKAGES` (handing a downloaded update to Android's installer), the notification, exact-alarm and boot receivers, and the data-sync foreground service. `open_filex` contributes storage and media read permissions; all four are removed with `tools:node="remove"` because the updater only opens an APK from the app's own cache through that plugin's FileProvider.
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

- SQLite stores only reminder intent (`reminder_at` for tasks and exams, `timetable_entries.reminder_minutes_before` for classes) and the two gating preferences: the global `notifications_enabled` master and the class-only `class_reminders_enabled` with its default lead time `class_reminder_minutes_before`. Android pending notifications are disposable projections.
- Task, exam, attendance and class reminder notification IDs occupy four disjoint deterministic ranges derived from the local record ID: tasks are positive, exams the same id negated, attendance is reserved as zero, and class reminders start at `classReminderNotificationIdBase`. No mapping table is needed and no two records can collide.
- A class reminder is a lead time rather than an instant, so `ClassReminderPlan` projects exactly one alarm per class: its next eligible occurrence, computed from the same day model attendance uses. Holidays, college-closed days, cancelled classes, one-day exceptions, archived subjects and semester breaks are therefore skipped without a second calendar, and `0` reminds at the class start.
- Creation/edit commands persist first, then schedule or cancel the matching projection. Completion and deletion always cancel it. Scheduling failure never rolls back or loses the task, exam or saved class itself.
- App startup initializes timezone data and reconciles all future reminder intent, cancelling stale CollegeOS IDs. Reconciliation also runs whenever the app resumes, covering alarms dropped while idle as well as app updates, restore, timezone changes observed on launch, and schedules lost by the OS.
- The class namespace is owned by its own serialized sync: the desired projection is recomputed from the stored timetable, the calendar and the clock, stale class alarms are cancelled, changed lead times are replaced and unchanged ones are left alone. Both the class-notifier switch and the global master gate that projection, so turning class reminders off empties the namespace and cancels every class alarm while tasks and exams keep working. `TimetableDao.setReminderForSemester` backs "Apply to all classes": it writes only the lead time, on rows that are still current or future, without versioning timetable history, because a lead time changes what Android announces rather than what a class record meant on a past date. Startup reconciliation deliberately skips class payloads so it can never wipe them before that sync runs, and the projection provider reports `null` ("leave the namespace alone") while its inputs are still loading instead of treating a slow read as "no reminders".
- On Android 12 and newer, CollegeOS offers the system-managed precise-alarm access when notifications are enabled or the first reminder is created. Scheduling uses `exactAllowWhileIdle` when that access is available and safely falls back to `inexactAllowWhileIdle` otherwise. Runtime notification permission is still requested only in context. No permanent background service is used.
- Payloads contain only a typed local route (`task:<id>`, `exam:<id>` or `classReminder:<id>`). Taps route to the relevant Tasks, Exams or Timetable screen, which remains recoverable if the record was removed.

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
8. Inspect the merged release manifest to confirm it carries only the permissions listed in §7 — no storage or media reads, no analytics, tracker or cloud SDK — and that the published `version.json` names the version the APK reports.

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

## 14. Release channel and in-app updates

- A release is a **tag**, not a manual upload. Pushing `v<major>.<minor>.<patch>` runs `.github/workflows/release.yml`, which checks the tag out, restores the gitignored `env.json` asset and the release keystore from repository secrets, runs `flutter analyze` and `flutter test`, builds the release APK, publishes it as a GitHub Release, and rewrites `version.json` on `main` so installed builds can find it. The tag must equal the `version:` name in `pubspec.yaml`; the workflow fails before building otherwise, because the app compares version names and an APK whose name disagrees with the manifest would keep offering itself as an update.
- `version.json` at the repository root is the channel's whole contract: `latest_version`, `apk_url`, `changelog` and `force_update`. It is read from `main`, so a release goes live the moment the workflow commits it, and a release APK must be signed with the keystore installed builds already trust or Android rejects the upgrade.
- The check reads a public file and nothing else — no user data, identifiers, accounts, analytics or trackers. The APK is fetched only after the student taps Update, and Android's own installer performs the upgrade, so no local database is replaced silently.
- Downloads go through the release worker first: `https://apicollegeos.steja3471.workers.dev/?download=1` redirects to the newest published APK, and the manifest's pinned `apk_url` is the fallback when the worker cannot be reached. Dio follows the redirects in place, so progress, cancellation and the installer hand-off are unchanged, and neither source sees anything but the request itself.
- The app never blocks on the channel. `UpdateService` runs once per launch from Home after the first frame, stays entirely silent about failures, and only an explicit Check for Updates in Settings reports "up to date" or "could not check". An unreadable or older manifest is treated as no update, never as a downgrade.
- None of this changes the schema, a migration, or the backup format: the updater reads no stored data and writes none.

Implementation commands are defined in `ROADMAP.md`. Flutter 3.44.9 and the Android toolchain are now installed; Phase 1 and Phase 2 persistence commands run locally.
