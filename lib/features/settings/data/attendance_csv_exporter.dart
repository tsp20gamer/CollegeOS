import 'dart:convert';
import 'dart:typed_data';

import 'package:college_os/features/backup/data/backup_data_snapshot.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

final class AttendanceCsvFile {
  const AttendanceCsvFile({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

abstract interface class AttendanceCsvFileGateway {
  Future<bool> save(AttendanceCsvFile file);
}

final class AndroidAttendanceCsvFileGateway
    implements AttendanceCsvFileGateway {
  const AndroidAttendanceCsvFileGateway();

  @override
  Future<bool> save(AttendanceCsvFile file) async {
    final destination = await FilePicker.platform.saveFile(
      dialogTitle: 'Export attendance CSV',
      fileName: file.fileName,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: file.bytes,
    );
    return destination != null;
  }
}

final class AttendanceCsvExporter {
  const AttendanceCsvExporter();

  AttendanceCsvFile create(BackupDataSnapshot snapshot, {DateTime? createdAt}) {
    final rows = [...snapshot.scheduledAttendance]
      ..sort((a, b) {
        final date = a.date.compareTo(b.date);
        return date != 0 ? date : a.startTime.compareTo(b.startTime);
      });
    final subjects = {for (final row in snapshot.subjects) row.id: row};
    final buffer = StringBuffer()
      ..writeln('Date,Day,Start,End,Subject,Short Code,Status,Note');
    for (final attendance in rows) {
      final subject = subjects[attendance.subjectId];
      buffer.writeln(
        [
          DateFormat('yyyy-MM-dd').format(attendance.date),
          DateFormat('EEEE').format(attendance.date),
          _time(attendance.startTime),
          _time(attendance.endTime),
          subject?.name ?? 'Unknown subject',
          subject?.shortCode ?? '',
          attendance.attendanceStatus.name,
          attendance.note,
        ].map(_cell).join(','),
      );
    }
    final timestamp = DateFormat(
      'yyyy-MM-dd_HHmm',
    ).format((createdAt ?? DateTime.now()).toLocal());
    return AttendanceCsvFile(
      fileName: 'CollegeOS_Attendance_$timestamp.csv',
      bytes: Uint8List.fromList(utf8.encode('\uFEFF$buffer')),
    );
  }

  String _cell(String value) =>
      '"${value.replaceAll('"', '""').replaceAll('\r\n', '\n').replaceAll('\r', '\n')}"';

  String _time(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';
}
