import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:xml/xml.dart';

/// Decodes a picked timetable file into table rows.
///
/// Excel and Word files are ZIP containers of XML, and the app already ships
/// the zip reader the backup format uses, so both are read with the existing
/// `archive` dependency and the already-resolved `xml` package instead of
/// adding a spreadsheet or document-processing package. That keeps the import
/// fully offline and the dependency set unchanged in size.
///
/// Everything that fails because of the file — a workbook that is not a zip, a
/// document without a table, a `.xls` that nothing can decode — is reported as
/// a [TimetableImportFileException] with a message written for the student.
final class TimetableDocumentReader {
  const TimetableDocumentReader();

  List<List<String>> readRows({
    required String fileName,
    required Uint8List bytes,
  }) {
    final format = timetableDocumentFormatFor(fileName);
    return switch (format) {
      TimetableDocumentFormat.csv => splitDelimitedText(_decodeCsv(bytes)),
      TimetableDocumentFormat.xlsx => _readWorkbook(bytes),
      TimetableDocumentFormat.docx => _readDocument(bytes),
      null => throw TimetableImportFileException(
        unsupportedTimetableFileMessage(fileName),
      ),
    };
  }

  /// A `.docx`: the first table in `word/document.xml`.
  List<List<String>> _readDocument(Uint8List bytes) {
    final archive = _openArchive(
      bytes,
      'This document could not be opened. Save it again as .docx and try once '
      'more.',
    );
    final entry = archive.find('word/document.xml');
    if (entry == null) {
      throw const TimetableImportFileException(
        'This file is not a Word document CollegeOS can read.',
      );
    }
    final document = _parseXml(
      _entryText(entry),
      'This document has no readable content.',
    );
    final table = _descendantElements(document.rootElement, 'tbl').firstOrNull;
    if (table == null) {
      throw const TimetableImportFileException(
        'Add the timetable as a table in Word (Insert → Table) and import it '
        'again. A plain list of classes cannot be read reliably.',
      );
    }
    return [
      for (final row in _descendantElements(table, 'tr'))
        [
          for (final cell in _descendantElements(row, 'tc'))
            _allText(cell).trim(),
        ],
    ];
  }

  /// An `.xlsx`: the first worksheet, resolved through its shared strings.
  List<List<String>> _readWorkbook(Uint8List bytes) {
    final failureMessage =
        'This workbook could not be opened. Save it again '
        'as .xlsx and try once more.';
    final archive = _openArchive(bytes, failureMessage);
    final sheetEntry = _firstWorksheet(archive);
    if (sheetEntry == null) {
      // A zip with no worksheet is not a workbook CollegeOS can read, so it
      // reports the same way a corrupt file does.
      throw const TimetableImportFileException(
        'This workbook could not be opened. Save it again as .xlsx and try '
        'once more.',
      );
    }
    final sharedStrings = _readSharedStrings(archive);
    final document = _parseXml(
      _entryText(sheetEntry),
      'This workbook has no readable worksheet.',
    );
    final byRow = <int, List<String>>{};
    var nextRow = 1;
    for (final rowElement in _descendantElements(document.rootElement, 'row')) {
      final rowNumber =
          int.tryParse(rowElement.getAttribute('r') ?? '') ?? nextRow;
      nextRow = rowNumber + 1;
      final cells = <int, String>{};
      var fallbackColumn = 0;
      for (final cell in _descendantElements(rowElement, 'c')) {
        final reference = cell.getAttribute('r');
        final column = reference == null
            ? fallbackColumn
            : max(0, _columnIndex(reference));
        fallbackColumn = column + 1;
        cells[column] = _cellText(cell, sharedStrings);
      }
      if (cells.isEmpty) continue;
      final values = List<String>.filled(cells.keys.reduce(max) + 1, '');
      for (final entry in cells.entries) {
        values[entry.key] = entry.value;
      }
      byRow[rowNumber] = values;
    }
    if (byRow.isEmpty) return const [];
    final lastRow = byRow.keys.reduce(max);
    return [for (var row = 1; row <= lastRow; row++) byRow[row] ?? const []];
  }

  /// Shared strings are the workbook's string table; cells reference them by
  /// index, so the sheet is unreadable without them.
  List<String> _readSharedStrings(Archive archive) {
    final entry = archive.find('xl/sharedStrings.xml');
    if (entry == null) return const [];
    final document = _tryParseXml(_entryText(entry));
    if (document == null) return const [];
    return [
      for (final item in _descendantElements(document.rootElement, 'si'))
        _allText(item),
    ];
  }

  /// The lexicographically first worksheet, which is sheet one in every
  /// workbook Excel and Google Sheets produce.
  ArchiveFile? _firstWorksheet(Archive archive) {
    final sheets =
        archive.files
            .where(
              (file) =>
                  file.isFile &&
                  file.name.startsWith('xl/worksheets/') &&
                  file.name.endsWith('.xml'),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return sheets.isEmpty ? null : sheets.first;
  }

  String _cellText(XmlElement cell, List<String> sharedStrings) {
    switch (cell.getAttribute('t')) {
      case 's':
        final index = int.tryParse(_childText(cell, 'v'));
        if (index == null || index < 0 || index >= sharedStrings.length) {
          return '';
        }
        return sharedStrings[index].trim();
      case 'inlineStr':
        return _childText(cell, 'is').trim();
      case 'b':
        return _childText(cell, 'v') == '1' ? 'TRUE' : 'FALSE';
      case 'e':
        // A formula error is an empty cell, not a value to import.
        return '';
      default:
        return _numericCellText(_childText(cell, 'v'));
    }
  }

  /// Numbers stay as written, except an Excel time of day.
  ///
  /// Excel stores a clock time as a fraction of a day, so `0.388…` is 9:20 AM.
  /// Integers are left alone because a day column is often written `1`–`7`.
  String _numericCellText(String raw) {
    final value = raw.trim();
    if (!value.contains('.')) return value;
    final number = double.tryParse(value);
    if (number == null) return value;
    if (number > 0 && number < 1) return _excelTimeText(number);
    return value;
  }

  String _excelTimeText(double fraction) =>
      _clockText((fraction * 24 * 60).round() % (24 * 60));

  String _decodeCsv(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const TimetableImportFileException(
        'This file is not UTF-8 text. Save it again as CSV (UTF-8) and try '
        'once more.',
      );
    }
  }

  Archive _openArchive(Uint8List bytes, String failureMessage) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw TimetableImportFileException(failureMessage);
    }
  }

  XmlDocument _parseXml(String text, String failureMessage) {
    final document = _tryParseXml(text);
    if (document == null) throw TimetableImportFileException(failureMessage);
    return document;
  }

  XmlDocument? _tryParseXml(String text) {
    try {
      return XmlDocument.parse(text);
    } catch (_) {
      return null;
    }
  }

  String _entryText(ArchiveFile entry) {
    final bytes = entry.readBytes();
    if (bytes == null) return '';
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// A 12-hour clock label for minutes after midnight.
///
/// It matches the times the row parser already accepts, so an Excel time cell
/// cannot drift from the format a CSV cell uses.
String _clockText(int totalMinutes) {
  final hour24 = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
}

/// Zero-based column index from an Excel cell reference such as `AB12`.
int _columnIndex(String reference) {
  var index = 0;
  for (final code in reference.codeUnits) {
    if (code < 0x41 || code > 0x5A) break;
    index = index * 26 + (code - 0x40);
  }
  return index == 0 ? 0 : index - 1;
}

/// Every `t` value inside [node], which is how a shared string or a Word run
/// spells its text.
String _allText(XmlNode node) =>
    _descendantElements(node, 't').map((element) => element.innerText).join();

String _childText(XmlElement parent, String local) =>
    _childElements(parent, local).map((element) => element.innerText).join();

Iterable<XmlElement> _childElements(XmlElement parent, String local) =>
    parent.childElements.where((element) => element.name.local == local);

Iterable<XmlElement> _descendantElements(XmlNode node, String local) => node
    .descendants
    .whereType<XmlElement>()
    .where((element) => element.name.local == local);
