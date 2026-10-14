import 'package:college_os/features/subjects/domain/subject_repository.dart';

/// Formats a stored attendance target as the whole percentage the app shows.
String formatAttendanceTarget(double target) => '${(target * 100).round()}%';

/// The subjects that still compare against a target other than the stored
/// default, across every semester.
///
/// CollegeOS keeps a target on each subject and re-applies the default whenever
/// it changes, so a subject created or imported before that change keeps the
/// older value while Settings reports the new one. This names that gap; the
/// student stays in charge of closing it, because a per-subject target may be
/// deliberate.
final class AttendanceTargetMismatch {
  /// Keeps only the [subjects] whose own target differs from [defaultTarget].
  AttendanceTargetMismatch({
    required this.defaultTarget,
    required Iterable<Subject> subjects,
  }) : subjects = List.unmodifiable(
         subjects.where((subject) => subject.attendanceTarget != defaultTarget),
       );

  /// The target "every subject" is meant to compare against.
  final double defaultTarget;

  /// The subjects holding a target other than [defaultTarget].
  final List<Subject> subjects;

  bool get hasMismatch => subjects.isNotEmpty;

  int get count => subjects.length;

  /// The distinct older targets, ascending, for the notice's summary.
  List<double> get strayTargets {
    final values = {
      for (final subject in subjects) subject.attendanceTarget,
    }.toList()..sort();
    return List.unmodifiable(values);
  }

  /// One line naming the gap, e.g. `12 subjects still compare against 75%`.
  String get summary => switch (strayTargets) {
    [] => '',
    [final only] =>
      '${_subjectCount()} still ${count == 1 ? 'compares' : 'compare'} '
          'against ${formatAttendanceTarget(only)}',
    _ =>
      '${_subjectCount()} ${count == 1 ? 'uses a target' : 'use targets'} '
          'other than ${formatAttendanceTarget(defaultTarget)}',
  };

  /// Names the repair on the control that applies it.
  String get actionLabel => 'Use ${formatAttendanceTarget(defaultTarget)}';

  String _subjectCount() => count == 1 ? '1 subject' : '$count subjects';
}
