import 'dart:typed_data';

import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';

const timetableImportTemplate =
    'Day,Start,End,Subject,Code,Professor,Room,Note\n'
    'Monday,9:20 AM,10:10 AM,Mathematics,MC,Mrs. Aruna,2009,\n'
    'Tuesday,10:10 AM,11:00 AM,Programming for Problem Solving,PPS,Ms. Lakshmi,Lab 2,Practical';

/// A failure that belongs to the chosen file rather than to one of its rows.
///
/// Its message is shown to the student as it is, because a corrupt workbook or
/// a legacy `.xls` cannot be explained by the per-row issue list.
final class TimetableImportFileException implements Exception {
  const TimetableImportFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The file kinds Smart timetable import can read.
enum TimetableDocumentFormat { csv, xlsx, docx }

/// The readable format for [fileName], or null when it is not supported.
///
/// Legacy `.xls` and `.doc` are deliberately absent: they are binary formats
/// that nothing in the app can decode offline, so they are reported rather than
/// half-read.
TimetableDocumentFormat? timetableDocumentFormatFor(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0) return null;
  return switch (fileName.substring(dot + 1).toLowerCase()) {
    'csv' => TimetableDocumentFormat.csv,
    'xlsx' => TimetableDocumentFormat.xlsx,
    'docx' => TimetableDocumentFormat.docx,
    _ => null,
  };
}

/// The message shown when the picker was handed a file nothing can read.
String unsupportedTimetableFileMessage(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'xls' =>
      'Excel .xls files cannot be read offline. Open it in Excel and save it as .xlsx.',
    'doc' =>
      'Word .doc files cannot be read offline. Open it in Word and save it as .docx.',
    '' => 'Choose a CSV, Excel (.xlsx) or Word (.docx) file.',
    _ => 'CollegeOS can import CSV, Excel (.xlsx) and Word (.docx) files.',
  };
}

final class TimetableImportRow {
  const TimetableImportRow({
    required this.line,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.shortCode,
    required this.professor,
    required this.room,
    required this.note,
  });

  final int line;
  final int weekday;
  final int startTime;
  final int endTime;
  final String subjectName;
  final String shortCode;
  final String professor;
  final String room;
  final String note;
}

final class TimetableImportIssue {
  const TimetableImportIssue(this.line, this.message);

  final int line;
  final String message;
}

final class TimetableImportCandidate {
  const TimetableImportCandidate({
    required this.row,
    required this.matchedSubjectId,
    required this.isDuplicate,
    required this.hasOverlap,
  });

  final TimetableImportRow row;
  final int? matchedSubjectId;
  final bool isDuplicate;
  final bool hasOverlap;

  bool get createsSubject => matchedSubjectId == null;
  bool get willImport => !isDuplicate;
}

final class TimetableImportPreview {
  const TimetableImportPreview({
    required this.fileName,
    required this.candidates,
    required this.issues,
  });

  final String fileName;
  final List<TimetableImportCandidate> candidates;
  final List<TimetableImportIssue> issues;

  int get importCount => candidates.where((row) => row.willImport).length;
  int get duplicateCount => candidates.where((row) => row.isDuplicate).length;
  int get overlapCount =>
      candidates.where((row) => row.willImport && row.hasOverlap).length;
  int get newSubjectCount => candidates
      .where((row) => row.willImport && row.createsSubject)
      .map((row) => _subjectKey(row.row))
      .toSet()
      .length;
}

final class TimetableImportResult {
  const TimetableImportResult({
    required this.entriesCreated,
    required this.subjectsCreated,
    required this.duplicatesSkipped,
  });

  final int entriesCreated;
  final int subjectsCreated;
  final int duplicatesSkipped;
}

abstract interface class TimetableImportCommitter {
  Future<TimetableImportResult> commit({
    required int semesterId,
    required DateTime semesterStart,
    required DateTime semesterEnd,
    required double defaultAttendanceTarget,
    required TimetableImportPreview preview,
  });
}

abstract interface class TimetableImportFilePicker {
  /// Opens the platform picker and returns the chosen file, or null when the
  /// student cancelled. Decoding happens outside the picker so every format
  /// shares one tested path.
  Future<({String name, Uint8List bytes})?> pickFile();
}

/// Turns a decoded table into an import preview.
///
/// Every format ends up here as rows, so CSV, Excel and Word share one set of
/// matching, duplicate, overlap and validation rules rather than three drifting
/// copies of them.
final class TimetableTableParser {
  const TimetableTableParser();

  TimetableImportPreview parseRows({
    required String fileName,
    required List<List<String>> rows,
    required List<Subject> subjects,
    required List<TimetableEntry> existingEntries,
  }) {
    final csv = rows;
    if (csv.isEmpty) {
      return TimetableImportPreview(
        fileName: fileName,
        candidates: const [],
        issues: const [TimetableImportIssue(1, 'The file has no rows.')],
      );
    }
    final header = <String, int>{};
    for (var index = 0; index < csv.first.length; index++) {
      header[_normalize(csv.first[index])] = index;
    }
    int? column(List<String> names) {
      for (final name in names) {
        final index = header[_normalize(name)];
        if (index != null) return index;
      }
      return null;
    }

    final dayColumn = column(const ['day', 'weekday']);
    final startColumn = column(const ['start', 'start time', 'from']);
    final endColumn = column(const ['end', 'end time', 'to']);
    final subjectColumn = column(const ['subject', 'subject name', 'name']);
    final missing = <String>[
      if (dayColumn == null) 'Day',
      if (startColumn == null) 'Start',
      if (endColumn == null) 'End',
      if (subjectColumn == null) 'Subject',
    ];
    if (missing.isNotEmpty) {
      return TimetableImportPreview(
        fileName: fileName,
        candidates: const [],
        issues: [
          TimetableImportIssue(
            1,
            'Missing required columns: ${missing.join(', ')}.',
          ),
        ],
      );
    }
    final codeColumn = column(const ['code', 'short code', 'subject code']);
    final professorColumn = column(const [
      'professor',
      'lecturer',
      'faculty',
      'teacher',
    ]);
    final roomColumn = column(const ['room', 'location']);
    final noteColumn = column(const ['note', 'notes']);
    final byCode = <String, Subject>{
      for (final subject in subjects)
        if (subject.shortCode.trim().isNotEmpty)
          _normalize(subject.shortCode): subject,
    };
    final byName = <String, Subject>{
      for (final subject in subjects) _normalize(subject.name): subject,
    };
    final issues = <TimetableImportIssue>[];
    final candidates = <TimetableImportCandidate>[];
    final seen = <String>{};

    String value(List<String> row, int? index) =>
        index == null || index >= row.length ? '' : row[index].trim();

    for (var index = 1; index < csv.length; index++) {
      final source = csv[index];
      if (source.every((cell) => cell.trim().isEmpty)) continue;
      final line = index + 1;
      try {
        final weekday = _parseWeekday(value(source, dayColumn!));
        final start = _parseTime(value(source, startColumn!));
        final end = _parseTime(value(source, endColumn!));
        final subjectName = value(source, subjectColumn!);
        if (subjectName.isEmpty) {
          throw const FormatException('Subject is empty.');
        }
        if (end <= start) {
          throw const FormatException('End time must be after start time.');
        }
        final row = TimetableImportRow(
          line: line,
          weekday: weekday,
          startTime: start,
          endTime: end,
          subjectName: subjectName,
          shortCode: value(source, codeColumn),
          professor: value(source, professorColumn),
          room: value(source, roomColumn),
          note: value(source, noteColumn),
        );
        final matched = row.shortCode.isNotEmpty
            ? byCode[_normalize(row.shortCode)] ??
                  byName[_normalize(row.subjectName)]
            : byName[_normalize(row.subjectName)];
        final subjectKey = matched == null
            ? _subjectKey(row)
            : 'id:${matched.id}';
        final slotKey =
            '$subjectKey:${row.weekday}:${row.startTime}:${row.endTime}';
        final duplicate =
            !seen.add(slotKey) ||
            (matched != null &&
                existingEntries.any(
                  (entry) =>
                      entry.subjectId == matched.id &&
                      entry.weekday == row.weekday &&
                      entry.startTime == row.startTime &&
                      entry.endTime == row.endTime,
                ));
        // Only the times matter here, so both sources are reduced to one slot
        // shape instead of sharing the full timetable record.
        final occupiedSlots = <({int start, int end})>[
          ...existingEntries
              .where((entry) => entry.weekday == row.weekday)
              .map((entry) => (start: entry.startTime, end: entry.endTime)),
          ...candidates
              .where(
                (candidate) =>
                    candidate.willImport &&
                    candidate.row.weekday == row.weekday,
              )
              .map(
                (candidate) => (
                  start: candidate.row.startTime,
                  end: candidate.row.endTime,
                ),
              ),
        ];
        final overlap =
            !duplicate &&
            occupiedSlots.any(
              (slot) => row.startTime < slot.end && row.endTime > slot.start,
            );
        candidates.add(
          TimetableImportCandidate(
            row: row,
            matchedSubjectId: matched?.id,
            isDuplicate: duplicate,
            hasOverlap: overlap,
          ),
        );
      } on FormatException catch (error) {
        issues.add(TimetableImportIssue(line, error.message));
      }
    }
    return TimetableImportPreview(
      fileName: fileName,
      candidates: List.unmodifiable(candidates),
      issues: List.unmodifiable(issues),
    );
  }
}

/// Splits delimited text into rows, honouring quoted fields.
///
/// Kept as a static on the parser so the CSV path and the file picker cannot
/// disagree about how a quoted comma or an unclosed quote is treated.
List<List<String>> splitDelimitedText(String source) => _readCsv(source);

String _subjectKey(TimetableImportRow row) => row.shortCode.trim().isNotEmpty
    ? 'code:${_normalize(row.shortCode)}'
    : 'name:${_normalize(row.subjectName)}';

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

int _parseWeekday(String value) {
  final normalized = _normalize(value);
  final numeric = int.tryParse(normalized);
  if (numeric != null && numeric >= 1 && numeric <= 7) return numeric;
  return switch (normalized) {
    'mon' || 'monday' => DateTime.monday,
    'tue' || 'tues' || 'tuesday' => DateTime.tuesday,
    'wed' || 'wednesday' => DateTime.wednesday,
    'thu' || 'thur' || 'thurs' || 'thursday' => DateTime.thursday,
    'fri' || 'friday' => DateTime.friday,
    'sat' || 'saturday' => DateTime.saturday,
    'sun' || 'sunday' => DateTime.sunday,
    _ => throw FormatException('Unknown weekday "$value".'),
  };
}

int _parseTime(String value) {
  final normalized = value.trim().toUpperCase().replaceAll('.', ':');
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
  ).firstMatch(normalized);
  if (match == null) throw FormatException('Invalid time "$value".');
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3);
  if (minute > 59 ||
      hour > (period == null ? 23 : 12) ||
      hour == 0 && period != null) {
    throw FormatException('Invalid time "$value".');
  }
  if (period == 'AM' && hour == 12) hour = 0;
  if (period == 'PM' && hour != 12) hour += 12;
  return hour * 60 + minute;
}

List<List<String>> _readCsv(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (character == '"') {
      if (quoted && index + 1 < source.length && source[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      row.add(field.toString());
      field = StringBuffer();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      row.add(field.toString());
      field = StringBuffer();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(character);
    }
  }
  if (quoted) {
    throw const FormatException('The CSV contains an unclosed quote.');
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}
