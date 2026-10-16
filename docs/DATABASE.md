# CollegeOS Database Design

## 1. Implemented persistence contract

CollegeOS uses one Drift-managed SQLite database as its local source of truth. Schema version `1` established the base tables, schema version `2` added task due time, schema version `3` added automatic-local-backup preference, schema version `4` added exam reminder intent, schema version `5` added legacy calendar-day attendance, schema version `6` added linked timetable-driven class attendance, calendar overrides, academic-year bounds, and effective timetable dates, schema version `7` added date-range academic calendar events, schema version `8` adds the student's local display name, schema version `14` adds an optional per-class reminder lead time (`timetable_entries.reminder_minutes_before`, minutes before the class start, `0..10080`, `NULL` for none), schema version `15` adds the class-notifier preferences (`app_settings.class_reminders_enabled`, default on, and `app_settings.class_reminder_minutes_before`, default `10`, `0..10080`), and schema version `16` adds the derived-holiday rules (`app_settings.sunday_off`, `app_settings.second_saturday_off` and `app_settings.government_holidays_off`, all default on). There is no remote database, network synchronization, account identifier, analytics store, or advertising data.

The production database is stored as `database/college_os.sqlite` inside the application's private support directory. Native database work runs on a background isolate. Every connection enables SQLite foreign keys and write-ahead logging.

Core storage rules:

- Integer auto-increment primary keys are sufficient because backup/restore moves a complete database.
- Local calendar dates are integer epoch days. They cannot shift when the device timezone changes.
- Wall-clock times are integer minutes after local midnight.
- Real instants are UTC milliseconds since the Unix epoch.
- Enums are stable lowercase text values. Renaming a value requires a migration.
- Attendance percentages and all other summary values are derived; they are never authoritative columns.
- Drift rows stay in the data layer. Feature repositories expose strongly typed immutable domain records and reactive streams.

## 2. Schema overview

```text
app_settings (singleton id = 1)
daily_attendance_records (one row per local calendar date)

semesters 1 -- * subjects 1 -- * attendance_sessions
    |               |  |
    |               |  +-- * timetable_entries
    |               +----- * tasks (optional subject)
    |               +----- * exams 1 -- * marks (optional exam link)
    |               +----- * standalone marks
    +--------------------- * timetable_entries
    +--------------------- * tasks
    +--------------------- * exams
```

Composite foreign keys ensure a timetable entry, subject task, or exam cannot refer to a subject from a different semester. Marks linked to an exam must use the same subject as that exam.

## 3. Tables

### `semesters`

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `name` | TEXT | Trimmed non-empty value |
| `semester_number` | INTEGER | Greater than zero |
| `academic_year` | TEXT | Trimmed non-empty value |
| `start_date` | INTEGER | Epoch day |
| `end_date` | INTEGER | Epoch day, not before start |
| `is_active` | INTEGER/BOOL | Default false; partial unique index allows at most one true row |
| `created_at`, `updated_at` | INTEGER | UTC milliseconds |

Indexes: one partial unique active-semester index and `(academic_year, semester_number)`. Activating a semester clears the old active flag and sets the new one in a transaction.

### `subjects`

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `semester_id` | INTEGER FK | Semester delete cascades |
| `name` | TEXT | Trimmed non-empty value |
| `short_code`, `professor`, `room` | TEXT | Empty string when not supplied |
| `attendance_target` | REAL | Default `0.75`; greater than zero and at most one. Rewritten for every subject when the default attendance target changes |
| `display_color` | INTEGER | Unsigned 32-bit ARGB value |
| `is_archived` | INTEGER/BOOL | Default false |
| `created_at`, `updated_at` | INTEGER | UTC milliseconds |

Indexes: `(semester_id, is_archived, name)`. A composite unique key on `(id, semester_id)` supports cross-table semester consistency.

### `timetable_entries`

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `semester_id`, `subject_id` | INTEGER FK | Subject must belong to semester; delete cascades |
| `weekday` | INTEGER | ISO weekday `1..7` |
| `start_time` | INTEGER | Minute `0..1439` |
| `end_time` | INTEGER | Minute `1..1440`, later than start |
| `room`, `note` | TEXT | Empty string when not supplied |
| `effective_from`, `effective_until` | INTEGER | Optional epoch-day range a schedule version applies to |
| `reminder_minutes_before` | INTEGER | Optional lead time before `start_time`, `0..10080`; `NULL` means the class has no reminder |

Indexes: `(semester_id, weekday, start_time)` and `subject_id`. Overlaps remain an application-level warning because real schedules can intentionally overlap.

### `attendance_sessions`

This is a legacy compatibility table retained so upgrades and older backups do not lose historical class-session data. It is not exposed by the current attendance UI.

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `subject_id` | INTEGER FK | Subject delete cascades |
| `date` | INTEGER | Epoch day |
| `period` | INTEGER | Greater than zero |
| `status` | TEXT enum | `present`, `absent`, `cancelled` |
| `note` | TEXT | Empty string when not supplied |
| `created_at`, `updated_at` | INTEGER | UTC milliseconds |

Indexes: `(subject_id, date, period)` and `(subject_id, status)`. Reactive aggregate queries return present, absent, cancelled, and held counts. Attendance percentages, safe bunks, and recovery classes remain a later pure domain calculator.

### `daily_attendance_records`

This schema-v5 table is retained for upgrade and older backup compatibility. It is not an attendance-percentage source of truth in schema v6.

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `date` | INTEGER | Unique epoch day |
| `status` | TEXT enum | `present`, `absent` |
| `note` | TEXT | Empty string when not supplied |
| `created_at`, `updated_at` | INTEGER | UTC milliseconds |

Schema-v6 migration may expand an unambiguous legacy day across that date's timetable. Current UI and percentages never query this table as an attendance source.

### `tasks`

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `semester_id` | INTEGER FK | Semester delete cascades |
| `subject_id` | INTEGER FK nullable | If set, subject must belong to semester; subject delete cascades |
| `title` | TEXT | Trimmed non-empty value |
| `description` | TEXT | Empty string when not supplied |
| `type` | TEXT enum | `general`, `assignment`, `study` |
| `priority` | TEXT enum | `low`, `medium`, `high` |
| `due_date` | INTEGER nullable | Epoch day |
| `due_time` | INTEGER nullable | Wall-clock minute `0..1439`; requires `due_date` |
| `reminder_at` | INTEGER nullable | UTC milliseconds |
| `is_completed` | INTEGER/BOOL | Default false |
| `completed_at` | INTEGER nullable | Required exactly when completed |
| `created_at`, `updated_at` | INTEGER | UTC milliseconds |

Indexes: `(semester_id, is_completed, due_date)` and `(subject_id, is_completed)`.

### `exams`

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `semester_id`, `subject_id` | INTEGER FK | Subject must belong to semester; delete cascades |
| `name`, `exam_type` | TEXT | Trimmed non-empty values |
| `exam_date` | INTEGER | Epoch day |
| `start_time`, `end_time` | INTEGER nullable | Valid minutes; end after start when both exist |
| `room`, `syllabus` | TEXT | Empty string when not supplied |
| `max_marks` | REAL nullable | Positive when present |
| `obtained_marks` | REAL nullable | Non-negative and not above max when max exists |
| `reminder_at` | INTEGER nullable | UTC instant; OS notification schedule is rebuildable |
| `created_at`, `updated_at` | INTEGER | UTC milliseconds |

Indexes: `(semester_id, exam_date, start_time)` and `(subject_id, exam_date)`. A composite unique key on `(id, subject_id)` supports marks consistency.

### `marks`

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Auto-increment |
| `subject_id` | INTEGER FK | Subject delete cascades |
| `exam_id` | INTEGER FK nullable | When set, exam must use the same subject; exam delete cascades |
| `category` | TEXT | Trimmed non-empty value |
| `obtained_marks` | REAL | Non-negative and at most max |
| `max_marks` | REAL | Greater than zero |
| `date` | INTEGER | Epoch day |
| `note` | TEXT | Empty string when not supplied |

Indexes: `(subject_id, date)` and `exam_id`. Percentages are derived from obtained/max values.

### `app_settings`

Exactly one row exists with `id = 1`.

| Column | SQLite type | Rules |
|---|---|---|
| `id` | INTEGER PK | Check `id = 1` |
| `student_name` | TEXT | Local display name; empty for upgraded installs until edited |
| `college_name`, `course`, `branch` | TEXT | Empty string when not supplied |
| `academic_year_start_date`, `academic_year_end_date` | INTEGER nullable | Epoch-day academic bounds; required by completed current setup |
| `default_attendance_target` | REAL | Default `0.75`; greater than zero and at most one. Changing it writes the new value onto every subject's `attendance_target`, since attendance, the planner and analytics compare against the subject's stored target |
| `theme_mode` | TEXT enum | `system`, `light`, `dark`; default system |
| `onboarding_completed` | INTEGER/BOOL | Default false |
| `notifications_enabled` | INTEGER/BOOL | Default false; separate from OS permission |
| `automatic_local_backup` | INTEGER/BOOL | Default true; controls private on-device recovery snapshots |
| `class_reminders_enabled` | INTEGER/BOOL | Default true; pauses only class reminders, independently of `notifications_enabled` |
| `class_reminder_minutes_before` | INTEGER | Default `10`; lead time `0..10080` offered to classes without their own reminder |
| `sunday_off` | INTEGER/BOOL | Default true; every Sunday is a derived holiday |
| `second_saturday_off` | INTEGER/BOOL | Default true; the second Saturday of each month is a derived holiday |
| `government_holidays_off` | INTEGER/BOOL | Default true; the fixed national holidays (26 January, 15 August, 2 October) are derived holidays |

The row is inserted during schema creation and updated with an upsert, so settings cannot accidentally multiply.

## 4. Repository and transaction boundaries

Each table has a narrow DAO. Feature repository interfaces map Drift rows to immutable feature-domain records and are wired through Riverpod providers. Widgets must not import tables, companions, DAOs, or generated Drift rows.

Reactive streams are provided for semesters, subjects, timetable entries, attendance history/counts, tasks, exams, marks, and settings. Write methods trim user-facing text at the repository boundary. Database checks and foreign keys remain the final integrity boundary.

Cross-record operations use transactions. In schema v1 this includes active-semester switching. Later onboarding must create settings, the initial semester, and subjects in a single transaction.

## 5. Migration policy

Schema version `1` has no predecessor migration. Schema version `2` adds nullable `tasks.due_time`; version `3` adds `app_settings.automatic_local_backup`; version `4` adds nullable `exams.reminder_at`; version `5` creates `daily_attendance_records`; version `6` introduces linked class attendance, calendar overrides, academic-year bounds, and effective timetable dates; version `7` adds date-range academic calendar events; version `8` adds non-null `app_settings.student_name` with an empty-string default; version `9` and `10` add subject notes and files; versions `11`–`13` add the PDF search index and its resumable page cursor; version `14` recreates `timetable_entries` with the optional `reminder_minutes_before` column, preserving every row and defaulting every existing class to no reminder; version `15` recreates `app_settings` with the two class-notifier columns, whose defaults backfill the single existing row as enabled with a ten-minute lead time, so classes that already remind keep reminding. The recreation is what keeps the new `CHECK (class_reminder_minutes_before BETWEEN 0 AND 10080)` identical to a fresh v15 create. Version `16` recreates the same table once more with the three derived-holiday rules, whose defaults backfill the existing row as enabled; that rebuild is what keeps both the v15 lead-time `CHECK` and `CHECK (id = 1)` in the upgraded table, which a plain `addColumn` would leave behind. `test/core/database/migrations/college_os/app_settings_v16_test.dart` proves the rebuilt schema matches a fresh v16 create and that the student's earlier choices survive it. The v6 migration preserves compatibility tables and conservatively copies records when relationships can be inferred. The v7 migration only creates the new table and index. The v8 migration adds one defaulted column, preserving every existing record and using the generic Home greeting until the student enters a name. Full rules are in `ATTENDANCE_ARCHITECTURE.md`. Immutable exported snapshots are stored under `drift_schemas/college_os/`. The database applies only explicitly registered upgrades and never silently drops or recreates user data.

For every future schema change:

1. Increment `CollegeOsSchemaVersions.current`.
2. Add an explicit step-by-step Drift migration from every supported prior version.
3. Run `dart run drift_dev make-migrations` and commit the new schema JSON without editing older snapshots.
4. Add fixture-based migration and data-integrity tests.

Historical recreations use `TableMigration`, which builds the temporary table from the *current* Dart definition. That makes a recreation a moving target: any column added later would silently appear in the older schema version it belongs to, and drift's verifier rejects that. The v6 timetable recreation is therefore written as pinned SQL for its own historical shape, and only the current version recreates the table with the current definition. Any further column added to `timetable_entries` follows the same rule: the v6 step keeps its frozen shape, and the new version recreates or alters the table itself.
5. Run `PRAGMA integrity_check` and `PRAGMA foreign_key_check` after migration and restore.
6. Evaluate backup format compatibility separately; a database version change does not automatically require a backup format change.
7. Never use `deleteEverything`, uninstall/reinstall, or fallback database recreation as an upgrade path.

## 6. Backup implications

A backup is a consistent transaction-level snapshot of all persisted datasets serialized into the versioned `data.json` inside a `.collegeos` archive. It contains linked scheduled attendance, day overrides, and legacy attendance tables for compatibility, but never calculated percentages. Restore validates the entire typed graph first, creates a private emergency backup, and performs all replacement writes plus integrity/foreign-key checks in one transaction. Full details remain in `BACKUP.md`.

## 7. Schema-v6 linked attendance additions

`app_settings` now includes nullable epoch-day `academic_year_start_date` and `academic_year_end_date`. `timetable_entries` includes nullable inclusive `effective_from` and `effective_until` dates so future schedule changes do not rewrite history.

`scheduled_class_attendance` stores sparse explicit marks with semester, optional timetable entry, subject, date, snapshotted start/end time, `unmarked|present|absent|cancelled` status, note, manual-modification flag, and timestamps. Its unique date/timetable index prevents duplicates. `calendar_day_overrides` stores a unique `normal|holiday|collegeClosed` override per semester/date. Exact projection, calculation, migration, and reversibility rules are documented in `ATTENDANCE_ARCHITECTURE.md`.

## 8. Schema-v7 academic calendar

`academic_calendar_events` stores semester-scoped date ranges without generating per-day rows. Each record has a title, `event|examPeriod|holiday|collegeClosed` type, inclusive start/end dates, optional note, and timestamps. A date constraint requires end on or after start, and `(semester_id, start_date, end_date)` is indexed.

Holiday and college-closed ranges are attendance exclusions. They do not delete or rewrite explicit attendance, so deleting the range safely reveals the original class state again. Event and exam-period ranges are informational and never alter attendance calculations. Semester deletion cascades to its calendar events; rollover does not copy them automatically.

## 9. Schema-v16 derived holidays

`app_settings` gains three defaulted booleans, all enabled on both a fresh install and an upgrade: `sunday_off`, `second_saturday_off`, and `government_holidays_off`. They describe days the college is closed as rules rather than rows, so no calendar date is stored per year and no student data is rewritten when one is switched off.

They add no table and no index, and no other table changes. A stored `calendar_day_overrides` row still outranks a rule, and the rules are read only through `DefaultHolidayPolicy`; the day-state and percentage derivation they feed is documented in `ATTENDANCE_ARCHITECTURE.md`.

Backup format stays `1`. `data.json` records the three values; an archive written before v16 restores them as enabled, which is what a fresh install stores, so a restore never silently changes which days the student is counted for.

