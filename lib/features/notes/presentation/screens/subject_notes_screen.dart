import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notes/application/notes_providers.dart';
import 'package:college_os/features/notes/domain/subject_note_repository.dart';
import 'package:college_os/features/notes/presentation/widgets/note_editor_sheet.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/presentation/widgets/upload_file_sheet.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _SubjectMaterialTab { notes, files }

class SubjectNotesScreen extends ConsumerStatefulWidget {
  const SubjectNotesScreen({required this.subjectId, super.key});

  final int subjectId;

  @override
  ConsumerState<SubjectNotesScreen> createState() => _SubjectNotesScreenState();
}

class _SubjectNotesScreenState extends ConsumerState<SubjectNotesScreen> {
  _SubjectMaterialTab _currentTab = _SubjectMaterialTab.notes;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
    final notesAsync = ref.watch(subjectNotesProvider(widget.subjectId));
    final filesAsync = ref.watch(subjectFilesProvider(widget.subjectId));
    final colors = Theme.of(context).colorScheme;

    return subjectsAsync.when(
      loading: () => const AppScaffold(
        title: 'Subject Materials',
        subtitle: 'Loading…',
        child: LoadingState(label: 'Loading subject materials...'),
      ),
      error: (error, _) => AppScaffold(
        title: 'Subject Materials',
        subtitle: 'Error loading subject',
        child: ErrorState(
          title: 'Could not load subject',
          message: error.toString(),
        ),
      ),
      data: (subjects) {
        final subject = subjects
            .where((s) => s.id == widget.subjectId)
            .firstOrNull;

        if (subject == null) {
          return const AppScaffold(
            title: 'Subject Materials',
            subtitle: 'Subject not found',
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Subject not found',
              message: 'This subject may have been removed.',
            ),
          );
        }

        final accent = Color(subject.displayColor);
        final notesCount = notesAsync.value?.length ?? 0;
        final filesCount = filesAsync.value?.length ?? 0;

        return AppScaffold(
          title: '${subject.name} Notes & Files',
          subtitle: [
            if (subject.shortCode.isNotEmpty) subject.shortCode,
            if (subject.room.isNotEmpty) 'Room ${subject.room}',
            '$notesCount notes',
            '$filesCount files',
          ].join(' • '),
          actions: [
            if (_currentTab == _SubjectMaterialTab.notes)
              IconButton.filledTonal(
                tooltip: 'Add Note',
                icon: const Icon(Icons.edit_note_rounded),
                onPressed: () => NoteEditorSheet.show(
                  context,
                  subjectId: subject.id,
                  semesterId: subject.semesterId,
                  subjectName: subject.name,
                ),
              )
            else
              IconButton.filledTonal(
                tooltip: 'Upload File',
                icon: const Icon(Icons.upload_file_rounded),
                onPressed: () => UploadFileSheet.pickAndShow(
                  context,
                  subjectId: subject.id,
                  semesterId: subject.semesterId,
                  subjectName: subject.name,
                ),
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: SegmentedButton<_SubjectMaterialTab>(
                  segments: [
                    ButtonSegment(
                      value: _SubjectMaterialTab.notes,
                      icon: const Icon(Icons.notes_rounded, size: 18),
                      label: Text('Notes ($notesCount)'),
                    ),
                    ButtonSegment(
                      value: _SubjectMaterialTab.files,
                      icon: const Icon(Icons.folder_outlined, size: 18),
                      label: Text('Files ($filesCount)'),
                    ),
                  ],
                  selected: {_currentTab},
                  onSelectionChanged: (selected) {
                    setState(() => _currentTab = selected.first);
                  },
                ),
              ),
              if (_currentTab == _SubjectMaterialTab.notes)
                _buildNotesSection(context, notesAsync, subject, accent, colors)
              else
                _buildFilesSection(context, filesAsync, subject, accent, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    AsyncValue<List<SubjectNote>> notesAsync,
    Subject subject,
    Color accent,
    ColorScheme colors,
  ) {
    return notesAsync.when(
      loading: () => const LoadingState(label: 'Loading notes...'),
      error: (error, _) => ErrorState(
        title: 'Could not load notes',
        message: error.toString(),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return EmptyState(
            icon: Icons.note_alt_outlined,
            title: 'No notes yet',
            message:
                'Take notes, record important points, or save reminders for ${subject.name}.',
            action: FilledButton.icon(
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Add Note'),
              onPressed: () => NoteEditorSheet.show(
                context,
                subjectId: subject.id,
                semesterId: subject.semesterId,
                subjectName: subject.name,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _NoteCard(
                  note: note,
                  subject: subject,
                  accent: accent,
                  onTap: () => NoteEditorSheet.show(
                    context,
                    subjectId: subject.id,
                    semesterId: subject.semesterId,
                    subjectName: subject.name,
                    note: note,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilesSection(
    BuildContext context,
    AsyncValue<List<SubjectFile>> filesAsync,
    Subject subject,
    Color accent,
    ColorScheme colors,
  ) {
    return filesAsync.when(
      loading: () => const LoadingState(label: 'Loading files...'),
      error: (error, _) => ErrorState(
        title: 'Could not load files',
        message: error.toString(),
      ),
      data: (files) {
        if (files.isEmpty) {
          return EmptyState(
            icon: Icons.cloud_upload_outlined,
            title: 'No files uploaded yet',
            message:
                'Attach lecture slides (PPT/PPTX), PDFs, assignment sheets, or notes for ${subject.name}.',
            action: FilledButton.icon(
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload File'),
              onPressed: () => UploadFileSheet.pickAndShow(
                context,
                subjectId: subject.id,
                semesterId: subject.semesterId,
                subjectName: subject.name,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final file in files)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _FileCard(
                  file: file,
                  subject: subject,
                  accent: accent,
                  onOpen: () => ref
                      .read(subjectFileCommandProvider.notifier)
                      .openOrShareFile(file),
                  onDelete: () => _confirmDeleteFile(context, file),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteFile(BuildContext context, SubjectFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text(
          'Are you sure you want to remove "${file.title}"? This file will be deleted from your device.',
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

    if (confirmed == true) {
      await ref.read(subjectFileCommandProvider.notifier).deleteFile(file.id);
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.subject,
    required this.accent,
    required this.onTap,
  });

  final SubjectNote note;
  final Subject subject;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final createdLocal = note.createdAt.toLocal();
    final dateStr = DateFormat('EEE, d MMM yyyy • h:mm a').format(createdLocal);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.title.isNotEmpty) ...[
                          Text(
                            note.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                note.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.subject,
    required this.accent,
    required this.onOpen,
    required this.onDelete,
  });

  final SubjectFile file;
  final Subject subject;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final createdLocal = file.createdAt.toLocal();
    final dateStr = DateFormat('d MMM yyyy • h:mm a').format(createdLocal);

    final (IconData icon, Color iconColor) = switch (file.fileExtension.toLowerCase()) {
      'pdf' => (Icons.picture_as_pdf_rounded, Colors.red.shade600),
      'ppt' || 'pptx' => (Icons.slideshow_rounded, Colors.orange.shade700),
      'doc' || 'docx' || 'txt' => (Icons.description_rounded, Colors.blue.shade600),
      'png' || 'jpg' || 'jpeg' => (Icons.image_rounded, Colors.purple.shade600),
      _ => (Icons.insert_drive_file_rounded, Colors.grey.shade600),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${_formatFileSize(file.fileSizeBytes)} • $dateStr',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (file.title != file.fileName) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        file.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'File actions',
                onSelected: (val) {
                  if (val == 'open') onOpen();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.open_in_new_rounded),
                      title: Text('Open / Share'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
