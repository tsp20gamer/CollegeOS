# CollegeOS Backup and Restore

## 1. Contract

CollegeOS exports one ZIP-compatible file with the custom `.collegeos` extension. It is a complete replacement snapshot for phone-to-phone transfer; it is not sync or merge. CollegeOS itself never uploads the file and needs no internet or broad storage permission. Android’s document and share sheets provide the user-controlled transfer mechanism.

Example filename:

`CollegeOS_Backup_2026-08-12_1500.collegeos`

Backups are private but not encrypted. Anyone holding a backup can inspect its JSON, so the UI tells the user to store and transfer it securely.

## 2. Archive formats and versioning

Two formats exist. Format 1 carries records only; format 2 adds the student's uploaded files. Exports write format 2 only when they actually carry files, so data-only archives stay byte-for-byte what earlier versions produced.

### Format version 1

```text
manifest.json
data.json
attachments/
```

`attachments/` is an explicit empty directory in v1 and reserves a safe namespace for the format-2 files. V1 rejects attachment files and all unexpected archive entries.

`manifest.json` contains:

```json
{
  "backupFormatVersion": 1,
  "appVersion": "1.0.0+1",
  "databaseSchemaVersion": 16,
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
    "calendarEvents": 9,
    "tasks": 81,
    "exams": 18,
    "marks": 14,
    "notes": 6,
    "files": 12
  },
  "dataSha256": "<lowercase SHA-256>",
  "dataBytes": 123456
}
```

The hash detects accidental corruption; it is not encryption, authentication, or proof of origin.

`data.json` has one settings object and arrays named `semesters`, `subjects`, `timetable`, `attendance`, `dailyAttendance`, `scheduledAttendance`, `dayOverrides`, `calendarEvents`, `tasks`, `exams`, `marks`, `notes`, and `subjectFiles`. The settings object includes the student's local display name from schema v8 and the three derived-holiday rules from schema v16 (`sundayOff`, `secondSaturdayOff`, `governmentHolidaysOff`; a settings object that predates them restores as enabled, matching a fresh install). `scheduledAttendance` and `dayOverrides` are the current linked attendance datasets; `calendarEvents` contains schema-v7 academic events and closure ranges; `attendance` and `dailyAttendance` preserve legacy history for backward compatibility. It preserves every primary key and foreign key. Local calendar dates use `YYYY-MM-DD`, real instants use UTC ISO-8601, wall-clock times use integer minutes, and enums use stable database names. Calculated percentages are not exported because they are derived from source records.

### Format version 2

Format 2 is format 1 plus the student's uploaded files:

```text
manifest.json
data.json
attachments/
attachments/<fileId>
```

`manifest.json` gains an `attachments` array:

```json
"attachments": [
  { "fileId": 12, "bytes": 84213, "sha256": "<lowercase SHA-256>" }
]
```

Each entry names one `subjectFiles` row and one `attachments/<fileId>` archive entry. The archive carries no file paths of its own: a restore places each file at the `relativeFilePath` of its data row, which must have the canonical `subject_files/<subjectId>/<timestamp>_<name>` shape.

Attached files are stored uncompressed — most are already-compressed formats — which lets both writing and reading stream the bytes in bounded memory instead of buffering whole entries. The declared size and SHA-256 are verified against the extracted file, because ZIP readers built on this library do not check entry CRCs. One export may carry at most 200 MB of attached files (`maxBackupAttachmentTotalBytes`); larger totals are rejected with a clear message in the export sheet. Format-2 archives are bounded to 320 MB compressed, 320 MB expanded, and 2000 entries; format-1 limits are unchanged.

Format 1 omits `attachments` entirely (it is not an empty array), so data-only archives stay byte-for-byte what earlier versions wrote. Automatic recovery snapshots, emergency pre-restore backups, and every other internal pipeline keep writing format 1.

## 3. Export and sharing

1. Capture every persisted dataset inside one Drift transaction for a consistent view.
2. Serialize the typed snapshot, hash `data.json`, build the manifest, and add the empty attachments directory. When the student includes files, resolve the `subjectFiles` rows whose files still exist, hash each file streaming from disk, and append it as an uncompressed `attachments/<fileId>` entry written to private scratch storage.
3. Re-open and fully validate a data-only archive before offering it to the user. A file-backed archive skips that re-read — it would duplicate up to 200 MB of I/O — and relies on the per-file checksums verified on import plus the round-trip tests.
4. `Export Data` offers **Full CollegeOS Backup**, **Full Backup + Files**, and a readable attendance CSV. `Share Backup` offers the two `.collegeos` variants through the share sheet. The with-files option is disabled with a reason when the student has no uploaded files or the files exceed the 200 MB cap.
5. Saving uses Android's native save workflow through `file_picker`; the dialog needs the archive bytes, read back from the scratch file for a file-backed export. Sharing hands `share_plus` the scratch file directly. A saved archive's scratch file is deleted immediately; a shared one is kept until the next export or launch, because the receiving app may still read it after the share sheet closes.
6. Android registers CollegeOS for compatible `.collegeos` view/share intents. The native activity immediately copies the granted content URI into bounded application cache, then Flutter sends those bytes through the same hostile-input validation, preview, confirmation, emergency-backup, and atomic restore pipeline used by the in-app picker. The temporary copy is removed after inspection. This is an additional entry point, not a less-safe restore path.

Exports do not change live data. Operations are mutually exclusive inside the backup service.

## 4. Hostile-input validation

Import validates before showing a preview and never writes to the database during inspection:

- `.collegeos` filename extension;
- valid ZIP structure; entry CRCs are not trusted, so every declared SHA-256 is verified explicitly;
- archive size, expanded size, entry-count, manifest-size, and data-size bounds;
- no absolute paths, Windows drive prefixes, backslashes, `..`, NULs, symlinks, or unknown files; v1 allows nothing under `attachments/` while v2 allows only `attachments/<fileId>` entries that its manifest declares exactly;
- required `manifest.json`, `data.json`, fields, types, UTC timestamp, and 64-character checksum;
- supported backup format and database schema versions;
- SHA-256 and declared byte length for `data.json`, and the declared size plus SHA-256 for every attached file;
- the declared attachment set matching the extracted entries one-to-one, at most 200 MB of declared attachments, and no duplicate file IDs;
- every attachment matching a `subjectFiles` row whose path has the canonical `subject_files/<subjectId>/<timestamp>_<name>` shape; every subject file path is also rejected if it could escape private storage;
- all required datasets and record-count agreement;
- finite numeric values, date/time ranges, enum values, singleton settings, unique positive IDs, at most one active semester, and table constraints;
- every semester/subject/exam relationship, including same-semester and same-subject composite relationships.

The decoder never uses archive paths as write targets. Attachment entries are staged to a private folder named after the manifest's file IDs, verified, and only then placed at the canonical target derived from the validated data row, which removes the zip-slip write surface in addition to rejecting unsafe names.

V1 and V2 are each represented by a `BackupFormatHandler`. A future format adds another handler rather than adding conditional parsing throughout UI or database code. A format-2 archive is always written against the current schema, so its handler delegates to the v1 decode rules; the legacy backfills below apply to format-1 archives written by older schema versions. A future backup format or database schema is rejected with an update message. Format v1 supplies fields introduced by later schemas when reading older data: task `dueTime`, automatic-local-backup preference, exam `reminderAt`, daily-attendance compatibility, academic-year bounds, timetable effective dates, linked class attendance, calendar overrides, schema-v7 academic calendar events, schema-v8 student display name, and the schema-v14 class reminder lead time (`reminderMinutesBefore` on each timetable entry, validated to `0..10080` and omitted by schema-v13 and earlier archives so those classes simply restore without a reminder). The schema-v15 class notifier is handled the same way: `classRemindersEnabled` and `classReminderMinutesBefore` are validated against the same `0..10080` range, and a schema-v14 or earlier archive that omits them restores them enabled with a ten-minute lead time, which is exactly what upgrading that database in place would have stored. Schema-v1–v6 backups default `calendarEvents` to an empty array. Pre-v8 backups default `studentName` to an empty string, preserving compatibility and the generic Home greeting. Schema-v1–v5 attendance is conservatively converted into linked class records where relationships can be inferred, while every original compatibility record remains preserved.

## 5. Preview and atomic restore

The preview shows college name, active semester, local backup date, subject, attendance, task, and exam counts, plus the uploaded-file count and total size for a format-2 backup. Restore requires a second explicit confirmation containing:

> Existing CollegeOS data on this device will be replaced.

A format-2 preview also states that uploaded files will be replaced by the ones in the backup. Inspecting a format-2 archive stages its files under private support storage after verifying each checksum; cancelling the preview, a failed restore, or the next app launch removes the staged files.

Before replacement, CollegeOS creates and validates a full emergency `.collegeos` backup under private application-support storage. Restore is cancelled if that file cannot be written. Only the newest private emergency backup is retained. Emergency backups are format 1: they protect records, not the uploaded files being replaced.

All deletions and ID-preserving inserts execute in one Drift transaction in dependency order. Foreign-key and SQLite integrity checks run before that transaction commits. Any decoding, insertion, relationship, injected, or integrity failure throws and Drift rolls the transaction back, leaving the original database open and usable. Successful table mutations notify existing reactive providers, and the app routes to Home using the restored settings.

A format-2 restore places the verified files before the database transaction: the previous `subject_files/` folder is renamed to `subject_files.restore-backup/` (recovering it first if an earlier restore was interrupted), the new files are copied in, and the database transaction runs. On success the old folder is deleted; on failure the new files are removed and the old folder is renamed back, so a failed restore leaves the student's files exactly as they were. Staged files are removed after a successful restore.

Android scheduled notifications are not platform data and are never stored in the archive. Task and exam reminder intent is included in `data.json`; the notification reconciler rebuilds the Android projection after restore or the next launch.

## 6. Automatic local recovery backups

Automatic recovery uses the exact same format-v1 serializer, validator, manifest, and atomic restore pipeline as a full exported `.collegeos` backup. These snapshots never carry uploaded files; those travel only in a full export the student chooses. Snapshots live only under the application-private support directory at `backup/recovery/`; Android removes them if CollegeOS is uninstalled or its app data is cleared. They are therefore secondary recovery points, not a phone-transfer strategy. The Settings UI states:

> Local backups remain on this phone. Export a backup to protect your data when changing devices.

Automatic local backup defaults to on and is persisted in `app_settings`. CollegeOS creates a baseline when no recovery snapshot exists, marks the database dirty from Drift table-update notifications, coalesces changes with a five-minute debounce, and checkpoints dirty state when the application pauses or detaches. It runs no permanent service, wake lock, alarm, or periodic Android job. An unchanged checkpoint creates no file.

Files are first written to a `.part` path and atomically renamed. After every successful write, oldest snapshots are deleted until exactly the newest five remain. The screen labels the newest valid snapshot as **Latest Backup**, older valid snapshots as **Previous Backups**, and lets the user preview and restore any selection through the normal emergency-backup and transactional replacement flow. A corrupt local snapshot is ignored without touching the live database or hiding other valid recovery points.

## 7. Tests and release gates

Automated coverage includes:

- a fully populated export, explicit wipe, import, and table-by-table JSON equality comparison;
- a format-2 export, inspect, and restore round trip that compares every table and every uploaded file byte-for-byte;
- tampered, missing, undeclared, escaping, and unmatched attachment rejection inside a format-2 archive, plus the 200 MB export cap;
- a forced database-restore failure proving the previous uploaded files are put back and can be recovered after an interrupted swap;
- ID and relationship preservation plus SQLite integrity/foreign-key checks;
- corrupt ZIP, invalid manifest, unsupported future format, unsupported future schema, zip-slip path, and invalid relationship rejection;
- a forced failure immediately before restore commit proving the original dataset is exactly retained;
- settings-to-preview-to-confirm UI restoration.
- automatic baseline/dirty checkpoint behavior, disabled behavior, and exact newest-five retention.

Every schema or backup-format change must extend immutable compatibility fixtures and round-trip coverage. Android release acceptance also includes manually saving through the document picker, sharing through the share sheet, and transferring between two installations.
