import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notes/application/notes_providers.dart';
import 'package:college_os/features/notes/domain/subject_note_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoteEditorSheet extends ConsumerStatefulWidget {
  const NoteEditorSheet({
    required this.subjectId,
    required this.semesterId,
    this.subjectName,
    this.note,
    super.key,
  });

  final int subjectId;
  final int semesterId;
  final String? subjectName;
  final SubjectNote? note;

  static Future<bool?> show(
    BuildContext context, {
    required int subjectId,
    required int semesterId,
    String? subjectName,
    SubjectNote? note,
  }) => showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    builder: (context) => NoteEditorSheet(
      subjectId: subjectId,
      semesterId: semesterId,
      subjectName: subjectName,
      note: note,
    ),
  );

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _submitted = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final command = ref.watch(noteCommandProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
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
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'Edit Note' : 'Add Note',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (widget.subjectName != null &&
                                widget.subjectName!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                widget.subjectName!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          tooltip: 'Delete Note',
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          onPressed: command.isLoading ? null : _delete,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                      hintText: 'e.g., Chapter 3 Summary, Assignment tips',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !command.isLoading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Write down key points, formulas, reminders...',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 5,
                    maxLines: 12,
                    enabled: !command.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter some notes';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: command.isLoading ? null : _save,
                    child: command.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Save Note'),
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
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (_isEditing) {
      final updated = (
        id: widget.note!.id,
        subjectId: widget.note!.subjectId,
        semesterId: widget.note!.semesterId,
        title: title,
        body: body,
        createdAt: widget.note!.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      final ok = await ref
          .read(noteCommandProvider.notifier)
          .updateNote(updated);
      if (mounted && ok) {
        Navigator.of(context).pop(true);
      }
    } else {
      final newNote = (
        subjectId: widget.subjectId,
        semesterId: widget.semesterId,
        title: title,
        body: body,
      );
      final id = await ref.read(noteCommandProvider.notifier).create(newNote);
      if (mounted && id != null) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This note will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ref
          .read(noteCommandProvider.notifier)
          .deleteNote(widget.note!.id);
      if (mounted && ok) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
