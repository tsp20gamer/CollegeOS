# CollegeOS Linked Attendance Architecture

## Purpose

CollegeOS attendance is class-based, timetable-driven, offline-only, and reactive. Calendar and Classes are two projections of the same local records. A change made in either view writes through the same repository and invalidates the same Drift stream, so the other view, Home, subject metrics, and pending-attendance count update together.

Calendar dates determine which weekly timetable slots may exist. They never directly determine attendance percentage.

## Sparse projection model

CollegeOS does not pre-generate a row for every class in a semester. The schedule for a date is projected from:

1. the active semester date range;
2. timetable entries whose weekday and effective-date range include that date;
3. sparse explicit `scheduled_class_attendance` rows, when a class has been marked or cancelled; and
4. a `calendar_day_overrides` row, when the day is a holiday or the college is closed.

An eligible timetable slot without an explicit mark is an `unmarked` projected session. It remains unmarked even when its date is in the past. This keeps storage proportional to user actions while retaining an exact per-class source of truth.

## Persistent records

`scheduled_class_attendance` snapshots the semester, optional timetable entry, subject, date, start/end time, status, note, modification origin, and timestamps. Status is `unmarked`, `present`, `absent`, or `cancelled`; normal UI writes only materialize rows once a status is selected. A nullable timetable link permits safe migration of legacy attendance that cannot be matched unambiguously to a timetable slot.

The unique `(date, timetable_entry_id)` index prevents duplicate marks for a projected class. Subject/date and semester/date indexes support history, calendar, and summary queries.

`calendar_day_overrides` stores a unique override per semester/date. Types are `normal`, `holiday`, and `collegeClosed`; normal is represented by removing the override in normal UI flows.

Marking a holiday does not overwrite or delete per-class marks. The override masks every scheduled class on that date from attendance calculations and from the Calendar, Classes, Home, and home-screen-widget daily projections. Undoing the holiday removes the mask and safely reveals the preserved class marks; previously unmarked classes remain unmarked.

## Timetable history

Timetable entries have nullable inclusive `effective_from` and `effective_until` dates. New entries start at the semester start. Editing an established entry ends the old version the day before the selected effective date and inserts a new version. Removing a class ends the current version instead of deleting historical schedule meaning.

This supports changes such as Mathematics on Monday through September and Physics in the same slot from October. Historical marked attendance retains its timetable ID, subject, and time snapshot. Editing or removing a future schedule can never delete historical attendance rows.

## Day state derivation

Day state is derived, not independently stored:

- override holiday -> Holiday;
- override college closed -> College Closed;
- outside semester -> Outside Semester;
- no scheduled sessions -> No Classes;
- every non-cancelled session unmarked -> Unmarked;
- some marked and some unmarked -> Partially Marked;
- every held session present -> Present Day;
- every held session absent -> Absent Day;
- present/absent mixture -> Partial Attendance.

Cancelled sessions do not turn a day absent. Icons and text accompany semantic colors so state is not conveyed by color alone.

## Calculations

For each subject, only explicit marks inside the semester and outside holiday/closed overrides participate:

```text
heldClasses = present + absent
attendancePercentage = present / heldClasses * 100
```

Unmarked, cancelled, holiday, and college-closed sessions are excluded. The integer-scaled `AttendanceCalculator` remains the sole implementation for percentage boundaries, safe bunks, and classes required; no percentage is persisted.

Each subject carries its own target. The default attendance target in Settings is written onto every subject whenever it changes, and Settings also names the subjects that still hold an older value — an import or an earlier build can leave them behind while the stored setting has already moved on — and offers one confirmed action that brings them onto the stored default. Nothing re-targets a subject silently, so a subject a student deliberately set apart survives.

The attendance forecast is also a pure projection. It runs the same exact calculator twice—once with one future present class and once with one future absent class. A subject is “fragile” only when it is currently on target but one more absence would put it below target. Forecasts never create sessions or predict that a class was actually held.

The Attendance Planner extends this projection to user-selected counts of future attended and missed classes. It calls the same integer-scaled `AttendanceCalculator`, never writes a database record, and resets when the planner screen is closed. Planner results therefore cannot be confused with real attendance.

Streak insights are also derived. Current and longest streaks consider only explicit present/absent class records after holiday and college-closed exclusions. Cancelled and unmarked classes do not break or extend a streak. A perfect day is counted only when the linked day projection is `present`, which prevents an unmarked scheduled class from being reported as perfect.

## One-day timetable exceptions

One-day exceptions reuse the versioned timetable and linked attendance models instead of adding a competing calendar:

- an extra class is a timetable entry whose inclusive `effective_from` and `effective_until` are the same selected date;
- cancelling a normally scheduled class writes an explicit `cancelled` linked attendance record for that date and timetable entry;
- restoring the class removes that sparse cancellation record; and
- weekly entries and historical marked attendance remain unchanged.

The exception screen projects the selected date through the normal attendance engine, so extra and cancelled classes immediately update Attendance, Home, analytics, pending review, and the Android widget. Holidays continue to mask all scheduled classes and the exception screen does not display classes on an excluded date.

This representation requires no schema migration beyond schema v7 and no backup-format change: both the effective timetable dates and cancelled attendance rows are already included in format-v1 backups.

Attendance Analytics reuses the same daily projection for Month, Semester, and All Time. Overall percentages are weighted from summed class counts (`all present / all held`); CollegeOS never averages subject percentages. All Time watches each locally stored semester and combines its exclusion-aware report, so edits to any semester update analytics without another persistence model.

## Migration from schema v5

Schema v6 adds academic-year dates to settings, effective dates to timetable entries, and the two linked-attendance tables. The migration:

- derives academic-year bounds from the active semester when possible;
- assigns existing timetable rows their semester bounds;
- preserves every legacy `attendance_sessions` row;
- copies legacy rows into linked attendance, matching the timetable by period/subject when unambiguous and otherwise retaining a standalone historical session with a deterministic fallback time;
- expands a legacy daily present/absent row across that date's timetable only when exactly one semester contains the date and no legacy per-class records already exist for that date; and
- retains legacy tables for older backup compatibility.

No legacy record is deleted. Ambiguous daily records without a uniquely identifiable semester or timetable cannot safely become class records and remain preserved in the compatibility table; they are not silently counted.

## Weekly summary, reminders, and undo (September 2026)

- Home summarizes Monday through today and compares its class-weighted percentage with the previous completed week. A week without held classes has no percentage or comparison. Subject warnings use each subject's stored target. Pending counts include only ended classes; holidays and closures are excluded.
- Reports project each date once and share it across subjects, reducing repeated timetable/history scans when opening analytics or rendering the summary.
- With Notifications enabled, one local alarm is maintained for the next eligible class day in a 14-day lookahead, 15 minutes after its final non-cancelled class. Fully marked days, holidays, closures, archived subjects, and dates outside the semester are skipped. App usage and changes to attendance/timetable/settings refresh this projection. Past alarms are not repeatedly postponed. Only the next eligible day is scheduled; this is not an indefinite daily background job.
- Notification ID zero is reserved for attendance. Existing positive task IDs and negative exam IDs remain unchanged. Tapping `attendance:1` opens Pending Attendance.
- Individual and bulk marks capture their affected rows before and after the write in one Drift transaction. The app offers a six-second Undo action. Undo checks that all affected rows still match the saved post-edit state, then atomically restores earlier rows (including notes, timestamps and modification flags) or removes newly materialized rows. If any row changed again, nothing is restored. Tokens are transient and never included in backups.
- Manual historical sessions update by record ID when there is no timetable link, preventing duplicate records during edits.
- No schema migration is required; schema 8 and backup format 1 remain compatible.

## Backup compatibility

Backup format version remains `1`. Schema-v6 backups add academic-year dates, timetable effective dates, scheduled attendance, and day overrides to `data.json` and record counts. Older format-v1/schema-v1–v5 backups are decoded with defaults and passed through the same conservative legacy conversion rules. Restore inserts all linked records inside the existing atomic transaction and validates their relationships before commit.
