# CollegeOS

CollegeOS is a private, Android-first, offline college productivity app built with Flutter and Material 3.

Phase 1 establishes the application shell, Riverpod root scope, GoRouter navigation, responsive light/dark design system, reusable state widgets, and five main destinations. Database and business features begin in later phases described in `docs/ROADMAP.md`.

## Development checks

```text
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

The app intentionally has no login, backend, cloud sync, analytics, advertising, or release-time internet permission.
