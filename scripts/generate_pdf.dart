// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:ui';

void main() {
  test('generate heavy benchmark pdf', () async {
    final document = PdfDocument();
    final font = PdfStandardFont(PdfFontFamily.helvetica, 8);
    final random = Random(42);

    // Generate unique text for each page to prevent compression
    for (int i = 0; i < 412; i++) {
      final sb = StringBuffer();
      for (int j = 0; j < 3000; j++) {
        // completely random string
        final chars = List.generate(
          60,
          (index) => String.fromCharCode(random.nextInt(26) + 97),
        );
        sb.writeln(chars.join(''));
      }
      final page = document.pages.add();
      page.graphics.drawString(
        sb.toString(),
        font,
        bounds: Rect.fromLTWH(
          0,
          0,
          page.getClientSize().width,
          page.getClientSize().height,
        ),
      );
      if (i % 50 == 0) print('Generated $i pages');
    }

    final file = File('scripts/benchmark_heavy.pdf');
    file.writeAsBytesSync(await document.save());
    document.dispose();

    final malformedFile = File('scripts/benchmark_heavy_malformed.pdf');
    malformedFile.writeAsBytesSync(file.readAsBytesSync());
    malformedFile.writeAsStringSync(
      '  \n\r  some garbage after EOF\n',
      mode: FileMode.append,
    );

    print('Saved clean heavy PDF: ${file.lengthSync()} bytes');
  });
}
