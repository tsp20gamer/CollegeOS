import 'dart:typed_data';

const collegeOsBackupExtension = 'collegeos';
const collegeOsBackupMimeType = 'application/x-collegeos';

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
    required this.bytes,
    required this.manifest,
  });

  final String fileName;
  final Uint8List bytes;
  final BackupManifest manifest;
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
