import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_color_palette.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/subjects/domain/subject_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubjectFormSheet extends ConsumerStatefulWidget {
  const SubjectFormSheet({
    required this.semesterId,
    required this.defaultAttendanceTarget,
    this.subject,
    super.key,
  });

  final int semesterId;
  final double defaultAttendanceTarget;
  final Subject? subject;

  @override
  ConsumerState<SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _professorController = TextEditingController();
  final _roomController = TextEditingController();
  final _targetController = TextEditingController();
  late int _displayColor;
  bool _submitted = false;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;
    _nameController.text = subject?.name ?? '';
    _codeController.text = subject?.shortCode ?? '';
    _professorController.text = subject?.professor ?? '';
    _roomController.text = subject?.room ?? '';
    final target =
        (subject?.attendanceTarget ?? widget.defaultAttendanceTarget) * 100;
    _targetController.text = target == target.roundToDouble()
        ? target.toInt().toString()
        : target.toStringAsFixed(1);
    _displayColor = subject?.displayColor ?? SubjectColorPalette.defaultValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _professorController.dispose();
    _roomController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(subjectCommandProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _isEditing ? 'Edit Subject' : 'Add Subject',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isEditing
                        ? 'Update how this subject appears across CollegeOS.'
                        : 'Add a subject to your active semester.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: const Key('subject_name_field'),
                    controller: _nameController,
                    autofocus: !_isEditing,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    validator: SubjectValidator.name,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('subject_code_field'),
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Short Code',
                            hintText: 'e.g. CS201',
                            prefixIcon: Icon(Icons.tag_rounded),
                          ),
                          validator: (value) => SubjectValidator.optionalText(
                            value,
                            fieldName: 'Short code',
                            maxLength: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          key: const Key('subject_room_field'),
                          controller: _roomController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Room',
                            hintText: 'e.g. B-204',
                            prefixIcon: Icon(Icons.meeting_room_outlined),
                          ),
                          validator: (value) => SubjectValidator.optionalText(
                            value,
                            fieldName: 'Room',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('subject_professor_field'),
                    controller: _professorController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Professor',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => SubjectValidator.optionalText(
                      value,
                      fieldName: 'Professor',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('subject_target_field'),
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Attendance Target',
                      prefixIcon: Icon(Icons.track_changes_rounded),
                      suffixText: '%',
                    ),
                    validator: SubjectValidator.attendanceTarget,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Display color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final color in SubjectColorPalette.values)
                        _ColorChoice(
                          color: color,
                          selected: _displayColor == color.toARGB32(),
                          onTap: () =>
                              setState(() => _displayColor = color.toARGB32()),
                        ),
                    ],
                  ),
                  if (command.hasError) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'The subject could not be saved. Your existing data is unchanged.',
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    key: const Key('save_subject_button'),
                    onPressed: command.isLoading ? null : _save,
                    icon: command.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      command.isLoading
                          ? 'Saving…'
                          : _isEditing
                          ? 'Save Changes'
                          : 'Add Subject',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final target = double.parse(_targetController.text) / 100;
    final current = widget.subject;
    final notifier = ref.read(subjectCommandProvider.notifier);
    final saved = current == null
        ? await notifier.create((
            semesterId: widget.semesterId,
            name: _nameController.text,
            shortCode: _codeController.text,
            professor: _professorController.text,
            room: _roomController.text,
            attendanceTarget: target,
            displayColor: _displayColor,
          ))
        : await notifier.updateSubject((
            id: current.id,
            semesterId: current.semesterId,
            name: _nameController.text,
            shortCode: _codeController.text,
            professor: _professorController.text,
            room: _roomController.text,
            attendanceTarget: target,
            displayColor: _displayColor,
            isArchived: current.isArchived,
            createdAt: current.createdAt,
            updatedAt: current.updatedAt,
          ));
    if (saved && mounted) Navigator.of(context).pop();
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Subject color',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
