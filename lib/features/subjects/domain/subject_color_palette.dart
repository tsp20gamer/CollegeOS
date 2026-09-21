import 'package:flutter/material.dart';

abstract final class SubjectColorPalette {
  static const values = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFF65A30D),
    Color(0xFFCA8A04),
    Color(0xFFEA580C),
    Color(0xFFDC2626),
    Color(0xFFDB2777),
    Color(0xFF9333EA),
  ];

  static int get defaultValue => values.first.toARGB32();
}
