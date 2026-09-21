import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:college_os/core/database/schema_versions.dart';
import 'package:college_os/features/backup/data/backup_data_snapshot.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:crypto/crypto.dart';

const currentBackupFormatVersion = 1;
const _maxArchiveBytes = 100 * 1024 * 1024;
const _maxUncompressedBytes = 200 * 1024 * 1024;
const _maxManifestBytes = 256 * 1024;
const _maxDataBytes = 100 * 1024 * 1024;

final class PreparedBackup {
  const PreparedBackup({
    required this.manifest,
    required this.data,
    required this.sourceName,
  });

  final BackupManifest manifest;
  final BackupDataSnapshot data;
  final String sourceName;

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

final class CollegeOsBackupCodec {
  CollegeOsBackupCodec({List<BackupFormatHandler>? formats})
    : _formats = {
        for (final format in formats ?? const [BackupFormatV1()])
          format.version: format,
      };

  final Map<int, BackupFormatHandler> _formats;

  ExportedBackup encode({
    required BackupDataSnapshot data,
    required String appVersion,
    required DateTime createdAt,
  }) {
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

  PreparedBackup decode({
    required Uint8List bytes,
    required String sourceName,
  }) {
    if (!sourceName.toLowerCase().endsWith('.$collegeOsBackupExtension')) {
      throw const BackupException(
        'invalid_extension',
        'Choose a file ending in .collegeos.',
      );
    }
    if (bytes.isEmpty || bytes.length > _maxArchiveBytes) {
      throw const BackupException(
        'invalid_archive',
        'The backup is empty or exceeds the supported size limit.',
      );
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      if (archive.length > 1000) {
        throw const BackupException(
          'invalid_archive',
          'The backup contains too many entries.',
        );
      }
      var totalSize = 0;
      ArchiveFile? manifestEntry;
      ArchiveFile? dataEntry;
      for (final entry in archive) {
        _validateEntry(entry);
        totalSize += entry.size;
        if (totalSize > _maxUncompressedBytes) {
          throw const BackupException(
            'invalid_archive',
            'The expanded backup is too large.',
          );
        }
        if (entry.name == 'manifest.json') manifestEntry = entry;
        if (entry.name == 'data.json') dataEntry = entry;
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
      return PreparedBackup(
        manifest: manifest,
        data: data,
        sourceName: sourceName,
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

  void _validateEntry(ArchiveFile entry) {
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
    final allowedDirectory =
        !entry.isFile && (name == 'attachments/' || name == 'attachments');
    final allowedFile =
        entry.isFile && (name == 'manifest.json' || name == 'data.json');
    if (!allowedDirectory && !allowedFile) {
      throw const BackupException(
        'invalid_archive',
        'The backup contains an unexpected entry.',
      );
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
        expected.marks == actual.marks;
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
  }
}
