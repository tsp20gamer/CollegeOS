import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:file_picker/file_picker.dart';

/// Opens the platform picker for the formats the timetable import can decode.
///
/// The picker only collects bytes: decoding lives in
/// `TimetableDocumentReader`, so CSV, Excel and Word share one tested path and
/// the picker stays a thin platform adapter.
final class DeviceTimetableImportFilePicker
    implements TimetableImportFilePicker {
  const DeviceTimetableImportFilePicker();

  /// Larger than the old CSV cap because an `.xlsx` is a zip of XML, and a
  /// timetable with formatting can comfortably pass 2 MB.
  static const _maximumBytes = 5 * 1024 * 1024;

  @override
  Future<({String name, Uint8List bytes})?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'docx'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      throw const TimetableImportFileException(
        'CollegeOS could not read that file.',
      );
    }
    if (bytes.length > _maximumBytes) {
      throw const TimetableImportFileException(
        'Choose a timetable file smaller than 5 MB.',
      );
    }
    return (name: file.name, bytes: bytes);
  }
}
