abstract final class CollegeSetupValidator {
  static String? requiredText(
    String? value, {
    required String fieldName,
    int maxLength = 120,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$fieldName is required.';
    if (text.length > maxLength) {
      return '$fieldName must be $maxLength characters or fewer.';
    }
    return null;
  }

  static String? semesterNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a valid semester number.';
    if (number < 1 || number > 20) {
      return 'Semester number must be between 1 and 20.';
    }
    return null;
  }

  static String? academicYear(String? value) {
    final text = value?.trim() ?? '';
    final match = RegExp(r'^(\d{4})\s*[-\u2013]\s*(\d{4})$').firstMatch(text);
    if (match == null) return 'Use the format 2026-2027.';
    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2)!);
    if (end != start + 1) return 'Academic year must span one year.';
    return null;
  }

  static String? attendanceTarget(String? value) {
    final percent = double.tryParse(value?.trim() ?? '');
    if (percent == null) return 'Enter a valid percentage.';
    if (percent < 1 || percent > 100) {
      return 'Attendance target must be between 1% and 100%.';
    }
    return null;
  }

  static String? dateRange(
    DateTime semesterStart,
    DateTime semesterEnd, {
    DateTime? academicStart,
    DateTime? academicEnd,
  }) {
    academicStart ??= semesterStart;
    academicEnd ??= semesterEnd;
    if (!academicStart.isBefore(academicEnd)) {
      return 'Academic year start must be before its end.';
    }
    if (semesterStart.isBefore(academicStart)) {
      return 'Semester cannot start before the academic year.';
    }
    if (semesterEnd.isAfter(academicEnd)) {
      return 'Semester cannot end after the academic year.';
    }
    if (!semesterStart.isBefore(semesterEnd)) {
      return 'Semester start must be before its end.';
    }
    return null;
  }
}
