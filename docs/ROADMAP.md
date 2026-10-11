# CollegeOS Implementation Roadmap

## Working method

Each milestone is a vertical, reviewable slice with acceptance criteria. Do not begin the next milestone while its required analysis/tests fail. No core feature ships as a TODO or placeholder. Database changes follow `DATABASE.md`; restore work follows `BACKUP.md`.

At the start of a milestone, confirm scope, affected tables/routes, migration impact, permissions, tests, and rollback. At the end, update docs where implementation differs from the plan.

## Phase 0 — Development environment readiness

**Goal:** make the inspected Windows machine capable of producing and testing an Android Flutter app.

Tasks:

1. Install official Flutter stable 3.44.9 (Dart 3.12.2 bundled) in a short, user-owned path and add `flutter\bin` to user `PATH`.
2. Set/verify Android SDK discovery for `C:\Users\Admin\AppData\Local\Android\Sdk`; install Android SDK command-line tools and a stable platform/SDK level supported by Flutter.
3. Run `flutter doctor -v`, accept Android licenses, and resolve Android toolchain errors.
4. Let Flutter select the JDK first. If JBR 25 is rejected by the generated Gradle toolchain, configure a supported JDK 17 or 21 and re-run doctor/build checks.
5. Install Flutter/Dart IDE support if desired.
6. Create phone AVDs for API 24 and a current supported API, or connect equivalent physical devices. The existing TV AVD is not sufficient for phone UX testing.
7. Re-check the candidate dependency table with `flutter pub get`; resolve only with supported stable versions and commit `pubspec.lock` once the project exists.

Exit criteria:

- `flutter --version` reports the chosen stable SDK.
- `flutter doctor -v` has no blocking Android errors.
- A generated sample can build and launch on a phone-sized emulator/device.
- Java, Gradle wrapper, AGP, compile SDK, and package solver compatibility are recorded.

## Phase 1 — Project foundation and design system

**Goal:** establish the real Flutter project without implementing product features.

Tasks:

- Create Android-first Flutter project and application ID.
- Apply feature-first folders, minimal bootstrap/main, Riverpod root scope, GoRouter skeleton, Material 3 themes, spacing/type/color tokens, and shared async/empty/error scaffolds.
- Add the resolved minimal dependencies and analysis rules.
- Configure min/compile/target SDK, Java 17 bytecode, desugaring prerequisites, and release manifest privacy baseline.
- Add CI-equivalent local scripts/documented commands without adding telemetry services.

Tests/gates:

- Theme widget tests in light/dark and large text.
- Router shell smoke test.
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

Exit criteria: five empty tab destinations render with stable state and no business-feature placeholders pretending to be complete.

## Phase 2A — Local persistence foundation

**Goal:** establish durable schema v1 and repository boundaries without implementing major UI.

Tasks:

- Implement Drift tables, DAOs, connection lifecycle, foreign-key/WAL setup, schema exports, repository contracts, clock/date value objects, and app settings.
- Implement singleton settings persistence and transactional active-semester selection.
- Export and commit the immutable schema-v1 snapshot.

Tests/gates:

- In-memory table constraints, CRUD/archive, foreign keys, cascades, active-semester uniqueness, repository mapping, aggregate queries, and file-backed reopen persistence.
- Generated-code freshness, schema validation, analyze, and full tests.

Exit criteria: schema v1 is durable and reactive, repositories isolate Drift from presentation code, and no schema operation can silently recreate data.

## Phase 2B — Settings integration and onboarding

**Goal:** add the transactional first-run experience on top of schema v1.

**Status (14 August 2026): complete and revised for schema v6.** The app uses the persisted singleton settings row as its startup gate, commits academic-year settings plus the current active semester in one transaction, exposes editable college information directly under Settings, and links first launch to the production restore flow completed in Phase 9.

Tasks:

- Implement onboarding for current academic-year and semester dates, persisted preferences, and active-semester selection.
- Implement typed validation/errors and destructive confirmation patterns.
- Commit onboarding in one database transaction so failures create no partial records.

Tests/gates:

- Onboarding rollback and repository mapping tests.
- Widget tests for skip/complete/relaunch flows and error states.
- Analyze, full tests, and debug Android launch.

Exit criteria: reinstall starts onboarding; completion persists across restart; and the app remains fully usable offline.

## Phase 3 — Semester and subject management

**Goal:** make academic structure fully manageable.

**Subject-management slice (12 August 2026): complete.** Subjects for the active semester now support add, edit, archive, and restore with reactive Drift persistence, settings-derived attendance targets, reusable cards, and no destructive-delete UI. Semester-management screens remain future work, so Phase 3 as a whole is not yet complete.

Tasks:

- Semester/subject lists, create/edit/archive/delete, active semester switching, filters, and impact-count confirmations.
- Subject visual tokens and default/per-subject attendance targets.
- Empty and historical states.

Tests/gates:

- CRUD/repository/transaction tests and cascade impact tests.
- Navigation and form widget tests.
- Analyze, full tests, manual dark/light phone review.

Exit criteria: multiple semesters and subjects are reliable, and historical data remains accessible.

## Phase 4 — Attendance core

**Goal:** deliver the highest-risk feature with mathematically trusted results.

Tasks:

- Pure attendance calculator and aggregate DAO query.
- Individual session add/edit/delete/history and bulk quick entry that writes individual records.
- Overall and subject dashboard visualizations, target states, safe bunks, recovery classes, and cancelled counts.
- Quick entry from Attendance and Home-ready application APIs.

Tests/gates:

- Exhaustive unit cases around zero classes, exact target, rounding boundaries, cancelled sessions, multiple same-day classes, 100% target, and large counts.
- DAO aggregate equivalence against a simple reference implementation.
- Widget/golden tests for above/at/below/no-data states in both themes and large text.
- Performance test with at least 20,000 sessions.

Exit criteria: all attendance screens derive from session rows and never accept a typed percentage as source data.

## Phase 5 — Timetable and Home dashboard

**Goal:** support daily planning and fast attendance capture.

Tasks:

- Weekly/day timetable, recurrence ranges, overlap warning, entry management, and today's schedule.
- Home composition: next class, quick attendance, attendance risks, open/overdue task slots, and next exam slots with honest empty states.
- Preserve tab and scroll state.

Tests/gates:

- Weekday/date-range/overlap unit tests.
- Timezone-safe local-date widget tests.
- Home reactive update tests after attendance/semester changes.
- Phone-size manual tests for dense schedules.

Exit criteria: today's dashboard and timetable remain correct across restart and local timezone changes.

## Phase 6 — Tasks and assignments

**Goal:** complete offline task planning.

**Status (12 August 2026): complete.** General, assignment, and study tasks share one reactive repository and UI. Schema v2 adds nullable wall-clock due time with a tested v1→v2 data-preserving migration. CRUD, priority, optional subject, date/time, persisted reminder intent, completion/reopen, filters, overdue ordering, and Home integration are implemented.

Tasks:

- General/assignment CRUD, due date/time, priority, subject/semester filters, open/overdue/completed views, completion/reopen, and Home integration.
- Date-only semantics and typed subject/semester validation.

Tests/gates:

- Due/overdue boundary tests with injectable clock.
- Repository filters and completion invariants.
- Form/list/detail widget and navigation tests.

Exit criteria: all task flows work without notifications and remain useful when notification permission is denied.

## Phase 7 — Exams and marks

**Goal:** track assessment schedule and outcomes without misleading aggregates.

**Status (12 August 2026): complete.** Exams now support reactive create, edit, delete, upcoming/past grouping, calendar-safe countdowns, and Home integration. Marks are recorded per subject using stable categories, validated raw scores, safe percentages, and clearly labelled simple totals. The UI deliberately makes no SGPA/CGPA claim and leaves institutional grading configuration for a later phase. The existing schema v2 already contained the required exam and marks fields, keys, checks, and indexes, so this phase required no migration and remains compatible with the planned full-database backup format.

Tasks:

- Exam CRUD, upcoming/past views, Home next-exam integration.
- One result per exam, mark validation, raw/percentage display, optional weighted summaries, and clearly labelled incomplete-data states.

Tests/gates:

- Constraint and calculation tests, including missing maximum/weights.
- Cascade and one-result uniqueness tests.
- Exam/marks screen and accessibility tests.

Exit criteria: results are mathematically honest and changes react throughout the app.

## Phase 8 — Local notifications

**Goal:** project persisted reminders into Android notifications reliably.

**Implementation status (13 August 2026): complete.** Task, assignment, and exam reminder intent is persisted in SQLite and projected to `flutter_local_notifications` using timezone-aware, inexact-while-idle Android schedules. Class reminders joined the same contract in schema v14: each timetable class stores an optional lead time in minutes before the class start (presets plus a custom setter), and exactly one alarm is projected for that class's next eligible occurrence, skipping holidays, college-closed days, cancelled classes, one-day exceptions, archived subjects and semester breaks. Class notification IDs occupy their own band, a dedicated sync channel owns the namespace, and the projection is rebuilt whenever the app runs. The temporary diagnostics panel was removed after device verification; the native permission and channel query it needed stays. Permission is requested only from the notification Settings toggle or first reminder save. Stable disjoint task/exam IDs prevent duplicates; create/edit/complete/delete operations schedule or cancel appropriately; startup and restore reconciliation repair stale projections; notification taps route to the relevant local item where available. Schema v4 adds nullable exam reminder intent with tested migrations and schema-v1 through schema-v3 backup compatibility. No Firebase, push server, internet permission, exact-alarm privilege, analytics, or permanent background service is present.

Tasks:

- Notification service abstraction, Android initialization/channels, timezone discovery, permission flow, reminder CRUD, scheduling/cancellation, notification deep links, boot/update behavior, and reconciliation on launch.
- Use inexact while-idle by default. Add no exact-alarm permission unless the user explicitly approves a precise-reminder feature.
- Add only required manifest receivers/permissions and enable desugaring per the resolved plugin version.

Tests/gates:

- Unit tests with mocked platform adapter for create/edit/complete/delete/timezone/permission cases.
- Router payload tests.
- Android integration tests on API 24, 33+, and current API for permission, tap, reboot/update where testable.
- Inspect pending requests for stale entries.

Exit criteria: reminder failure never loses task/exam data, and permission denial is fully supported.

## Phase 9 — Backup and restore

**Goal:** prove complete phone-to-phone portability.

**Implementation status (13 August 2026): complete for the application layer and automated acceptance.** CollegeOS exports and shares one validated `.collegeos` ZIP containing `manifest.json`, `data.json`, and `attachments/`; imports through the native picker; previews the snapshot; creates a private emergency backup; and restores all datasets atomically with preserved IDs. The same serializer powers optional application-private recovery snapshots with newest-five retention. Schema v5 adds daily calendar attendance while retaining legacy sessions and schema-v1-v4 backup compatibility. Automated round-trip, hostile-file, version, relationship, rollback, retention, coordinator, and UI confirmation tests pass. A two-device native picker/share transfer remains a release-candidate manual check.

Tasks:

- Streaming snapshot, hash, manifest, archive, share, pick, safe validation/extraction, staged migration, atomic replacement, rollback, cleanup, progress UI, and notification rebuild.
- Add immutable backup/schema fixtures.

Tests/gates:

- Entire matrix in `BACKUP.md`, including injected failure at every restore stage.
- Full table-by-table round-trip and settings/theme/onboarding preservation.
- Manual export on one emulator/device and import on another.
- Memory/performance test with a large fixture.

Exit criteria: a failed restore preserves current data; a successful restore reproduces all user-visible state and future reminders.

## Phase 10 — Polish, hardening, and release candidate

**Goal:** produce a dependable personal release build.

Tasks:

- Cross-feature UX consistency, responsive phone layouts, accessibility, subtle motion, empty/loading/error recovery, and performance profiling.
- Validate every destructive action, migration, and notification lifecycle.
- Test upgrade from previous signed build without clearing data.
- Prepare local signing/release instructions without adding a distribution backend.

Required final gates:

```text
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter build apk --release
```

Also inspect the merged release manifest/APK permissions and dependency graph. The release candidate fails if it contains `INTERNET`, analytics, trackers, advertising, account/login, Firebase/Supabase, or an unexplained native SDK.

Exit criteria: the complete v1 definition in `PRODUCT_SPEC.md` is met on a physical Android phone and the signed upgrade/backup paths preserve data.

## Post-v1 usability and insight milestone

**Implementation status (14 August 2026): implemented.** This milestone adds date-range academic calendar events and semester rollover, grouped pending-attendance review, week/month/semester/subject attendance reports, an offline Help center, and first-setup guidance. Database schema v7 and backup-format-v1 compatibility preserve existing data and older imports.

Acceptance requires clean formatting/analyzer/tests, migration and backup round-trip coverage, and Android compilation.

## Continuous testing strategy

### Unit tests

- Attendance math, mark math, date/time value objects, validation, reminder reconciliation, backup manifest parsing, and typed failure mapping.
- Use an injected clock/timezone; never make boundary tests depend on the real current time.

### Database tests

- In-memory DAO/repository tests, foreign-key/cascade/check constraints, transactions, aggregate queries, schema exports, and migrations from fixture databases.
- Run integrity and foreign-key checks after migration and backup restore.

### Widget and golden tests

- Forms, empty/loading/error states, destructive confirmations, tab state, accessibility semantics, light/dark variants, large text, and attendance visual states.
- Keep goldens focused on stable high-value components rather than every screen.

### Integration tests

- Onboarding through daily workflows; task/exam notification permissions and taps; export/import/rollback; app restart; schema upgrade; and release-mode permission inspection.
- Test API 24 plus current Android, with API 33+ notification permission coverage.

### Manual acceptance

- Real-phone one-handed quick entry, dark mode, battery-restricted notification behavior, Android picker/share interactions, timezone change, low-storage failure, app update without data clearing, and phone-to-phone backup transfer.

## Milestone completion report template

For each phase report: implemented scope, files/schema/routes changed, migration/backup impact, tests and commands run with results, known non-core limitations, manual checks, and the next approved phase. Do not claim completion when a required command could not run.
