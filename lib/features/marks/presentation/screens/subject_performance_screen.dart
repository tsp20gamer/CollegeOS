import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/exams/application/exam_mark_providers.dart';
import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:college_os/features/marks/domain/marks_service.dart';
import 'package:college_os/features/marks/presentation/widgets/mark_form_sheet.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SubjectPerformanceScreen extends ConsumerWidget {
  const SubjectPerformanceScreen({required this.subjectId, super.key});

  final int subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(performanceSubjectProvider(subjectId));
    final marks = ref.watch(subjectMarksProvider(subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('Subject performance')),
      floatingActionButton: subject.value == null
          ? null
          : PressScale(
              pressedScale: .95,
              child: FloatingActionButton.extended(
                key: const Key('add_mark_button'),
                onPressed: () => _showMarkForm(context, subjectId),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Record marks'),
              ),
            ),
      body: SafeArea(
        top: false,
        child: subject.when(
          loading: () => const LoadingState(label: 'Loading subject'),
          error: (error, _) => ErrorState(
            title: 'Could not load subject',
            message: error.toString(),
          ),
          data: (value) {
            if (value == null) {
              return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Subject not found',
                message: 'This subject may have been removed.',
              );
            }
            return marks.when(
              loading: () => const LoadingState(label: 'Loading marks'),
              error: (error, _) => ErrorState(
                title: 'Could not load marks',
                message: error.toString(),
              ),
              data: (items) => _PerformanceBody(
                subjectId: subjectId,
                subjectName: value.name,
                shortCode: value.shortCode,
                displayColor: value.displayColor,
                marks: items,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PerformanceBody extends ConsumerWidget {
  const _PerformanceBody({
    required this.subjectId,
    required this.subjectName,
    required this.shortCode,
    required this.displayColor,
    required this.marks,
  });

  final int subjectId;
  final String subjectName;
  final String shortCode;
  final int displayColor;
  final List<Mark> marks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = MarksService.summarize(marks);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppLayout.scaffoldBottomPadding(context),
      ),
      children: [
        _SummaryCard(
          subjectName: subjectName,
          shortCode: shortCode,
          displayColor: displayColor,
          summary: summary,
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recorded assessments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text('${marks.length}'),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (marks.isEmpty)
          EmptyState(
            icon: Icons.assessment_outlined,
            title: 'No marks recorded',
            message:
                'Record an internal, assignment, lab, semester exam, or other result.',
            action: FilledButton.icon(
              onPressed: () => _showMarkForm(context, subjectId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record marks'),
            ),
          )
        else
          for (var index = 0; index < marks.length; index++) ...[
            _MarkCard(
              mark: marks[index],
              onEdit: () =>
                  _showMarkForm(context, subjectId, mark: marks[index]),
              onDelete: () => _deleteMark(context, ref, marks[index]),
            ),
            if (index != marks.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subjectName,
    required this.shortCode,
    required this.displayColor,
    required this.summary,
  });

  final String subjectName;
  final String shortCode;
  final int displayColor;
  final MarksSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(displayColor);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (shortCode.isNotEmpty) Text(shortCode),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  value: summary.percentage == null
                      ? '—'
                      : '${summary.percentage!.toStringAsFixed(1)}%',
                  label: 'Simple total',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value:
                      '${_number(summary.obtained)} / ${_number(summary.maximum)}',
                  label: 'Recorded marks',
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  value: '${summary.assessmentCount}',
                  label: 'Assessments',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This combines recorded raw marks only. It is not an institutional GPA calculation.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ],
  );
}

class _MarkCard extends StatelessWidget {
  const _MarkCard({
    required this.mark,
    required this.onEdit,
    required this.onDelete,
  });

  final Mark mark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final percentage = MarksService.percentage(
      mark.obtainedMarks,
      mark.maxMarks,
    );
    final category = MarkCategoryDetails.fromDatabase(mark.category);
    final colors = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final color = percentage == null
        ? colors.onSurfaceVariant
        : percentage >= 75
        ? semantic.success
        : percentage >= 50
        ? semantic.warning
        : colors.error;
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.10),
                foregroundColor: color,
                child: Text(
                  percentage == null ? '—' : '${percentage.round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${_number(mark.obtainedMarks)} / ${_number(mark.maxMarks)}  •  ${DateFormat.yMMMd().format(mark.date)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (mark.note.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        mark.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_MarkAction>(
                tooltip: 'Marks actions',
                onSelected: (action) => switch (action) {
                  _MarkAction.edit => onEdit(),
                  _MarkAction.delete => onDelete(),
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _MarkAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _MarkAction.delete,
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

enum _MarkAction { edit, delete }

Future<void> _showMarkForm(BuildContext context, int subjectId, {Mark? mark}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => MarkFormSheet(subjectId: subjectId, mark: mark),
    );

Future<void> _deleteMark(BuildContext context, WidgetRef ref, Mark mark) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete marks?'),
      content: Text(
        'Delete the ${MarkCategoryDetails.fromDatabase(mark.category).label} result?',
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
  if (confirmed != true || !context.mounted) return;
  final success = await ref
      .read(markCommandProvider.notifier)
      .deleteMark(mark.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success ? 'Marks deleted' : 'Could not delete marks'),
    ),
  );
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
