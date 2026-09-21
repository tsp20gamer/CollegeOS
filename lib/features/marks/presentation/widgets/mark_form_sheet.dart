import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/exams/application/exam_mark_providers.dart';
import 'package:college_os/features/marks/domain/marks_repository.dart';
import 'package:college_os/features/marks/domain/marks_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MarkFormSheet extends ConsumerStatefulWidget {
  const MarkFormSheet({required this.subjectId, this.mark, super.key});

  final int subjectId;
  final Mark? mark;

  @override
  ConsumerState<MarkFormSheet> createState() => _MarkFormSheetState();
}

class _MarkFormSheetState extends ConsumerState<MarkFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _obtained;
  late final TextEditingController _maximum;
  late final TextEditingController _note;
  late MarkCategory _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final mark = widget.mark;
    _category = mark == null
        ? MarkCategory.internal
        : MarkCategoryDetails.fromDatabase(mark.category);
    _date = mark?.date ?? DateTime.now();
    _obtained = TextEditingController(text: _number(mark?.obtainedMarks));
    _maximum = TextEditingController(text: _number(mark?.maxMarks));
    _note = TextEditingController(text: mark?.note ?? '');
  }

  @override
  void dispose() {
    _obtained.dispose();
    _maximum.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(markCommandProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.mark == null ? 'Record marks' : 'Edit marks',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<MarkCategory>(
                  key: const Key('mark_category_field'),
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final category in MarkCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: command.isLoading
                      ? null
                      : (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('mark_obtained_field'),
                        controller: _obtained,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalFormatter],
                        decoration: const InputDecoration(
                          labelText: 'Obtained marks',
                        ),
                        validator: _obtainedValidator,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        key: const Key('mark_maximum_field'),
                        controller: _maximum,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalFormatter],
                        decoration: const InputDecoration(
                          labelText: 'Maximum marks',
                        ),
                        validator: _maximumValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  key: const Key('mark_date_field'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: const Icon(Icons.event_rounded),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMMd().format(_date)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDate,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('mark_note_field'),
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  key: const Key('save_mark_button'),
                  onPressed: command.isLoading ? null : _save,
                  icon: command.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    widget.mark == null ? 'Record marks' : 'Save changes',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  String? _obtainedValidator(String? value) {
    final obtained = double.tryParse(value?.trim() ?? '');
    if (obtained == null) return 'Enter obtained marks';
    if (obtained < 0) return 'Cannot be negative';
    final maximum = double.tryParse(_maximum.text.trim());
    if (maximum != null && obtained > maximum) return 'Above maximum';
    return null;
  }

  String? _maximumValidator(String? value) {
    final maximum = double.tryParse(value?.trim() ?? '');
    if (maximum == null || maximum <= 0) return 'Enter a positive maximum';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.mark;
    final draft = (
      subjectId: widget.subjectId,
      examId: existing?.examId,
      category: _category.databaseValue,
      obtainedMarks: double.parse(_obtained.text),
      maxMarks: double.parse(_maximum.text),
      date: _date,
      note: _note.text,
    );
    final controller = ref.read(markCommandProvider.notifier);
    final success = existing == null
        ? await controller.create(draft)
        : await controller.updateMark((
            id: existing.id,
            subjectId: draft.subjectId,
            examId: draft.examId,
            category: draft.category,
            obtainedMarks: draft.obtainedMarks,
            maxMarks: draft.maxMarks,
            date: draft.date,
            note: draft.note,
          ));
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save these marks.')),
      );
    }
  }
}

final _decimalFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d{0,2}'),
);

String _number(double? value) => value == null
    ? ''
    : value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
