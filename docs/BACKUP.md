# CollegeOS Backup and Restore

## 1. Contract

CollegeOS exports one ZIP-compatible file with the custom `.collegeos` extension. It is a complete replacement snapshot for phone-to-phone transfer; it is not sync or merge. CollegeOS itself never uploads the file and needs no internet or broad storage permission. Android’s document and share sheets provide the user-controlled transfer mechanism.

Example filename:

`CollegeOS_Backup_2026-08-12_1500.collegeos`

V1 backups are private but not encrypted. Anyone holding a backup can inspect its JSON, so the UI tells the user to store and transfer it securely.

## 2. Format version 1

```text
manifest.json
data.json
attachments/
```

`attachments/` is an explicit empty directory in v1 and reserves a safe namespace for a future format. V1 rejects attachment files and all unexpected archive entries.

`manifest.json` contains:

```json
{
  "backupFormatVersion": 1,
  "appVersion": "1.0.0+1",
  "databaseSchemaVersion": 8,
  "createdAt": "2026-08-12T09:30:00.000Z",
  "collegeName": "City College",
  "activeSemester": "Semester 3",
  "recordCounts": {
    "settings": 1,
    "semesters": 2,
    "subjects": 12,
    "timetable": 28,
    "attendance": 640,
    "dailyAttendance": 72,
    "scheduledAttendance": 636,
    "dayOverrides": 4,
    "tasks": 81,
    "exams": 18,
    "marks": 14
  },
  "dataSha256": "<lowercase SHA-256>",
  "dataBytes": 123456
}
```

The hash detects accidental corruption; it is not encryption, authentication, or proof of origin.

`data.json` has one settings object and arrays named `semesters`, `subjects`, `timetable`, `attendance`, `dailyAttendance`, `scheduledAttendance`, `dayOverrides`, `calendarEvents`, `tasks`, `exams`, and `marks`. The settings object includes the student's local display name from schema v8. `scheduledAttendance` and `dayOverrides` are the current linked attendance datasets; `calendarEvents` contains schema-v7 academic events and closure ranges; `attendance` and `dailyAttendance` preserve legacy history for backward compatibility. It preserves every primary key and foreign key. Local calendar dates use `YYYY-MM-DD`, real instants use UTC ISO-8601, wall-clock times use integer minutes, and enums use stable database names. Calculated percentages are not exported because they are derived from source records.

## 3. Export and sharing

1. Capture every persisted dataset inside one Drift transaction for a consistent view.
2. Serialize the typed snapshot, hash `data.json`, build the manifest, and add the empty attachments directory.
3. Re-open and fully validate the generated archive before offering it to the user.
4. `Export Data` lets the student choose a full `.collegeos` backup or a readable attendance CSV. The full backup includes attendance and every other persisted dataset; both choices use Android’s native save workflow through `file_picker`.
5. `Share Backup` sends an `XFile` with the dedicated `application/x-collegeos` MIME type to Android’s share sheet through `share_plus`.
6. Android registers CollegeOS for compatible `.collegeos` view/share intents. The native activity immediately copies the granted content URI into bounded application cache, then Flutter sends those bytes through the same hostile-input validation, preview, confirmation, emergency-backup, and atomic restore pipeline used by the in-app picker. The temporary copy is removed after inspection. This is an additional entry point, not a less-safe restore path.

Exports do not change live data. Operations are mutually exclusive inside the backup service.

## 4. Hostile-input validation

Import validates before showing a preview and never writes to the database during inspection:

- `.collegeos` filename extension;
- valid ZIP structure and CRC;
- archive size, expanded size, entry-count, manifest-size, and data-size bounds;
- no absolute paths, Windows drive prefixes, backslashes, `..`, NULs, symlinks, unknown files, or files under `attachments/` in v1;
- required `manifest.json`, `data.json`, fields, types, UTC timestamp, and 64-character checksum;
- supported backup format and database schema versions;
- SHA-256 and declared byte length;
- all required datasets and record-count agreement;
- finite numeric values, date/time ranges, enum values, singleton settings, unique positive IDs, at most one active semester, and table constraints;
- every semester/subject/exam relationship, including same-semester and same-subject composite relationships.

The decoder never extracts archive paths to disk, which removes the zip-slip write surface in addition to rejecting unsafe names.

V1 is represented by a `BackupFormatHandler`. A future format adds another handler rather than adding conditional parsing throughout UI or database code. A future backup format or database schema is rejected with an update message. Format v1 supplies fields introduced by later schemas when reading older data: task `dueTime`, automatic-local-backup preference, exam `reminderAt`, daily-attendance compatibility, academic-year bounds, timetable effective dates, linked class attendance, calendar overrides, schema-v7 academic calendar events, and schema-v8 student display name. Schema-v1–v6 backups default `calendarEvents` to an empty array. Pre-v8 backups default `studentName` to an empty string, preserving compatibility and the generic Home greeting. Schema-v1–v5 attendance is conservatively converted into linked class records where relationships can be inferred, while every original compatibility record remains preserved.

## 5. Preview and atomic restore

The preview shows college name, active semester, local backup date, and subject, attendance, task, and exam counts. Restore requires a second explicit confirmation containing:

> Existing CollegeOS data on this device will be replaced.

Before replacement, CollegeOS creates and validates a full emergency `.collegeos` backup under private application-support storage. Restore is cancelled if that file cannot be written. Only the newest private emergency backup is retained.

All deletions and ID-preserving inserts execute in one Drift transaction in dependency order. Foreign-key and SQLite integrity checks run before that transaction commits. Any decoding, insertion, relationship, injected, or integrity failure throws and Drift rolls the transaction back, leaving the original database open and usable. Successful table mutations notify existing reactive providers, and the app routes to Home using the restored settings.

Android scheduled notifications are not platform data and are never stored in the archive. Task and exam reminder intent is included in `data.json`; the notification reconciler rebuilds the Android projection after restore or the next launch.

## 6. Automatic local recovery backups

Automatic recovery uses the exact same format-v1 serializer, validator, manifest, and atomic restore pipeline as a full exported `.collegeos` backup. These snapshots live only under the application-private support directory at `backup/recovery/`; Android removes them if CollegeOS is uninstalled or its app data is cleared. They are therefore secondary recovery points, not a phone-transfer strategy. The Settings UI states:

> Local backups remain on this phone. Export a backup to protect your data when changing devices.

Automatic local backup defaults to on and is persisted in `app_settings`. CollegeOS creates a baseline when no recovery snapshot exists, marks the database dirty from Drift table-update notifications, coalesces changes with a five-minute debounce, and checkpoints dirty state when the application pauses or detaches. It runs no permanent service, wake lock, alarm, or periodic Android job. An unchanged checkpoint creates no file.

Files are first written to a `.part` path and atomically renamed. After every successful write, oldest snapshots are deleted until exactly the newest five remain. The screen labels the newest valid snapshot as **Latest Backup**, older valid snapshots as **Previous Backups**, and lets the user preview and restore any selection through the normal emergency-backup and transactional replacement flow. A corrupt local snapshot is ignored without touching the live database or hiding other valid recovery points.

## 7. Tests and release gates

Automated coverage includes:

- a fully populated export, explicit wipe, import, and table-by-table JSON equality comparison;
- ID and relationship preservation plus SQLite integrity/foreign-key checks;
- corrupt ZIP, invalid manifest, unsupported future format, unsupported future schema, zip-slip path, and invalid relationship rejection;
- a forced failure immediately before restore commit proving the original dataset is exactly retained;
- settings-to-preview-to-confirm UI restoration.
- automatic baseline/dirty checkpoint behavior, disabled behavior, and exact newest-five retention.

Every schema or backup-format change must extend immutable compatibility fixtures and round-trip coverage. Android release acceptance also includes manually saving through the document picker, sharing through the share sheet, and transferring between two installations.
