abstract final class SubjectValidator {
  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Subject name is required.';
    if (text.length > 100) {
      return 'Subject name must be 100 characters or fewer.';
    }
    return null;
  }

  static String? optionalText(
    String? value, {
    required String fieldName,
    int maxLength = 80,
  }) {
    if ((value?.trim().length ?? 0) > maxLength) {
      return '$fieldName must be $maxLength characters or fewer.';
    }
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
}
