import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/timetable/application/timetable_import_providers.dart';
import 'package:college_os/features/timetable/domain/timetable_import.dart';
import 'package:college_os/features/timetable/domain/timetable_repository.dart';
import 'package:college_os/features/timetable/domain/timetable_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showTimetableImportSheet(
  BuildContext context, {
  required Semester semester,
  required List<Subject> subjects,
  required List<TimetableEntry> entries,
  required double defaultAttendanceTarget,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _TimetableImportSheet(
    semester: semester,
    subjects: subjects,
    entries: entries,
    defaultAttendanceTarget: defaultAttendanceTarget,
  ),
);

class _TimetableImportSheet extends ConsumerStatefulWidget {
  const _TimetableImportSheet({
    required this.semester,
    required this.subjects,
    required this.entries,
    required this.defaultAttendanceTarget,
  });

  final Semester semester;
  final List<Subject> subjects;
  final List<TimetableEntry> entries;
  final double defaultAttendanceTarget;

  @override
  ConsumerState<_TimetableImportSheet> createState() =>
      _TimetableImportSheetState();
}

class _TimetableImportSheetState extends ConsumerState<_TimetableImportSheet> {
  TimetableImportPreview? _preview;
  bool _pickerOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pick());
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(timetableImportControllerProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Smart timetable import',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose a CSV, an Excel workbook (.xlsx) or a Word document (.docx). CollegeOS matches existing subjects, previews conflicts, skips exact duplicates, and creates missing subjects only after confirmation.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _TemplateHelp(onCopy: _copyTemplate),
            const SizedBox(height: AppSpacing.md),
            if (operation.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_preview == null)
              _ChooseFileCard(onChoose: _pick)
            else
              _PreviewCard(preview: _preview!),
            if (operation.hasError) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Could not import: ${operation.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_preview != null) ...[
              OutlinedButton.icon(
                onPressed: operation.isLoading ? null : _pick,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Choose another file'),
              ),
              const SizedBox(height: AppSpacing.xs),
              FilledButton.icon(
                key: const Key('confirm_timetable_import'),
                onPressed: operation.isLoading || _preview!.importCount == 0
                    ? null
                    : _commit,
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: Text('Import ${_preview!.importCount} classes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    if (!mounted || _pickerOpened) return;
    _pickerOpened = true;
    final preview = await ref
        .read(timetableImportControllerProvider.notifier)
        .chooseFile(subjects: widget.subjects, existingEntries: widget.entries);
    _pickerOpened = false;
    if (!mounted || preview == null) return;
    setState(() => _preview = preview);
  }

  Future<void> _commit() async {
    final result = await ref
        .read(timetableImportControllerProvider.notifier)
        .commit(
          semesterId: widget.semester.id,
          semesterStart: widget.semester.startDate,
          semesterEnd: widget.semester.endDate,
          defaultAttendanceTarget: widget.defaultAttendanceTarget,
          preview: _preview!,
        );
    if (!mounted || result == null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${result.entriesCreated} classes imported • ${result.subjectsCreated} subjects created • ${result.duplicatesSkipped} duplicates skipped',
        ),
      ),
    );
  }

  Future<void> _copyTemplate() async {
    await Clipboard.setData(const ClipboardData(text: timetableImportTemplate));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('CSV template copied.')));
  }
}

class _TemplateHelp extends StatelessWidget {
  const _TemplateHelp({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.table_view_outlined),
      title: const Text(
        'CSV, Excel or Word',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Flexible column names and 12/24-hour times'),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [
        const SelectableText(
          'Required: Day, Start, End, Subject\nOptional: Code, Professor, Room, Note',
        ),
        const SizedBox(height: AppSpacing.xs),
        const SelectableText(
          'Excel: one sheet, headers in the first row.\n'
          'Word: the timetable has to be a table (Insert → Table).\n'
          'Legacy .xls and .doc files must be saved again as .xlsx and .docx.',
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy example'),
          ),
        ),
      ],
    ),
  );
}

class _ChooseFileCard extends StatelessWidget {
  const _ChooseFileCard({required this.onChoose});

  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      children: [
        const Icon(Icons.upload_file_rounded, size: 40),
        const SizedBox(height: AppSpacing.sm),
        const Text('No timetable chosen'),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonal(
          key: const Key('choose_timetable_file'),
          onPressed: onChoose,
          child: const Text('Choose file'),
        ),
      ],
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final TimetableImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final importable = preview.candidates
        .where((candidate) => candidate.willImport)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _CountChip('${preview.importCount} classes'),
                    _CountChip('${preview.newSubjectCount} new subjects'),
                    _CountChip('${preview.duplicateCount} duplicates'),
                    _CountChip('${preview.overlapCount} overlaps'),
                    if (preview.issues.isNotEmpty)
                      _CountChip('${preview.issues.length} invalid rows'),
                  ],
                ),
                if (preview.overlapCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Overlapping classes are highlighted but will import because unusual schedules are allowed.',
                    style: TextStyle(color: colors.tertiary),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: importable.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final candidate = importable[index];
              final row = candidate.row;
              return ListTile(
                dense: true,
                leading: Icon(
                  candidate.hasOverlap
                      ? Icons.warning_amber_rounded
                      : candidate.createsSubject
                      ? Icons.add_circle_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: candidate.hasOverlap
                      ? colors.tertiary
                      : colors.primary,
                ),
                title: Text(
                  row.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${timetableDayNames[row.weekday]} • ${_time(row.startTime)}–${_time(row.endTime)}${row.room.isEmpty ? '' : ' • ${row.room}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: candidate.createsSubject
                    ? const Text('New subject')
                    : null,
              );
            },
          ),
        ),
        if (preview.issues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ExpansionTile(
            title: Text('${preview.issues.length} rows need correction'),
            children: [
              for (final issue in preview.issues.take(8))
                ListTile(
                  dense: true,
                  title: Text('Line ${issue.line}'),
                  subtitle: Text(issue.message),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(visualDensity: VisualDensity.compact, label: Text(label));
}

String _time(int minutes) {
  final hour24 = minutes ~/ 60;
  final minute = minutes % 60;
  final suffix = hour24 < 12 ? 'AM' : 'PM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} $suffix';
}
