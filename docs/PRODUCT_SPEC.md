# CollegeOS Product Specification

## 1. Product statement

CollegeOS is a private, Android-first college productivity application for one person. It combines semester planning, subjects, session-level attendance, a weekly timetable, assignments, exams, marks, reminders, settings, and portable backups in one offline application.

The product must remain useful with airplane mode permanently enabled. It has no identity system, remote service, advertising, analytics, or required internet permission. The user owns the only authoritative copy of the data and can move that data between phones through an explicit backup file.

## 2. Product principles

1. **Offline is complete, not degraded.** Every core workflow reads and writes only local device storage.
2. **Data is inspectable and portable.** The user can export, transfer, validate, and restore a full backup without an account.
3. **Attendance is evidence-based.** Percentages are always derived from individual class-session records.
4. **Fast daily use wins.** Recording a class, checking today's schedule, or completing a task should take very few taps.
5. **Calm, premium presentation.** Material 3, strong typography, restrained color, clear hierarchy, and subtle motion support the work instead of decorating it.
6. **Updates do not erase data.** Database migrations and backup compatibility are release gates.

## 3. Users and scope

The v1 user is the device owner. There are no shared colleges, faculty portals, collaborative spaces, or multi-user roles.

### In scope for v1

- First-time setup and editable personal preferences
- Multiple semesters with one active semester
- Subjects within semesters and per-subject attendance targets
- Individual attendance sessions with present, absent, or cancelled status
- Weekly recurring timetable
- General tasks and subject assignments
- Exams and recorded marks
- Locally scheduled reminders
- Light, dark, and system theme modes
- Full export, share, import, validation, and restore

### Explicitly out of scope

- Login, signup, accounts, authentication, or profiles for multiple users
- Firebase, Supabase, a backend, cloud sync, cloud storage, or required networking
- Analytics, crash trackers, telemetry, ads, or growth SDKs
- Faculty/student portals, collaboration, messaging, fee payments, or LMS integrations
- Automatic attendance imported from an institution
- Attachments in v1; the backup layout reserves room for them later
- iOS and desktop release work; the architecture must not prevent later ports

## 4. First-time setup

The onboarding flow is local and resumable until committed. It collects:

- College name, course, and branch
- Current semester number and academic year label
- Academic-year start and end dates
- Current-semester start and end dates, constrained inside the academic year
- Default attendance target, initially 75%

Completion is one database transaction that creates settings, the current active semester, and the onboarding-complete flag. A partially completed form must not create orphan data. Notification permission is not requested during onboarding. After completion, startup goes directly to Home. Settings provides later editing; onboarding is not shown again unless the database is deliberately reset or an imported backup says it is incomplete.

## 5. Main navigation and information architecture

Use a floating translucent glass dock with five persistent destinations:

1. **Home** — overview and next actions
2. **Attendance** — aggregate health, subjects, and rapid session entry
3. **Timetable** — weekly schedule and today's classes
4. **Tasks** — assignments and general tasks
5. **Notes** — per-subject material and search over every indexed PDF

The dock floats above the content with a translucent, blurred surface. Every destination keeps its icon and label at any width; the selected one is marked by a cobalt icon, a cobalt label and a micro dot, never by a capsule behind it. Settings is deliberately not a destination: each destination header exposes it, and it opens above the shell.

Each destination preserves its navigation stack and scroll position when switching tabs. Forms and details open above the relevant tab. Onboarding and full-screen restore progress live outside the tab shell.

## 6. Functional requirements

### 6.1 Home dashboard

- Shows the active semester and an empty-state call to create/select one when absent.
- Shows today's timetable, linked class-attendance summary, upcoming tasks, and next exam.
- Highlights only actionable information: today's attendance status, items due soon, and the next class.
- Today's classes come from the weekly timetable and offer explicit per-class or whole-day attendance actions with duplicate-safe upserts.
- Handles no subjects, no schedule, and no tasks without dead space or fake sample data.

### 6.2 Semester management

- Create, edit, archive, delete, and activate semesters.
- Permit only one active semester at a time.
- Warn before deleting a semester because related subjects, sessions, tasks, exams, marks, timetable entries, and reminders are removed.
- Prefer archive for historical semesters; archived data remains available and is backed up.
- Validate non-empty name and start date not after end date.

### 6.3 Subject management

- Create, edit, archive, and delete a subject within a semester.
- Store name, optional short code, color token, instructor, room, credits, and attendance target.
- Initialize the target from the app default, and re-target every existing subject when that default changes, so Attendance, the planner and Analytics all compare against the target the student chose. A per-subject override is still allowed.
- Subject deletion requires explicit confirmation and explains its cascading impact.

### 6.4 Attendance

Attendance is class-based and timetable-driven. The source of truth is a sparse explicit scheduled-class record with status `unmarked`, `present`, `absent`, or `cancelled`; unmarked timetable projections do not require a database row. Calendar and Classes are linked views of the same records.

The monthly calendar derives semantic day states (present, absent, partial, partially marked, unmarked, holiday, college closed, no classes, or outside semester). Whole-day Present/Absent writes every scheduled class, while per-class edits can create partial attendance. Holidays and college-closed overrides mask the schedule without deleting prior marks, so undo is reversible.

Subject percentages remain class-based: `present / (present + absent)`. Unmarked, cancelled, holiday, and college-closed classes never count. Legacy session/day tables remain stored only so existing installations and old backups do not lose data; schema-v6 migration converts only records whose relationships can be inferred safely.

### 6.5 Weekly timetable

- Recurring entries belong to a subject and specify ISO weekday, start/end minute, optional room, and active date range.
- Week view emphasizes today and supports day-focused phone layouts.
- Detect overlapping entries and warn; allow save only after the user confirms because real timetables can overlap.
- Timetable entries project eligible unmarked classes. Explicit attendance records are created only when the user marks or cancels a class.
- Semester changes filter the schedule without deleting historical entries.

### 6.6 Tasks and assignments

- One unified task model with type `general` or `assignment`.
- Store title, optional details, semester, optional subject, due local date, optional due time, priority, status, and completion timestamp.
- Views: upcoming, overdue, completed, and subject filter.
- Completing or reopening a task updates reminders consistently.
- Date-only items remain date-only; the UI must not invent a visible midnight deadline.

### 6.7 Exams

- Store exam name/type, subject, local date, optional start/end time, venue, optional maximum marks, optional weight, and notes.
- Show next exam on Home and chronological upcoming/past lists.
- Validate end time after start time and positive maximum marks.
- Exam deletion cascades to its mark and reminders only after confirmation.

### 6.8 Marks

- A completed exam may have one marks record with obtained marks, optional grade, optional published date, and notes.
- Validate obtained marks as non-negative and not greater than the exam maximum when a maximum exists.
- Calculate exam percentage from obtained/maximum marks; do not store that percentage.
- Show subject-level totals only when the data is mathematically comparable. Weighted totals require weights; otherwise show individual results and a clearly labelled simple aggregate, never an implied official GPA.

### 6.9 Local notifications

- Support reminders for tasks, exams, and timetable classes without a network connection.
- Persist reminder intent in SQLite; operating-system notification schedules are a rebuildable projection.
- Treat a class reminder as a lead time before every occurrence of that class, not a one-off instant: presets plus any custom lead time from the class start up to seven days earlier.
- Project one alarm for each class's next occurrence and respect the academic calendar while doing it: holidays, college-closed days, cancelled classes, one-day exceptions, archived subjects, and semester breaks never remind about a class that will not happen.
- Settings exposes a **Class notifier**: a switch that pauses class reminders on its own (independently of the global notifications switch, which keeps controlling tasks and exams) and a reminder time offered to every class that has no reminder of its own. Below them, "Apply to all classes" writes that time onto every current and future class in the active semester after confirming that individually set per-class reminders will be replaced.
- A new class starts from the class notifier's reminder time, so asking for class reminders once configures the whole timetable. Classes whose effectiveness has already ended, and other semesters, are never rewritten.
- Ask for notification permission in context and keep the app fully usable if denied. While the global notifications switch is off, the class notifier section says so and offers to turn it on rather than silently doing nothing.
- Use device timezone data and reschedule after restore, relevant data edits, timezone changes detected on app launch, and application updates.
- Use inexact while-idle scheduling by default to avoid unnecessary exact-alarm privilege. If exact reminders are later offered, request `SCHEDULE_EXACT_ALARM` transparently and degrade gracefully when denied.
- Notification taps deep-link to the related task, exam, or timetable.
- Past, completed, deleted, or disabled items must not leave stale notifications.

### 6.10 Settings

- Edit student/college labels, default attendance target, theme, week start, notification preferences (including the class notifier), and date/time display preferences.
- Show application and database schema version for support.
- Provide Backup & Restore and a destructive local reset behind explicit confirmation.
- No analytics or privacy toggles are needed because no telemetry exists.

### 6.11 Backup and restore

The user can export a complete `.collegeos` file, share it with Android's share sheet, pick such a file on another phone, inspect summary metadata, and restore it. Validation, rollback, compatibility, and failure states are specified in `BACKUP.md`.

## 7. Visual and interaction direction

- Material 3 with a restrained seed palette and semantic success/warning/error colors.
- Typography prioritizes readable numbers and compact information hierarchy; use platform-bundled/system fonts in v1 so the visual system is offline by construction.
- Use an 8-point spacing rhythm, consistent corner radii, low/no elevation surfaces, and generous but not wasteful padding.
- Cards group real information; avoid a card around every label.
- Progress rings are reserved for compact attendance summaries; bars work better for comparisons and small screens.
- Motion uses short Material transitions, animated value changes, and list insertion/removal. Respect reduced-motion accessibility settings and avoid decorative animation.
- Light and dark schemes are designed separately for contrast, not simple color inversion.
- Minimum tap targets, screen-reader labels, large-text behavior, and non-color status indicators are acceptance requirements.

## 8. Non-functional requirements

- **Offline/privacy:** release manifest has no `INTERNET` permission; no network SDKs or trackers.
- **Performance:** normal dashboard and list operations feel immediate with thousands of sessions; aggregate queries are indexed and reactive.
- **Reliability:** mutations that touch related entities use transactions; restore cannot leave a half-replaced database.
- **Compatibility:** Android minimum is proposed as API 24 because the selected current `path_provider` release supports Android 24+; compile SDK must satisfy all selected plugins.
- **Time semantics:** local dates and wall-clock times must not shift when timezone changes; real instants use UTC.
- **Maintainability:** feature-first boundaries, typed repositories, centralized business rules, small `main.dart`, and no core TODO stubs.
- **Data longevity:** every schema bump includes migration and backup round-trip tests.

## 9. Definition of v1 complete

All core workflows work offline on a physical Android device, attendance calculations pass edge-case tests, the five-tab navigation is stable, notifications survive restart/restore as allowed by Android, light/dark UI passes accessibility review, full backup round-trips all records and settings, an older supported database migrates without loss, `flutter analyze` and all automated tests pass, and a release APK contains no internet permission, analytics, ads, login, or backend code.
