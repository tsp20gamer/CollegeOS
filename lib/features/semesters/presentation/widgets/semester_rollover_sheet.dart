import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

Future<void> showSemesterRolloverSheet(BuildContext context, Semester active) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _SemesterRolloverSheet(active: active),
    );

class _SemesterRolloverSheet extends ConsumerStatefulWidget {
  const _SemesterRolloverSheet({required this.active});

  final Semester active;

  @override
  ConsumerState<_SemesterRolloverSheet> createState() =>
      _SemesterRolloverSheetState();
}

class _SemesterRolloverSheetState
    extends ConsumerState<_SemesterRolloverSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _semesterNumber;
  late final TextEditingController _academicYear;
  late DateTime _academicStart;
  late DateTime _academicEnd;
  late DateTime _semesterStart;
  late DateTime _semesterEnd;
  bool _copySubjects = true;
  bool _copyTimetable = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(collegeSettingsProvider).value;
    _semesterNumber = TextEditingController(
      text: '${widget.active.semesterNumber + 1}',
    );
    _academicYear = TextEditingController(text: widget.active.academicYear);
    _academicStart = settings?.academicYearStartDate ?? widget.active.startDate;
    _academicEnd = settings?.academicYearEndDate ?? widget.active.endDate;
    _semesterStart = widget.active.endDate.add(const Duration(days: 1));
    if (_semesterStart.isAfter(_academicEnd)) {
      _academicStart = _semesterStart;
      _academicEnd = DateTime(
        _semesterStart.year + 1,
        _semesterStart.month,
        _semesterStart.day - 1,
      );
      _academicYear.text = '${_semesterStart.year}-${_semesterStart.year + 1}';
    }
    final suggestedEnd = _semesterStart.add(const Duration(days: 120));
    _semesterEnd = suggestedEnd.isAfter(_academicEnd)
        ? _academicEnd
        : suggestedEnd;
  }

  @override
  void dispose() {
    _semesterNumber.dispose();
    _academicYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(semesterRolloverControllerProvider).isLoading;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Start the next semester',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.active.name} remains preserved as history. The new semester becomes active only after everything is copied successfully.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('rollover_semester_number'),
                      controller: _semesterNumber,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Semester number',
                      ),
                      validator: (value) =>
                          (int.tryParse(value ?? '') ?? 0) <= 0
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      key: const Key('rollover_academic_year'),
                      controller: _academicYear,
                      decoration: const InputDecoration(
                        labelText: 'Academic year',
                        hintText: '2026-2027',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DatePair(
                first: _DateField(
                  label: 'Academic year starts',
                  value: _academicStart,
                  onTap: () => _pick(_DateKind.academicStart),
                ),
                second: _DateField(
                  label: 'Academic year ends',
                  value: _academicEnd,
                  onTap: () => _pick(_DateKind.academicEnd),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DatePair(
                first: _DateField(
                  label: 'Semester starts',
                  value: _semesterStart,
                  onTap: () => _pick(_DateKind.semesterStart),
                ),
                second: _DateField(
                  label: 'Semester ends',
                  value: _semesterEnd,
                  onTap: () => _pick(_DateKind.semesterEnd),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('rollover_copy_subjects'),
                      value: _copySubjects,
                      onChanged: (value) => setState(() {
                        _copySubjects = value;
                        if (!value) _copyTimetable = false;
                      }),
                      title: const Text('Copy active subjects'),
                      subtitle: const Text(
                        'Copies names, lecturers, rooms, colors, and targets',
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('rollover_copy_timetable'),
                      value: _copyTimetable,
                      onChanged: !_copySubjects
                          ? null
                          : (value) => setState(() => _copyTimetable = value),
                      title: const Text('Copy weekly timetable'),
                      subtitle: const Text(
                        'Creates new entries linked to the copied subjects',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('complete_semester_rollover'),
                onPressed: busy ? null : _save,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Create and activate semester'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(_DateKind kind) async {
    final current = switch (kind) {
      _DateKind.academicStart => _academicStart,
      _DateKind.academicEnd => _academicEnd,
      _DateKind.semesterStart => _semesterStart,
      _DateKind.semesterEnd => _semesterEnd,
    };
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      switch (kind) {
        case _DateKind.academicStart:
          _academicStart = picked;
        case _DateKind.academicEnd:
          _academicEnd = picked;
        case _DateKind.semesterStart:
          _semesterStart = picked;
        case _DateKind.semesterEnd:
          _semesterEnd = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_academicStart.isBefore(_academicEnd) ||
        _semesterStart.isBefore(_academicStart) ||
        _semesterEnd.isAfter(_academicEnd) ||
        !_semesterStart.isBefore(_semesterEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Check that semester dates fit inside the academic year.',
          ),
        ),
      );
      return;
    }
    final result = await ref
        .read(semesterRolloverControllerProvider.notifier)
        .rollover((
          sourceSemesterId: widget.active.id,
          semesterNumber: int.parse(_semesterNumber.text),
          academicYear: _academicYear.text.trim(),
          academicYearStartDate: _academicStart,
          academicYearEndDate: _academicEnd,
          semesterStartDate: _semesterStart,
          semesterEndDate: _semesterEnd,
          copySubjects: _copySubjects,
          copyTimetable: _copyTimetable,
        ));
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the semester. Nothing was changed.'),
        ),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semester created • ${result.subjectsCopied} subjects • ${result.timetableEntriesCopied} classes',
        ),
      ),
    );
  }
}

enum _DateKind { academicStart, academicEnd, semesterStart, semesterEnd }

class _DatePair extends StatelessWidget {
  const _DatePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: first),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: second),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    child: Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(DateFormat.MMMd().format(value)),
      ],
    ),
  );
}
