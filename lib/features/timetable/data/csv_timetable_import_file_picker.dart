import 'dart:convert';
import 'dart:io';

import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:file_picker/file_picker.dart';

final class CsvTimetableImportFilePicker implements TimetableImportFilePicker {
  const CsvTimetableImportFilePicker();

  static const _maximumBytes = 2 * 1024 * 1024;

  @override
  Future<({String name, String contents})?> pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) throw StateError('CollegeOS could not read that file.');
    if (bytes.length > _maximumBytes) {
      throw const FormatException('Choose a CSV smaller than 2 MB.');
    }
    return (name: file.name, contents: utf8.decode(bytes));
  }
}
