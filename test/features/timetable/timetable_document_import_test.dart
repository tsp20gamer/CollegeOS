import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:college_os/features/timetable/data/timetable_document_readers.dart';
import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Excel and Word timetables reach the same preview the CSV path uses.
///
/// The fixtures are real (small) OOXML containers built here, so the readers
/// are exercised against the zip layout Excel and Word actually write rather
/// than against a hand-written string.
void main() {
  const reader = TimetableDocumentReader();

  test('reads an Excel timetable and parses it like CSV', () {
    final rows = reader.readRows(
      fileName: 'semester.xlsx',
      bytes: _xlsxFixture(),
    );
    final preview = const TimetableTableParser().parseRows(
      fileName: 'semester.xlsx',
      rows: rows,
      subjects: const [],
      existingEntries: const [],
    );

    expect(preview.importCount, 2);
    expect(preview.newSubjectCount, 2);
    // Excel stores 9:00 AM as the fraction 0.375 of a day.
    expect(preview.candidates.first.row.startTime, 540);
    expect(preview.candidates.first.row.endTime, 600);
    // A shared string split into runs still arrives as one subject name.
    expect(preview.candidates[1].row.subjectName, 'English Communication');
    expect(preview.candidates[1].row.shortCode, 'EC');
    // The invalid weekday is reported by line, exactly as it is for CSV.
    expect(preview.issues.single.line, 4);
  });

  test('reads a Word timetable table', () {
    final rows = reader.readRows(fileName: 'semester.docx', bytes: _docx());
    final preview = const TimetableTableParser().parseRows(
      fileName: 'semester.docx',
      rows: rows,
      subjects: const [],
      existingEntries: const [],
    );

    expect(preview.importCount, 1);
    expect(preview.candidates.single.row.subjectName, 'Mathematics');
    expect(preview.candidates.single.row.weekday, DateTime.monday);
    expect(preview.candidates.single.row.startTime, 560);
  });

  test('reads CSV bytes through the same entry point', () {
    final rows = reader.readRows(
      fileName: 'semester.csv',
      bytes: Uint8List.fromList(
        'Day,Start,End,Subject\nSaturday,09:00,10:00,Mathematics'.codeUnits,
      ),
    );

    expect(rows, hasLength(2));
    expect(rows.first, ['Day', 'Start', 'End', 'Subject']);
  });

  test('a Word document without a table is explained, not guessed', () {
    expect(
      () => reader.readRows(
        fileName: 'notes.docx',
        bytes: _docx(
          documentXml:
              '<w:document xmlns:w="http://schemas.openxmlformats.org/'
              'wordprocessingml/2006/main"><w:body><w:p><w:r>'
              '<w:t>Monday 9:20 Mathematics</w:t></w:r></w:p></w:body>'
              '</w:document>',
        ),
      ),
      throwsA(
        isA<TimetableImportFileException>().having(
          (error) => error.message,
          'message',
          contains('Insert → Table'),
        ),
      ),
    );
  });

  test('legacy .xls and .doc are refused with the way forward', () {
    expect(
      () => reader.readRows(fileName: 'semester.xls', bytes: Uint8List(0)),
      throwsA(
        isA<TimetableImportFileException>().having(
          (error) => error.message,
          'message',
          contains('save it as .xlsx'),
        ),
      ),
    );
    expect(
      () => reader.readRows(fileName: 'semester.doc', bytes: Uint8List(0)),
      throwsA(
        isA<TimetableImportFileException>().having(
          (error) => error.message,
          'message',
          contains('save it as .docx'),
        ),
      ),
    );
  });

  test('a workbook that is not a zip reports itself', () {
    expect(
      () => reader.readRows(
        fileName: 'semester.xlsx',
        bytes: Uint8List.fromList('not a workbook'.codeUnits),
      ),
      throwsA(
        isA<TimetableImportFileException>().having(
          (error) => error.message,
          'message',
          contains('could not be opened'),
        ),
      ),
    );
  });

  test('CSV text that is not UTF-8 is reported', () {
    expect(
      () => reader.readRows(
        fileName: 'semester.csv',
        bytes: Uint8List.fromList([0xC3, 0x28, 0x0A]),
      ),
      throwsA(
        isA<TimetableImportFileException>().having(
          (error) => error.message,
          'message',
          contains('UTF-8'),
        ),
      ),
    );
  });
}

Uint8List _xlsxFixture() {
  final archive = Archive()
    ..add(ArchiveFile.string('xl/sharedStrings.xml', _sharedStrings))
    ..add(ArchiveFile.string('xl/worksheets/sheet1.xml', _sheet));
  return ZipEncoder().encodeBytes(archive);
}

Uint8List _docx({String? documentXml}) {
  final archive = Archive()
    ..add(
      ArchiveFile.string('word/document.xml', documentXml ?? _wordDocument),
    );
  return ZipEncoder().encodeBytes(archive);
}

const _sharedStrings = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="9" uniqueCount="9">
<si><t>Day</t></si>
<si><t>Start</t></si>
<si><t>End</t></si>
<si><t>Subject</t></si>
<si><t>Code</t></si>
<si><t>Mathematics</t></si>
<si><t>MC</t></si>
<si><r><t>English</t></r><r><t> Communication</t></r></si>
<si><t>EC</t></si>
</sst>
''';

const _sheet = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData>
<row r="1">
<c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="s"><v>2</v></c>
<c r="D1" t="s"><v>3</v></c><c r="E1" t="s"><v>4</v></c>
</row>
<row r="2">
<c r="A2" t="inlineStr"><is><t>Saturday</t></is></c><c r="B2"><v>0.375</v></c>
<c r="C2"><v>0.4166666666666667</v></c><c r="D2" t="s"><v>5</v></c>
<c r="E2" t="s"><v>6</v></c>
</row>
<row r="3">
<c r="A3" t="inlineStr"><is><t>Tuesday</t></is></c><c r="B3" t="inlineStr"><is><t>11:00</t></is></c>
<c r="C3" t="inlineStr"><is><t>11:50</t></is></c><c r="D3" t="s"><v>7</v></c>
<c r="E3" t="s"><v>8</v></c>
</row>
<row r="4">
<c r="A4" t="inlineStr"><is><t>Funday</t></is></c><c r="B4" t="inlineStr"><is><t>11:00</t></is></c>
<c r="C4" t="inlineStr"><is><t>12:00</t></is></c><c r="D4" t="s"><v>5</v></c>
</row>
</sheetData>
</worksheet>
''';

const _wordDocument = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:tbl>
<w:tr>
<w:tc><w:p><w:r><w:t>Day</w:t></w:r></w:p></w:tc>
<w:tc><w:p><w:r><w:t>Start</w:t></w:r></w:p></w:tc>
<w:tc><w:p><w:r><w:t>End</w:t></w:r></w:p></w:tc>
<w:tc><w:p><w:r><w:t>Subject</w:t></w:r></w:p></w:tc>
</w:tr>
<w:tr>
<w:tc><w:p><w:r><w:t>Monday</w:t></w:r></w:p></w:tc>
<w:tc><w:p><w:r><w:t>9:20 AM</w:t></w:r></w:p></w:tc>
<w:tc><w:p><w:r><w:t>10:10 AM</w:t></w:r></w:p></w:tc>
<w:tc><w:p><w:r><w:t>Mathematics</w:t></w:r></w:p></w:tc>
</w:tr>
</w:tbl>
</w:body>
</w:document>
''';
