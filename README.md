# CollegeOS

CollegeOS is a private, Android-first, offline college productivity app built with Flutter and Material 3. It combines semester planning, subjects, class-level attendance, a weekly timetable, assignments, exams, marks, reminders, notes with offline PDF search, portable backups, and a home-screen widget in one application that stays fully usable with no connection.

## Status

Current release: **v1.15.0** (`1.15.0+36`). The core v1 product and the post-v1 usability/insight milestone are complete. Milestone history lives in `docs/ROADMAP.md`; the release process lives in `docs/RELEASE_CHECKLIST.md`.

## Tech stack

- Flutter 3.44.9 / Dart 3.12.2, Material 3
- Riverpod for state management and dependency wiring
- GoRouter with a persistent navigation shell
- Drift/SQLite for local persistence (schema version 16)
- `flutter_local_notifications` for offline reminders
- Bundled Lottie assets for the dock animations

## Features

- **Onboarding** — resumable local first-run setup, committed in one transaction
- **Semesters & subjects** — multiple semesters with one active, archive/delete, per-subject attendance targets
- **Attendance** — class-based, timetable-driven linked attendance with calendar/classes views, planner, analytics, forecasting, and undo
- **Timetable** — weekly recurrence with versioned effective dates, one-day exceptions, and CSV/xlsx/docx import
- **Tasks** — general/assignment/study tasks with due dates, priorities, and filters
- **Exams & marks** — assessment schedule and validated, honestly labelled results
- **Notes & files** — per-subject notes, PDF attachments with a full-screen reader, and offline full-text PDF search with on-device OCR
- **Reminders** — offline local notifications for tasks, exams, and classes
- **Home widget** — Android launcher widget showing the next class and today's attendance
- **Backup & restore** — portable `.collegeos` export/import with validation and rollback
- **Updates** — optional in-app updater that reads a public version manifest

## Architecture

The codebase follows a feature-first clean architecture. Dependencies point inward from presentation (screens/widgets) through application (Riverpod controllers) and domain (pure business rules) to data (Drift repositories and platform adapters) and SQLite. Full detail is in `docs/ARCHITECTURE.md`.

```text
lib/
  main.dart            # binding + bootstrap only
  app/                 # MaterialApp.router, startup orchestration
  core/                # database, routing, theme, notification services
  features/            # one module per feature (domain/data/application/presentation)
  shared/              # reusable widgets
```

## Development

Requires Flutter 3.44.9 (Dart 3.12.2) and an Android toolchain.

```text
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

`flutter build apk --release` is the release build; see `docs/RELEASE_CHECKLIST.md`. Database schema and migration policy are documented in `docs/DATABASE.md`; backup and restore behavior in `docs/BACKUP.md`.

## Privacy

CollegeOS has no login, accounts, backend, cloud sync, advertising, trackers, or analytics. All user data stays on the device and moves between phones only through an explicit backup file. The single network feature is the optional release check, which reads a public `version.json` to offer updates and downloads nothing unless the student taps Update.
