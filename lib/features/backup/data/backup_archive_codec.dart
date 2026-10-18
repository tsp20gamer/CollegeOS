import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:college_os/core/database/schema_versions.dart';
import 'package:college_os/features/backup/data/backup_attachment_staging.dart';
import 'package:college_os/features/backup/data/backup_data_snapshot.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:crypto/crypto.dart';

/// Format 2 adds the uploaded subject files to what format 1 already carried.
///
/// Format 1 archives stay byte-for-byte what earlier app versions produced and
/// never contain attached files; they are still written whenever a backup has
/// no files to carry, so data-only pipelines (automatic recovery snapshots,
/// emergency backups before restore) do not change.
const currentBackupFormatVersion = 2;
const _dataOnlyFormatVersion = 1;
const _maxArchiveBytes = 100 * 1024 * 1024;
const _maxUncompressedBytes = 200 * 1024 * 1024;
const _maxManifestBytes = 256 * 1024;
const _maxDataBytes = 100 * 1024 * 1024;
const _maxV2ArchiveBytes = 320 * 1024 * 1024;
const _maxV2UncompressedBytes = 320 * 1024 * 1024;
const _maxV1EntryCount = 1000;
const _maxV2EntryCount = 2000;

final class PreparedBackup {
  const PreparedBackup({
    required this.manifest,
    required this.data,
    required this.sourceName,
    this.attachments = const [],
  });

  final BackupManifest manifest;
  final BackupDataSnapshot data;
  final String sourceName;

  /// Verified attachment files staged on disk, in the order they will be
  /// installed by a restore. Empty for data-only backups.
  final List<StagedBackupAttachment> attachments;

  bool get hasAttachments => attachments.isNotEmpty;

  BackupPreview get preview =>
      BackupPreview(manifest: manifest, sourceName: sourceName);
}

abstract interface class BackupFormatHandler {
  int get version;
  BackupDataSnapshot decodeData(
    BackupManifest manifest,
    Map<String, dynamic> json,
  );
}

final class BackupFormatV1 implements BackupFormatHandler {
  const BackupFormatV1();

  @override
  int get version => 1;

  @override
  BackupDataSnapshot decodeData(
    BackupManifest manifest,
    Map<String, dynamic> json,
  ) {
    if (manifest.databaseSchemaVersion == 1) {
      final tasks = json['tasks'];
      if (tasks is List<dynamic>) {
        for (final task in tasks) {
          if (task is Map<String, dynamic>) {
            task.putIfAbsent('dueTime', () => null);
          }
        }
      }
    }
    if (manifest.databaseSchemaVersion < 3) {
      final settings = json['settings'];
      if (settings is Map<String, dynamic>) {
        settings.putIfAbsent('automaticLocalBackup', () => true);
      }
    }
    if (manifest.databaseSchemaVersion < 4) {
      final exams = json['exams'];
      if (exams is List<dynamic>) {
        for (final exam in exams) {
          if (exam is Map<String, dynamic>) {
            exam.putIfAbsent('reminderAt', () => null);
          }
        }
      }
    }
    if (manifest.databaseSchemaVersion < 5) {
      json.putIfAbsent('dailyAttendance', () => <dynamic>[]);
    }
    if (manifest.databaseSchemaVersion < 6) {
      json['_migrateLegacyAttendance'] = true;
      final settings = json['settings'];
      if (settings is Map<String, dynamic>) {
        settings.putIfAbsent('academicYearStartDate', () => null);
        settings.putIfAbsent('academicYearEndDate', () => null);
      }
      final timetable = json['timetable'];
      if (timetable is List<dynamic>) {
        for (final entry in timetable) {
          if (entry is Map<String, dynamic>) {
            entry.putIfAbsent('effectiveFrom', () => null);
            entry.putIfAbsent('effectiveUntil', () => null);
          }
        }
      }
      json.putIfAbsent('scheduledAttendance', () => <dynamic>[]);
      json.putIfAbsent('dayOverrides', () => <dynamic>[]);
    }
    if (manifest.databaseSchemaVersion < 7) {
      json.putIfAbsent('calendarEvents', () => <dynamic>[]);
    }
    if (manifest.databaseSchemaVersion < 8) {
      final settings = json['settings'];
      if (settings is Map<String, dynamic>) {
        settings.putIfAbsent('studentName', () => '');
      }
    }
    return BackupDataSnapshot.fromJson(json);
  }
}

final class BackupFormatV2 implements BackupFormatHandler {
  const BackupFormatV2();

  @override
  int get version => 2;

  @override
  BackupDataSnapshot decodeData(
    BackupManifest manifest,
    Map<String, dynamic> json,
  ) {
    // A format-2 archive is written by an app that already runs the current
    // schema, so no legacy backfill applies; delegating keeps one copy of the
    // rules should that ever change.
    return const BackupFormatV1().decodeData(manifest, json);
  }
}

final class CollegeOsBackupCodec {
  CollegeOsBackupCodec({
    List<BackupFormatHandler>? formats,
    BackupAttachmentStaging? staging,
  }) : _formats = {
         for (final format
             in formats ?? const [BackupFormatV1(), BackupFormatV2()])
           format.version: format,
       },
       _staging = staging ?? BackupAttachmentStaging();

  final Map<int, BackupFormatHandler> _formats;
  final BackupAttachmentStaging _staging;

  /// Writes a data-only (format 1) backup held entirely in memory.
  ExportedBackup encode({
    required BackupDataSnapshot data,
    required String appVersion,
    required DateTime createdAt,
  }) {
    final dataBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(data.toJson())),
    );
    final manifest = BackupManifest(
      backupFormatVersion: _dataOnlyFormatVersion,
      appVersion: appVersion,
      databaseSchemaVersion: CollegeOsSchemaVersions.current,
      createdAt: createdAt.toUtc(),
      collegeName: data.settings.collegeName,
      activeSemester: data.activeSemesterName,
      recordCounts: data.counts,
      dataSha256: sha256.convert(dataBytes).toString(),
      dataBytes: dataBytes.length,
    );
    final archive = Archive()
      ..add(ArchiveFile.string('manifest.json', jsonEncode(manifest.toJson())))
      ..add(ArchiveFile.bytes('data.json', dataBytes))
      ..add(ArchiveFile.directory('attachments/'));
    final bytes = ZipEncoder().encodeBytes(archive);
    return ExportedBackup(
      fileName: backupFileName(createdAt.toLocal()),
      bytes: bytes,
      manifest: manifest,
    );
  }

  /// Writes a format-2 backup to [outputPath], streaming every attached file
  /// from disk so the export never holds the bytes in memory.
  ///
  /// Files listed in [attachments] that no longer exist are skipped, and a
  /// backup whose files all vanished falls back to a data-only archive.
  Future<ExportedBackup> encodeWithFiles({
    required BackupDataSnapshot data,
    required String appVersion,
    required DateTime createdAt,
    required List<BackupEncodeAttachment> attachments,
    required String outputPath,
  }) async {
    final files = <({BackupEncodeAttachment source, String sha256})>[];
    var totalBytes = 0;
    for (final attachment in attachments) {
      final file = File(attachment.filePath);
      try {
        if (await file.length() != attachment.bytes) continue;
        totalBytes += attachment.bytes;
        if (totalBytes > maxBackupAttachmentTotalBytes) {
          throw const BackupException(
            'attachments_too_large',
            'The uploaded files are larger than the 200 MB limit for one backup. Remove some files or export without them.',
          );
        }
        final digest = await sha256.bind(file.openRead()).first;
        // The file changed while it was being read; skip it rather than
        // write a checksum that describes different bytes.
        if (await file.length() != attachment.bytes) continue;
        files.add((source: attachment, sha256: digest.toString()));
      } on FileSystemException {
        continue;
      }
    }
    files.sort((a, b) => a.source.fileId.compareTo(b.source.fileId));
    if (files.isEmpty) {
      return encode(data: data, appVersion: appVersion, createdAt: createdAt);
    }
    final dataBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(data.toJson())),
    );
    final manifest = BackupManifest(
      backupFormatVersion: currentBackupFormatVersion,
      appVersion: appVersion,
      databaseSchemaVersion: CollegeOsSchemaVersions.current,
      createdAt: createdAt.toUtc(),
      collegeName: data.settings.collegeName,
      activeSemester: data.activeSemesterName,
      recordCounts: data.counts,
      dataSha256: sha256.convert(dataBytes).toString(),
      dataBytes: dataBytes.length,
      attachments: [
        for (final file in files)
          BackupAttachment(
            fileId: file.source.fileId,
            bytes: file.source.bytes,
            sha256: file.sha256,
          ),
      ],
    );
    final encoder = ZipFileEncoder();
    encoder.create(outputPath);
    var finished = false;
    try {
      encoder.addArchiveFile(
        ArchiveFile.string('manifest.json', jsonEncode(manifest.toJson())),
      );
      encoder.addArchiveFile(ArchiveFile.bytes('data.json', dataBytes));
      encoder.addArchiveFile(ArchiveFile.directory('attachments/'));
      for (final file in files) {
        // Attached files are stored uncompressed: most are already compressed
        // formats and store mode lets the encoder stream them from disk with
        // bounded memory instead of buffering a whole compressed entry.
        final input = InputFileStream(file.source.filePath);
        final entry = ArchiveFile.stream(
          'attachments/${file.source.fileId}',
          input,
        );
        entry.compression = CompressionType.none;
        encoder.addArchiveFile(entry);
        await input.close();
      }
      await encoder.close();
      finished = true;
    } finally {
      if (!finished) {
        // Release the file handle before deleting the partial archive,
        // otherwise Windows refuses the delete.
        try {
          await encoder.close();
        } catch (_) {
          // The archive is discarded either way.
        }
        try {
          final partial = File(outputPath);
          if (await partial.exists()) await partial.delete();
        } catch (_) {
          // The scratch folder is wiped before the next export.
        }
      }
    }
    return ExportedBackup(
      fileName: backupFileName(createdAt.toLocal()),
      manifest: manifest,
      filePath: outputPath,
    );
  }

  Future<PreparedBackup> decode({
    required Uint8List bytes,
    required String sourceName,
  }) async {
    if (!sourceName.toLowerCase().endsWith('.$collegeOsBackupExtension')) {
      throw const BackupException(
        'invalid_extension',
        'Choose a file ending in .collegeos.',
      );
    }
    if (bytes.isEmpty || bytes.length > _maxV2ArchiveBytes) {
      throw const BackupException(
        'invalid_archive',
        'The backup is empty or exceeds the supported size limit.',
      );
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      if (archive.length > _maxV2EntryCount) {
        throw const BackupException(
          'invalid_archive',
          'The backup contains too many entries.',
        );
      }
      var totalSize = 0;
      ArchiveFile? manifestEntry;
      ArchiveFile? dataEntry;
      final attachmentEntries = <String, ArchiveFile>{};
      for (final entry in archive) {
        _validateSafeEntry(entry);
        totalSize += entry.size;
        if (totalSize > _maxV2UncompressedBytes) {
          throw const BackupException(
            'invalid_archive',
            'The expanded backup is too large.',
          );
        }
        if (entry.name == 'manifest.json') {
          manifestEntry = entry;
        } else if (entry.name == 'data.json') {
          dataEntry = entry;
        } else if (entry.isFile && entry.name.startsWith('attachments/')) {
          attachmentEntries[entry.name] = entry;
        }
      }
      if (manifestEntry == null || dataEntry == null) {
        throw const BackupException(
          'invalid_archive',
          'The backup must contain manifest.json and data.json.',
        );
      }
      if (manifestEntry.size > _maxManifestBytes ||
          dataEntry.size > _maxDataBytes) {
        throw const BackupException(
          'invalid_archive',
          'A backup entry exceeds its size limit.',
        );
      }
      final manifest = BackupManifest.fromJson(
        jsonDecode(utf8.decode(manifestEntry.content, allowMalformed: false)),
      );
      final format = _formats[manifest.backupFormatVersion];
      if (format == null) {
        if (manifest.backupFormatVersion > currentBackupFormatVersion) {
          throw const BackupException(
            'unsupported_future_backup',
            'This backup was created by a newer CollegeOS backup format. Update CollegeOS and try again.',
          );
        }
        throw const BackupException(
          'unsupported_backup',
          'This CollegeOS backup format is not supported.',
        );
      }
      if (manifest.databaseSchemaVersion > CollegeOsSchemaVersions.current) {
        throw const BackupException(
          'unsupported_future_schema',
          'This backup uses a newer database schema. Update CollegeOS and try again.',
        );
      }
      if (manifest.databaseSchemaVersion < 1) {
        throw const BackupException(
          'unsupported_schema',
          'This database schema is not supported.',
        );
      }
      if (manifest.backupFormatVersion >= 2) {
        _validateFormat2Entries(manifest, archive);
      } else {
        if (archive.length > _maxV1EntryCount) {
          throw const BackupException(
            'invalid_archive',
            'The backup contains too many entries.',
          );
        }
        if (bytes.length > _maxArchiveBytes ||
            totalSize > _maxUncompressedBytes) {
          throw const BackupException(
            'invalid_archive',
            'The backup is empty or exceeds the supported size limit.',
          );
        }
        _validateFormat1Entries(archive);
      }
      final content = dataEntry.content;
      if (content.length != manifest.dataBytes ||
          sha256.convert(content).toString() != manifest.dataSha256) {
        throw const BackupException(
          'corrupt_data',
          'The backup data checksum does not match. The file may be damaged.',
        );
      }
      final decoded = jsonDecode(utf8.decode(content, allowMalformed: false));
      if (decoded is! Map<String, dynamic>) {
        throw const BackupException(
          'invalid_data',
          'data.json must contain an object.',
        );
      }
      final data = format.decodeData(manifest, decoded);
      _validateManifestAgainstData(manifest, data);
      final staged = await _stageAttachments(manifest, data, attachmentEntries);
      return PreparedBackup(
        manifest: manifest,
        data: data,
        sourceName: sourceName,
        attachments: staged,
      );
    } on BackupException {
      rethrow;
    } on FormatException catch (error) {
      throw BackupException(
        'invalid_json',
        'The backup contains invalid JSON.',
        error,
      );
    } catch (error) {
      throw BackupException(
        'invalid_archive',
        'The selected file is not a valid CollegeOS backup.',
        error,
      );
    }
  }

  /// Removes every attachment staged by [decode].
  Future<void> discardStaging() => _staging.reset();

  void _validateSafeEntry(ArchiveFile entry) {
    final name = entry.name;
    final segments = name.replaceAll('\\', '/').split('/');
    final unsafe =
        name.contains('\\') ||
        name.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(name) ||
        segments.contains('..') ||
        name.contains('\u0000') ||
        entry.isSymbolicLink;
    if (unsafe) {
      throw const BackupException(
        'unsafe_archive',
        'The backup contains an unsafe archive path.',
      );
    }
  }

  void _validateFormat1Entries(Archive archive) {
    for (final entry in archive) {
      final allowedDirectory =
          !entry.isFile &&
          (entry.name == 'attachments/' || entry.name == 'attachments');
      final allowedFile =
          entry.isFile &&
          (entry.name == 'manifest.json' || entry.name == 'data.json');
      if (!allowedDirectory && !allowedFile) {
        throw const BackupException(
          'invalid_archive',
          'The backup contains an unexpected entry.',
        );
      }
    }
  }

  void _validateFormat2Entries(BackupManifest manifest, Archive archive) {
    final declared = {for (final a in manifest.attachments) a.fileId};
    final present = <int>{};
    var attachmentFileCount = 0;
    for (final entry in archive) {
      if (!entry.isFile) {
        final allowedDirectory =
            entry.name == 'attachments/' || entry.name == 'attachments';
        if (!allowedDirectory) {
          throw const BackupException(
            'invalid_archive',
            'The backup contains an unexpected entry.',
          );
        }
        continue;
      }
      final name = entry.name;
      if (name == 'manifest.json' || name == 'data.json') continue;
      final match = RegExp(r'^attachments/(\d{1,9})$').firstMatch(name);
      if (match == null) {
        throw const BackupException(
          'invalid_archive',
          'The backup contains an unexpected entry.',
        );
      }
      attachmentFileCount++;
      present.add(int.parse(match.group(1)!));
    }
    // Two entry names can parse to the same file ID (for example
    // `attachments/1` and `attachments/01`); the count catches that.
    final duplicateIds = present.length != attachmentFileCount;
    if (duplicateIds ||
        present.length != declared.length ||
        !present.containsAll(declared)) {
      throw const BackupException(
        'invalid_archive',
        'The attached files do not match the backup manifest.',
      );
    }
  }

  Future<List<StagedBackupAttachment>> _stageAttachments(
    BackupManifest manifest,
    BackupDataSnapshot data,
    Map<String, ArchiveFile> entries,
  ) async {
    if (manifest.attachments.isEmpty) return const [];
    final filesById = {for (final row in data.subjectFiles) row.id: row};
    await _staging.reset();
    try {
      final staged = <StagedBackupAttachment>[];
      final declarations = [...manifest.attachments]
        ..sort((a, b) => a.fileId.compareTo(b.fileId));
      for (final declaration in declarations) {
        final entry = entries['attachments/${declaration.fileId}'];
        final row = filesById[declaration.fileId];
        if (entry == null || row == null) {
          throw const BackupException(
            'invalid_relationships',
            'An attached file does not match a subject file record.',
          );
        }
        final stagedPath = await _staging.write(
          entry: entry,
          fileId: declaration.fileId,
          declaredBytes: declaration.bytes,
          declaredSha256: declaration.sha256,
        );
        staged.add(
          StagedBackupAttachment(
            fileId: declaration.fileId,
            stagedPath: stagedPath,
            bytes: declaration.bytes,
            sha256: declaration.sha256,
            targetRelativePath: row.relativeFilePath,
          ),
        );
      }
      return List.unmodifiable(staged);
    } catch (_) {
      await _staging.reset();
      rethrow;
    }
  }

  void _validateManifestAgainstData(
    BackupManifest manifest,
    BackupDataSnapshot data,
  ) {
    final expected = manifest.recordCounts;
    final actual = data.counts;
    final matches =
        expected.settings == actual.settings &&
        expected.semesters == actual.semesters &&
        expected.subjects == actual.subjects &&
        expected.timetable == actual.timetable &&
        expected.attendance == actual.attendance &&
        expected.dailyAttendance == actual.dailyAttendance &&
        (manifest.databaseSchemaVersion < 6 ||
            (expected.scheduledAttendance == actual.scheduledAttendance &&
                expected.dayOverrides == actual.dayOverrides)) &&
        (manifest.databaseSchemaVersion < 7 ||
            expected.calendarEvents == actual.calendarEvents) &&
        expected.tasks == actual.tasks &&
        expected.exams == actual.exams &&
        expected.marks == actual.marks &&
        expected.notes == actual.notes &&
        expected.files == actual.files;
    if (!matches) {
      throw const BackupException(
        'count_mismatch',
        'Backup record counts do not match its data.',
      );
    }
    if (manifest.collegeName != data.settings.collegeName ||
        manifest.activeSemester != data.activeSemesterName) {
      throw const BackupException(
        'summary_mismatch',
        'Backup summary does not match its data.',
      );
    }
    if (manifest.attachments.isNotEmpty) {
      final filesById = {for (final row in data.subjectFiles) row.id: row};
      for (final attachment in manifest.attachments) {
        final row = filesById[attachment.fileId];
        if (row == null) {
          throw const BackupException(
            'invalid_relationships',
            'An attached file does not match a subject file record.',
          );
        }
        if (!isCanonicalSubjectFileRelativePath(row.relativeFilePath)) {
          throw const BackupException(
            'invalid_relationships',
            'An attached file path is invalid.',
          );
        }
      }
    }
  }
}
