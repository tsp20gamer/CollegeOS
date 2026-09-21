# CollegeOS personal Android release checklist

## Automated gates

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- Inspect the merged release manifest and reject `android.permission.INTERNET`, analytics, trackers, or cloud SDKs.
- Confirm package `com.collegeos.app`, version, minimum SDK, target SDK, signing certificate, APK size, and SHA-256.

## Upgrade and data safety

- Install over the previous signed personal build; do not uninstall when preserving device data.
- Open an existing schema-v7 database and verify settings, timetable, attendance, tasks, exams, and marks.
- Export a `.collegeos` backup, restore it into a clean test database, and compare all relationships.
- Confirm older backup-format-1 archives remain accepted.

## Device checks

- Fresh onboarding and restart persistence.
- Light/dark themes at 360–430 logical pixels.
- Add and refresh the home-screen widget using the device launcher.
- Mark a timetable date as holiday; verify classes disappear from Attendance, Home, and widget, then undo and verify prior marks return.
- Verify task/exam notification permission, scheduling, editing, completion, deletion, and notification taps.
- Verify backup export/import through Android’s system file workflow.

## Release policy

CollegeOS remains offline-only. A release must not contain login, accounts, Firebase, Supabase, backend services, cloud sync, advertisements, trackers, analytics, or a required network permission.
