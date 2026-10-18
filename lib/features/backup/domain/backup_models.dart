import 'dart:typed_data';

const collegeOsBackupExtension = 'collegeos';
const collegeOsBackupMimeType = 'application/x-collegeos';

/// Largest total size of attached files one backup may carry.
///
/// The whole export pipeline is bounded by this number so a backup always
/// stays within what the device can hold in memory while saving or sharing
/// it. A future format can raise it without changing this contract.
const maxBackupAttachmentTotalBytes = 200 * 1024 * 1024;

/// One attached file declared by a format-2 backup manifest.
///
/// The bytes live in the archive at `attachments/<fileId>`; the manifest
/// carries the size and SHA-256 so a reader can verify what it extracts.
final class BackupAttachment {
  const BackupAttachment({
    required this.fileId,
    required this.bytes,
    required this.sha256,
  });

  final int fileId;
  final int bytes;
  final String sha256;

  Map<String, Object> toJson() => {
    'fileId': fileId,
    'bytes': bytes,
    'sha256': sha256,
  };

  static BackupAttachment fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const BackupException(
        'invalid_manifest',
        'An attachment declaration is missing.',
      );
    }
    final fileId = value['fileId'];
    final bytes = value['bytes'];
    final sha256 = value['sha256'];
    if (fileId is! int || fileId < 1) {
      throw const BackupException(
        'invalid_manifest',
        'An attachment file ID is invalid.',
      );
    }
    if (bytes is! int || bytes < 0 || bytes > maxBackupAttachmentTotalBytes) {
      throw const BackupException(
        'invalid_manifest',
        'An attachment size is invalid.',
      );
    }
    if (sha256 is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) {
      throw const BackupException(
        'invalid_manifest',
        'An attachment checksum is invalid.',
      );
    }
    return BackupAttachment(fileId: fileId, bytes: bytes, sha256: sha256);
  }
}

/// A file that a format-2 export copies into the archive.
final class BackupEncodeAttachment {
  const BackupEncodeAttachment({
    required this.fileId,
    required this.filePath,
    required this.bytes,
  });

  final int fileId;
  final String filePath;
  final int bytes;
}

/// One attachment that was verified and staged on disk while a backup was
/// inspected, ready to be installed by a restore.
final class StagedBackupAttachment {
  const StagedBackupAttachment({
    required this.fileId,
    required this.stagedPath,
    required this.bytes,
    required this.sha256,
    required this.targetRelativePath,
  });

  final int fileId;
  final String stagedPath;
  final int bytes;
  final String sha256;

  /// Where the file belongs under application support storage, taken from
  /// the matching `subject_files` row and validated by the decoder.
  final String targetRelativePath;
}

final class BackupRecordCounts {
  const BackupRecordCounts({
    required this.settings,
    required this.semesters,
    required this.subjects,
    required this.timetable,
    required this.attendance,
    this.dailyAttendance = 0,
    this.scheduledAttendance = 0,
    this.dayOverrides = 0,
    this.calendarEvents = 0,
    required this.tasks,
    required this.exams,
    required this.marks,
    this.notes = 0,
    this.files = 0,
  });

  final int settings;
  final int semesters;
  final int subjects;
  final int timetable;
  final int attendance;
  final int dailyAttendance;
  final int scheduledAttendance;
  final int dayOverrides;
  final int calendarEvents;
  final int tasks;
  final int exams;
  final int marks;
  final int notes;
  final int files;

  Map<String, Object> toJson() => {
    'settings': settings,
    'semesters': semesters,
    'subjects': subjects,
    'timetable': timetable,
    'attendance': attendance,
    'dailyAttendance': dailyAttendance,
    'scheduledAttendance': scheduledAttendance,
    'dayOverrides': dayOverrides,
    'calendarEvents': calendarEvents,
    'tasks': tasks,
    'exams': exams,
    'marks': marks,
    'notes': notes,
    'files': files,
  };

  factory BackupRecordCounts.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const BackupException(
        'invalid_manifest',
        'Record counts are missing.',
      );
    }
    int count(String key) {
      final item = value[key];
      if (item is! int || item < 0) {
        throw BackupException(
          'invalid_manifest',
          'Invalid record count for $key.',
        );
      }
      return item;
    }

    int optionalCount(String key) {
      if (!value.containsKey(key)) return 0;
      return count(key);
    }

    return BackupRecordCounts(
      settings: count('settings'),
      semesters: count('semesters'),
      subjects: count('subjects'),
      timetable: count('timetable'),
      attendance: count('attendance'),
      dailyAttendance: optionalCount('dailyAttendance'),
      scheduledAttendance: optionalCount('scheduledAttendance'),
      dayOverrides: optionalCount('dayOverrides'),
      calendarEvents: optionalCount('calendarEvents'),
      tasks: count('tasks'),
      exams: count('exams'),
      marks: count('marks'),
      notes: optionalCount('notes'),
      files: optionalCount('files'),
    );
  }
}

final class BackupManifest {
  const BackupManifest({
    required this.backupFormatVersion,
    required this.appVersion,
    required this.databaseSchemaVersion,
    required this.createdAt,
    required this.collegeName,
    required this.activeSemester,
    required this.recordCounts,
    required this.dataSha256,
    required this.dataBytes,
    this.attachments = const [],
  });

  final int backupFormatVersion;
  final String appVersion;
  final int databaseSchemaVersion;
  final DateTime createdAt;
  final String collegeName;
  final String? activeSemester;
  final BackupRecordCounts recordCounts;
  final String dataSha256;
  final int dataBytes;

  /// Files carried inside a format-2 archive. Always empty for format 1.
  final List<BackupAttachment> attachments;

  int get totalAttachmentBytes {
    var total = 0;
    for (final attachment in attachments) {
      total += attachment.bytes;
    }
    return total;
  }

  Map<String, Object?> toJson() => {
    'backupFormatVersion': backupFormatVersion,
    'appVersion': appVersion,
    'databaseSchemaVersion': databaseSchemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'collegeName': collegeName,
    'activeSemester': activeSemester,
    'recordCounts': recordCounts.toJson(),
    'dataSha256': dataSha256,
    'dataBytes': dataBytes,
    // Omitted entirely for format-1 backups so their manifest stays
    // byte-for-byte what earlier app versions produced.
    if (attachments.isNotEmpty)
      'attachments': [
        for (final attachment in attachments) attachment.toJson(),
      ],
  };

  factory BackupManifest.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const BackupException(
        'invalid_manifest',
        'manifest.json must contain an object.',
      );
    }
    final format = value['backupFormatVersion'];
    final schema = value['databaseSchemaVersion'];
    final appVersion = value['appVersion'];
    final createdAtText = value['createdAt'];
    final collegeName = value['collegeName'];
    final activeSemester = value['activeSemester'];
    final hash = value['dataSha256'];
    final bytes = value['dataBytes'];
    final createdAt = createdAtText is String
        ? DateTime.tryParse(createdAtText)
        : null;
    if (format is! int || format < 1 || schema is! int || schema < 1) {
      throw const BackupException(
        'invalid_manifest',
        'Backup or database version is invalid.',
      );
    }
    if (appVersion is! String ||
        appVersion.isEmpty ||
        createdAt == null ||
        !createdAt.isUtc) {
      throw const BackupException(
        'invalid_manifest',
        'Backup application version or date is invalid.',
      );
    }
    if (collegeName is! String ||
        (activeSemester != null && activeSemester is! String)) {
      throw const BackupException(
        'invalid_manifest',
        'Backup college or semester is invalid.',
      );
    }
    if (hash is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const BackupException(
        'invalid_manifest',
        'Backup data checksum is invalid.',
      );
    }
    if (bytes is! int || bytes < 0) {
      throw const BackupException(
        'invalid_manifest',
        'Backup data size is invalid.',
      );
    }
    final attachmentsValue = value['attachments'];
    final attachments = <BackupAttachment>[];
    if (attachmentsValue != null) {
      if (attachmentsValue is! List) {
        throw const BackupException(
          'invalid_manifest',
          'Backup attachment list is invalid.',
        );
      }
      final seen = <int>{};
      var totalBytes = 0;
      for (final item in attachmentsValue) {
        final attachment = BackupAttachment.fromJson(item);
        if (!seen.add(attachment.fileId)) {
          throw const BackupException(
            'invalid_manifest',
            'Backup attachment list repeats a file.',
          );
        }
        totalBytes += attachment.bytes;
        if (totalBytes > maxBackupAttachmentTotalBytes) {
          throw const BackupException(
            'attachments_too_large',
            'The backup carries more attached files than this app supports.',
          );
        }
        attachments.add(attachment);
      }
      if (format < 2 && attachments.isNotEmpty) {
        throw const BackupException(
          'invalid_manifest',
          'This backup format cannot carry attached files.',
        );
      }
    }
    return BackupManifest(
      backupFormatVersion: format,
      appVersion: appVersion,
      databaseSchemaVersion: schema,
      createdAt: createdAt,
      collegeName: collegeName,
      activeSemester: activeSemester as String?,
      recordCounts: BackupRecordCounts.fromJson(value['recordCounts']),
      dataSha256: hash,
      dataBytes: bytes,
      attachments: List.unmodifiable(attachments),
    );
  }
}

final class BackupPreview {
  const BackupPreview({required this.manifest, required this.sourceName});

  final BackupManifest manifest;
  final String sourceName;
}

final class ExportedBackup {
  const ExportedBackup({
    required this.fileName,
    required this.manifest,
    this.bytes,
    this.filePath,
  }) : assert(
         (bytes == null) != (filePath == null),
         'A backup is either held in memory or written to a file.',
       );

  final String fileName;
  final BackupManifest manifest;

  /// In-memory archive for data-only backups.
  final Uint8List? bytes;

  /// Path of the temporary archive for backups that carry attached files,
  /// which can be far larger than memory should hold.
  final String? filePath;

  bool get isFileBacked => filePath != null;
}

final class BackupException implements Exception {
  const BackupException(this.code, this.message, [this.cause]);

  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

String backupFileName(DateTime localTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'CollegeOS_Backup_${localTime.year}-${two(localTime.month)}-'
      '${two(localTime.day)}_${two(localTime.hour)}${two(localTime.minute)}.'
      '$collegeOsBackupExtension';
}

/// True when [path] can be joined under application support storage without
/// escaping it or resolving to an unexpected location.
///
/// This guards both restore and normal file reads: a crafted archive must
/// never be able to point CollegeOS at another file on the device.
bool isSafeSubjectFileRelativePath(String path) {
  if (path.isEmpty || path.length > 512) return false;
  if (path.contains('\\') || path.contains('\u0000')) return false;
  if (path.startsWith('/') || path.startsWith('~')) return false;
  if (RegExp(r'^[A-Za-z]:').hasMatch(path)) return false;
  final segments = path.split('/');
  return !segments.contains('..') &&
      !segments.contains('.') &&
      !segments.contains('');
}

/// True when [path] is exactly the shape this app writes for an uploaded
/// subject file: `subject_files/<subjectId>/<timestamp>_<name>`.
///
/// Restoring a format-2 backup writes files at this path, so it is held to the
/// stricter, canonical form rather than merely being traversal-safe.
bool isCanonicalSubjectFileRelativePath(String path) {
  final match = RegExp(
    r'^subject_files/(\d{1,9})/([A-Za-z0-9_.\-]+)$',
  ).firstMatch(path);
  if (match == null) return false;
  final name = match.group(2)!;
  return name != '.' && name != '..';
}
