import 'dart:io';
import 'dart:typed_data';

import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class UploadFileSheet extends ConsumerStatefulWidget {
  const UploadFileSheet({
    required this.subjectId,
    required this.semesterId,
    this.subjectName,
    this.initialFileName,
    this.initialBytes,
    super.key,
  });

  final int subjectId;
  final int semesterId;
  final String? subjectName;
  final String? initialFileName;
  final Uint8List? initialBytes;

  static Future<bool?> pickAndShow(
    BuildContext context, {
    required int subjectId,
    required int semesterId,
    String? subjectName,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'ppt',
        'pptx',
        'doc',
        'docx',
        'txt',
        'png',
        'jpg',
        'jpeg',
        'xlsx',
        'csv',
      ],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final bytes =
        picked.bytes ??
        (picked.path != null ? await File(picked.path!).readAsBytes() : null);

    if (bytes == null || !context.mounted) return null;

    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => UploadFileSheet(
        subjectId: subjectId,
        semesterId: semesterId,
        subjectName: subjectName,
        initialFileName: picked.name,
        initialBytes: bytes,
      ),
    );
  }

  @override
  ConsumerState<UploadFileSheet> createState() => _UploadFileSheetState();
}

class _UploadFileSheetState extends ConsumerState<UploadFileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  String? _fileName;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
    _bytes = widget.initialBytes;
    final defaultTitle = _fileName != null ? p.basenameWithoutExtension(_fileName!) : '';
    _titleController = TextEditingController(text: defaultTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final command = ref.watch(subjectFileCommandProvider);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload File',
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
                  const SizedBox(height: AppSpacing.lg),
                  if (_fileName != null && _bytes != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildFileIcon(p.extension(_fileName!).replaceFirst('.', '').toLowerCase()),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  _formatFileSize(_bytes!.length),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Choose different file',
                            onPressed: command.isLoading ? null : _pickFile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title / Label',
                        hintText: 'e.g., Chapter 1 Slides, Syllabus',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !command.isLoading,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a title for the file';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: command.isLoading ? null : _pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxl,
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: colors.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tap to select a document',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'PDF, PPT, PPTX, DOC, DOCX, Images, etc.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: command.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save to Subject'),
                    onPressed: command.isLoading || _bytes == null ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'ppt',
        'pptx',
        'doc',
        'docx',
        'txt',
        'png',
        'jpg',
        'jpeg',
        'xlsx',
        'csv',
      ],
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;
      final bytes =
          picked.bytes ??
          (picked.path != null ? await File(picked.path!).readAsBytes() : null);

      if (bytes != null && mounted) {
        setState(() {
          _fileName = picked.name;
          _bytes = bytes;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = p.basenameWithoutExtension(picked.name);
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _bytes == null || _fileName == null) {
      return;
    }

    final id = await ref
        .read(subjectFileCommandProvider.notifier)
        .uploadFile(
          subjectId: widget.subjectId,
          semesterId: widget.semesterId,
          title: _titleController.text.trim(),
          fileName: _fileName!,
          bytes: _bytes!,
        );

    if (mounted && id != null) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildFileIcon(String ext) {
    final (IconData icon, Color color) = switch (ext) {
      'pdf' => (Icons.picture_as_pdf_rounded, Colors.red.shade600),
      'ppt' || 'pptx' => (Icons.slideshow_rounded, Colors.orange.shade700),
      'doc' || 'docx' || 'txt' => (Icons.description_rounded, Colors.blue.shade600),
      'png' || 'jpg' || 'jpeg' => (Icons.image_rounded, Colors.purple.shade600),
      _ => (Icons.insert_drive_file_rounded, Colors.grey.shade600),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
