import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/semesters/application/semester_providers.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/semesters/presentation/widgets/semester_rollover_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SemesterManagementScreen extends ConsumerWidget {
  const SemesterManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesters = ref.watch(semestersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Semester Management')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_semester_button'),
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add semester'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl * 2,
          ),
          children: [
            Text(
              'Your academic timeline',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Switching the active semester changes the data shown across CollegeOS. Earlier semester history remains preserved.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (semesters.value
                    ?.where((semester) => semester.isActive)
                    .firstOrNull
                case final active?) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.next_plan_outlined),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready for the next semester?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Text(
                              'Preserve history and optionally copy subjects and timetable.',
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        key: const Key('start_next_semester_button'),
                        onPressed: () =>
                            showSemesterRolloverSheet(context, active),
                        child: const Text('Start'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            semesters.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Card(
                child: ListTile(
                  leading: Icon(Icons.error_outline_rounded),
                  title: Text('Could not load semesters'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptySemesters()
                  : Column(
                      children: [
                        for (final semester in items) ...[
                          _SemesterCard(
                            semester: semester,
                            onEdit: () =>
                                _openEditor(context, ref, semester: semester),
                            onActivate: semester.isActive
                                ? null
                                : () => _activate(context, ref, semester),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Semester? semester,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _SemesterEditor(semester: semester),
  );

  Future<void> _activate(
    BuildContext context,
    WidgetRef ref,
    Semester semester,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Make ${semester.name} active?'),
        content: const Text(
          'Dashboards, subjects, timetable, tasks, and exams will switch to this semester. No history will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Make active'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final saved = await ref
        .read(semesterControllerProvider.notifier)
        .setActive(semester.id);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not switch semester.')),
      );
    }
  }
}

class _SemesterCard extends StatelessWidget {
  const _SemesterCard({
    required this.semester,
    required this.onEdit,
    required this.onActivate,
  });

  final Semester semester;
  final VoidCallback onEdit;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dates =
        '${DateFormat.MMMd().format(semester.startDate)} – ${DateFormat.yMMMd().format(semester.endDate)}';
    return Card(
      color: semester.isActive ? colors.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    semester.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (semester.isActive)
                  const Chip(
                    avatar: Icon(Icons.check_circle_rounded, size: 18),
                    label: Text('Active'),
                  ),
                IconButton(
                  tooltip: 'Edit semester',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            Text(
              'Semester ${semester.semesterNumber} • ${semester.academicYear}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.date_range_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(dates)),
                if (onActivate != null)
                  TextButton(
                    onPressed: onActivate,
                    child: const Text('Make active'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySemesters extends StatelessWidget {
  const _EmptySemesters();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 40),
          SizedBox(height: AppSpacing.sm),
          Text('No semesters yet'),
        ],
      ),
    ),
  );
}

class _SemesterEditor extends ConsumerStatefulWidget {
  const _SemesterEditor({this.semester});
  final Semester? semester;

  @override
  ConsumerState<_SemesterEditor> createState() => _SemesterEditorState();
}

class _SemesterEditorState extends ConsumerState<_SemesterEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _year;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final value = widget.semester;
    final now = DateTime.now();
    _name = TextEditingController(text: value?.name ?? '');
    _number = TextEditingController(
      text: value?.semesterNumber.toString() ?? '',
    );
    _year = TextEditingController(text: value?.academicYear ?? '');
    _start = value?.startDate ?? DateTime(now.year, now.month, now.day);
    _end = value?.endDate ?? _start.add(const Duration(days: 120));
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(semesterControllerProvider).isLoading;
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
                widget.semester == null ? 'Add semester' : 'Edit semester',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const Key('semester_name_field'),
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Semester name',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _number,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Number'),
                      validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                          ? null
                          : 'Enter a valid number',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _year,
                      decoration: const InputDecoration(
                        labelText: 'Academic year',
                      ),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Starts',
                      value: _start,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DateTile(
                      label: 'Ends',
                      value: _end,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                key: const Key('save_semester_button'),
                onPressed: busy ? null : _save,
                child: Text(
                  widget.semester == null ? 'Add semester' : 'Save changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _pickDate(bool start) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be on or after start date.'),
        ),
      );
      return;
    }
    final old = widget.semester;
    final controller = ref.read(semesterControllerProvider.notifier);
    final saved = old == null
        ? await controller.create((
            name: _name.text.trim(),
            semesterNumber: int.parse(_number.text),
            academicYear: _year.text.trim(),
            startDate: _start,
            endDate: _end,
            isActive: false,
          ))
        : await controller.updateSemester((
            id: old.id,
            name: _name.text.trim(),
            semesterNumber: int.parse(_number.text),
            academicYear: _year.text.trim(),
            startDate: _start,
            endDate: _end,
            isActive: old.isActive,
            createdAt: old.createdAt,
            updatedAt: old.updatedAt,
          ));
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save semester.')));
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(DateFormat.yMMMd().format(value)),
    ),
  );
}
