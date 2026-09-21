# CollegeOS working rules

- CollegeOS is offline-first. All user data stays on the device.
- Never add Firebase, Supabase, login, accounts, cloud syncing, backend services, advertisements, trackers or analytics unless the user explicitly asks.
- Plan everything first. Read `docs/` and state the implementation and migration plan before changing behavior or persistence.
- Keep the app Android-first and use Flutter, Dart, Material 3, Riverpod, GoRouter, and Drift/SQLite.
- Use feature-first modules and keep UI, state/application logic, domain logic, database code, and repositories separated. Keep `main.dart` minimal.
- Attendance is class-based and timetable-driven. Calendar and Classes are linked projections of the same scheduled-class records. Never derive attendance percentage from calendar days; count only explicitly present/absent class sessions, excluding unmarked, cancelled, holiday, and college-closed dates.
- Preserve existing data. Every schema change needs an explicit, tested Drift migration and backup compatibility consideration.
- Run formatting, code generation when applicable, `flutter analyze`, and relevant tests for each milestone. Fix failures before proceeding and do not leave core-feature TODOs.
- Prefer strong types, reusable components, accessible empty/loading/error states, and the smallest justified dependency set.
