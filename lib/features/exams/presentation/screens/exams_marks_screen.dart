import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/exams/application/exam_mark_providers.dart';
import 'package:college_os/features/exams/domain/exam_repository.dart';
import 'package:college_os/features/exams/domain/exam_service.dart';
import 'package:college_os/features/exams/presentation/widgets/exam_form_sheet.dart';
import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:college_os/features/marks/domain/marks_service.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _AssessmentView { exams, performance }

class ExamsMarksScreen extends ConsumerStatefulWidget {
  const ExamsMarksScreen({this.focusExamId, super.key});

  final int? focusExamId;

  @override
  ConsumerState<ExamsMarksScreen> createState() => _ExamsMarksScreenState();
}

class _ExamsMarksScreenState extends ConsumerState<ExamsMarksScreen> {
  _AssessmentView _view = _AssessmentView.exams;
  bool _focusedExamShown = false;

  @override
  void didUpdateWidget(covariant ExamsMarksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusExamId != widget.focusExamId) {
      _focusedExamShown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final examsAsync = ref.watch(semesterExamsProvider);
    final marksAsync = ref.watch(semesterMarksProvider);
    final subjects = subjectsAsync.value ?? const <Subject>[];
    final activeSubjects = subjects
        .where((subject) => !subject.isArchived)
        .toList(growable: false);
    final focusedExam = examsAsync.value
        ?.where((exam) => exam.id == widget.focusExamId)
        .firstOrNull;
    if (focusedExam != null &&
        !_focusedExamShown &&
        semester.value != null &&
        activeSubjects.isNotEmpty) {
      _focusedExamShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showExamForm(
          semesterId: semester.value!.id,
          subjects: activeSubjects,
          exam: focusedExam,
        );
      });
    }
    return AppScaffold(
      title: 'Exams & marks',
      subtitle: semester.value?.name ?? 'Assessments and recorded performance.',
      actions: [
        if (_view == _AssessmentView.exams)
          IconButton.filledTonal(
            key: const Key('add_exam_button'),
            tooltip: 'Add exam',
            onPressed: semester.value == null || activeSubjects.isEmpty
                ? null
                : () => _showExamForm(
                    semesterId: semester.value!.id,
                    subjects: activeSubjects,
                  ),
            icon: const Icon(Icons.add_rounded),
          ),
      ],
      child: semester.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          title: 'Could not load the semester',
          message: error.toString(),
        ),
        data: (activeSemester) {
          if (activeSemester == null) {
            return const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No active semester',
              message: 'Make a semester active before tracking assessments.',
            );
          }
          if (subjectsAsync.isLoading ||
              examsAsync.isLoading ||
              marksAsync.isLoading) {
            return const LoadingState(label: 'Loading assessments');
          }
          if (subjectsAsync.hasError ||
              examsAsync.hasError ||
              marksAsync.hasError) {
            return ErrorState(
              title: 'Could not load assessments',
              message:
                  '${subjectsAsync.error ?? examsAsync.error ?? marksAsync.error}',
            );
          }
          if (activeSubjects.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Add a subject first',
              message: 'Exams and marks are always associated with a subject.',
              action: FilledButton.icon(
                onPressed: () => context.push(RoutePaths.subjects),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Manage subjects'),
              ),
            );
          }
          return _content(
            semesterId: activeSemester.id,
            subjects: activeSubjects,
            exams: examsAsync.value!,
            marks: marksAsync.value!,
          );
        },
      ),
    );
  }

  Widget _content({
    required int semesterId,
    required List<Subject> subjects,
    required List<Exam> exams,
    required List<Mark> marks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_AssessmentView>(
          key: const Key('assessment_view_selector'),
          segments: const [
            ButtonSegment(
              value: _AssessmentView.exams,
              icon: Icon(Icons.event_note_rounded),
              label: Text('Exams'),
            ),
            ButtonSegment(
              value: _AssessmentView.performance,
              icon: Icon(Icons.insights_rounded),
              label: Text('Performance'),
            ),
          ],
          selected: {_view},
          showSelectedIcon: false,
          onSelectionChanged: (value) => setState(() => _view = value.single),
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _view == _AssessmentView.exams
              ? _ExamsView(
                  key: const ValueKey('exams'),
                  semesterId: semesterId,
                  subjects: subjects,
                  exams: exams,
                  onEdit: (exam) => _showExamForm(
                    semesterId: semesterId,
                    subjects: subjects,
                    exam: exam,
                  ),
                  onDelete: _deleteExam,
                  onAdd: () =>
                      _showExamForm(semesterId: semesterId, subjects: subjects),
                )
              : _PerformanceView(
                  key: const ValueKey('performance'),
                  subjects: subjects,
                  marks: marks,
                ),
        ),
      ],
    );
  }

  Future<void> _showExamForm({
    required int semesterId,
    required List<Subject> subjects,
    Exam? exam,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) =>
        ExamFormSheet(semesterId: semesterId, subjects: subjects, exam: exam),
  );

  Future<void> _deleteExam(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete exam?'),
        content: Text(
          'Delete “${exam.name}”? Marks directly linked to this exam are also removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(examCommandProvider.notifier)
        .deleteExam(exam.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Exam deleted' : 'Could not delete exam'),
      ),
    );
  }
}

class _ExamsView extends StatelessWidget {
  const _ExamsView({
    required this.semesterId,
    required this.subjects,
    required this.exams,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    super.key,
  });

  final int semesterId;
  final List<Subject> subjects;
  final List<Exam> exams;
  final ValueChanged<Exam> onEdit;
  final ValueChanged<Exam> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming = ExamService.upcoming(exams, now);
    final past = ExamService.past(exams, now);
    final subjectById = {for (final subject in subjects) subject.id: subject};
    if (exams.isEmpty) {
      return EmptyState(
        icon: Icons.event_note_rounded,
        title: 'No exams yet',
        message:
            'Add upcoming assessments and keep their details in one place.',
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add exam'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ListHeader(title: 'Upcoming exams', count: upcoming.length),
        const SizedBox(height: AppSpacing.sm),
        if (upcoming.isEmpty)
          const _CompactEmpty(message: 'No upcoming exams.')
        else
          for (var i = 0; i < upcoming.length; i++) ...[
            _ExamCard(
              exam: upcoming[i],
              subject: subjectById[upcoming[i].subjectId],
              today: now,
              onEdit: () => onEdit(upcoming[i]),
              onDelete: () => onDelete(upcoming[i]),
            ),
            if (i != upcoming.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.xl),
        _ListHeader(title: 'Past exams', count: past.length),
        const SizedBox(height: AppSpacing.sm),
        if (past.isEmpty)
          const _CompactEmpty(message: 'No past exams in this semester.')
        else
          for (var i = 0; i < past.length; i++) ...[
            _ExamCard(
              exam: past[i],
              subject: subjectById[past[i].subjectId],
              today: now,
              onEdit: () => onEdit(past[i]),
              onDelete: () => onDelete(past[i]),
            ),
            if (i != past.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.subject,
    required this.today,
    required this.onEdit,
    required this.onDelete,
  });

  final Exam exam;
  final Subject? subject;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final days = ExamService.daysUntil(exam.examDate, today);
    final countdownColor = days < 0
        ? colors.onSurfaceVariant
        : days <= 1
        ? semantic.warning
        : colors.primary;
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: countdownColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat.MMM().format(exam.examDate).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: countdownColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${exam.examDate.day}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: countdownColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        subject?.shortCode.isNotEmpty == true
                            ? subject!.shortCode
                            : subject?.name,
                        exam.examType,
                      ].whereType<String>().join('  •  '),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      ExamService.countdown(exam.examDate, today),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: countdownColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (exam.startTime != null || exam.room.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (exam.startTime != null)
                            _formatTime(context, exam.startTime!),
                          if (exam.room.isNotEmpty) exam.room,
                        ].join('  •  '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (exam.maxMarks != null ||
                        exam.obtainedMarks != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        exam.obtainedMarks == null
                            ? 'Maximum ${_formatNumber(exam.maxMarks!)} marks'
                            : exam.maxMarks == null
                            ? '${_formatNumber(exam.obtainedMarks!)} marks obtained'
                            : '${_formatNumber(exam.obtainedMarks!)} / ${_formatNumber(exam.maxMarks!)} marks',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_ExamAction>(
                tooltip: 'Exam actions',
                onSelected: (action) => switch (action) {
                  _ExamAction.edit => onEdit(),
                  _ExamAction.delete => onDelete(),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _ExamAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _ExamAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceView extends StatelessWidget {
  const _PerformanceView({
    required this.subjects,
    required this.marks,
    super.key,
  });

  final List<Subject> subjects;
  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('SGPA/CGPA setup can be configured later.')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < subjects.length; i++) ...[
          _SubjectPerformanceCard(
            subject: subjects[i],
            marks: marks
                .where((mark) => mark.subjectId == subjects[i].id)
                .toList(growable: false),
          ),
          if (i != subjects.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SubjectPerformanceCard extends StatelessWidget {
  const _SubjectPerformanceCard({required this.subject, required this.marks});

  final Subject subject;
  final List<Mark> marks;

  @override
  Widget build(BuildContext context) {
    final summary = MarksService.summarize(marks);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.subjectPerformance,
          pathParameters: {'subjectId': subject.id.toString()},
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(
                  subject.displayColor,
                ).withValues(alpha: 0.12),
                foregroundColor: Color(subject.displayColor),
                child: Text(
                  subject.shortCode.isEmpty
                      ? subject.name.characters.first.toUpperCase()
                      : subject.shortCode.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      summary.assessmentCount == 0
                          ? 'No marks recorded'
                          : '${summary.assessmentCount} recorded ${summary.assessmentCount == 1 ? 'assessment' : 'assessments'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary.percentage == null
                        ? '—'
                        : '${summary.percentage!.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Simple total',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      Text('$count', style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

enum _ExamAction { edit, delete }

String _formatTime(BuildContext context, int minutes) {
  final safe = minutes == 1440 ? 0 : minutes;
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: safe ~/ 60, minute: safe % 60));
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
