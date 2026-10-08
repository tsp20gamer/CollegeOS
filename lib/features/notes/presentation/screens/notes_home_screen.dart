import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notes/application/pdf_search_providers.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Which kinds of material the list is showing.
///
/// Derived from the stored file extension, so it needs no new state and no
/// schema change: the filter is a view over what the student already has.
enum _MaterialFilter { all, pdfs, text, others }

/// Extensions the "Text" filter covers.
const _textExtensions = {'txt', 'md', 'rtf', 'doc', 'docx', 'odt', 'csv'};

/// The Notes destination: everything the student has collected for a subject,
/// with search one tap away.
///
/// Browsing stays subject-based so the tab answers "what do I have for this
/// subject", while [RoutePaths.notesSearch] answers "where is this topic". The
/// two entry points deliberately stay separate rather than duplicating each
/// other in one screen.
class NotesHomeScreen extends ConsumerStatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  ConsumerState<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends ConsumerState<NotesHomeScreen> {
  _MaterialFilter _filter = _MaterialFilter.all;

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final subjects = ref.watch(activeSemesterSubjectsProvider);
    final activeSemesterName = semester.value?.name;

    return AppScaffold(
      title: 'Notes',
      subtitle: activeSemesterName == null
          ? 'Your notes and PDFs, kept on this device.'
          : '$activeSemesterName · notes, files and search',
      showSettingsAction: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SearchEntry(onTap: () => context.go(RoutePaths.notesSearch)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            key: const Key('notes_material_filter'),
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final filter in _MaterialFilter.values)
                FilterChip(
                  key: Key('notes_filter_${filter.name}'),
                  selected: _filter == filter,
                  showCheckmark: false,
                  label: Text(_materialFilterLabel(filter)),
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (semester.isLoading || subjects.isLoading)
            const LoadingState(label: 'Loading your material')
          else if (semester.hasError || subjects.hasError)
            ErrorState(
              title: 'Could not load your notes',
              message: 'Your local notes and files are unchanged. Try again.',
              onRetry: () {
                ref.invalidate(activeSemesterProvider);
                ref.invalidate(activeSemesterSubjectsProvider);
              },
            )
          else if (semester.value == null)
            const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No active semester',
              message:
                  'Make a semester active to collect notes and files here.',
            )
          else if ((subjects.value ?? const <Subject>[]).isEmpty)
            const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              message:
                  'Add a subject from Settings to start keeping notes and PDFs.',
            )
          else
            for (final subject in subjects.value!)
              _SubjectSection(subject: subject, filter: _filter),
        ],
      ),
    );
  }
}

/// The search entry point, dressed as the field it stands in for.
class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PremiumSurface(
      key: const Key('notes_search_entry'),
      onTap: onTap,
      semanticLabel: 'Search all notes',
      color: colors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Search notes…',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One subject's material, as a heading with its files listed beneath it.
///
/// The heading keeps the subject reachable — and keeps the list meaningful when
/// a subject has no files yet — while the rows below stay flat.
class _SubjectSection extends ConsumerWidget {
  const _SubjectSection({required this.subject, required this.filter});

  final Subject subject;
  final _MaterialFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final files = ref.watch(subjectFilesProvider(subject.id));
    final pages = {
      for (final row in ref.watch(pdfSearchMetadataProvider).value ?? const [])
        row.fileId: row.pageCount,
    };
    final details = [
      if (subject.shortCode.isNotEmpty) subject.shortCode,
      if (subject.room.isNotEmpty) 'Room ${subject.room}',
      if (files.hasValue) '${files.value!.length} files',
      if (subject.isArchived) 'Archived',
    ];
    final visible = (files.value ?? const <SubjectFile>[])
        .where((file) => _matchesFilter(filter, file))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('notes_subject_${subject.id}'),
            onTap: () => context.push(
              RoutePaths.subjectNotes.replaceFirst(
                ':subjectId',
                '${subject.id}',
              ),
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (details.isNotEmpty)
                          Text(
                            details.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppIconSize.sm,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (files.isLoading)
            _MutedLine(text: 'Loading files…', theme: theme)
          else if (files.hasError)
            _MutedLine(text: 'Could not load files.', theme: theme)
          else if (visible.isEmpty)
            _MutedLine(
              text: files.value!.isEmpty
                  ? 'No files yet. Upload slides or a PDF to keep them here.'
                  : 'No ${_materialFilterLabel(filter).toLowerCase()} here yet.',
              theme: theme,
            )
          else
            PremiumSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < visible.length; index++) ...[
                    _MaterialRow(
                      file: visible[index],
                      subject: subject,
                      pages: pages[visible[index].id],
                    ),
                    if (index != visible.length - 1)
                      const Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MutedLine extends StatelessWidget {
  const _MutedLine({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

/// One stored file: an icon tile, its title, and when-and-how-big it is.
class _MaterialRow extends ConsumerWidget {
  const _MaterialRow({
    required this.file,
    required this.subject,
    required this.pages,
  });

  final SubjectFile file;
  final Subject subject;
  final int? pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      key: ValueKey('notes_file_${file.id}'),
      // Opening a file keeps the behaviour the subject screen already had:
      // PDFs open in the viewer, everything else opens or shares through the
      // platform.
      onTap: () {
        if (file.fileExtension.toLowerCase() == 'pdf') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => PdfViewerScreen(file: file),
            ),
          );
        } else {
          ref.read(subjectFileCommandProvider.notifier).openOrShareFile(file);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(
                _fileIcon(file.fileExtension),
                size: 18,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    _fileMeta(file, pages),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIconSize.sm,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

String _materialFilterLabel(_MaterialFilter filter) => switch (filter) {
  _MaterialFilter.all => 'All',
  _MaterialFilter.pdfs => 'PDFs',
  _MaterialFilter.text => 'Text',
  _MaterialFilter.others => 'Others',
};

bool _matchesFilter(_MaterialFilter filter, SubjectFile file) {
  final extension = file.fileExtension.toLowerCase();
  final isText = _textExtensions.contains(extension);
  return switch (filter) {
    _MaterialFilter.all => true,
    _MaterialFilter.pdfs => extension == 'pdf',
    _MaterialFilter.text => isText,
    _MaterialFilter.others => extension != 'pdf' && !isText,
  };
}

IconData _fileIcon(String extension) => switch (extension.toLowerCase()) {
  'pdf' => Icons.picture_as_pdf_rounded,
  final value when _textExtensions.contains(value) => Icons.description_rounded,
  _ => Icons.insert_drive_file_rounded,
};

String _fileMeta(SubjectFile file, int? pages) {
  final date = DateFormat('d MMM yyyy').format(file.createdAt.toLocal());
  final detail = pages != null && pages > 0
      ? '$pages ${pages == 1 ? 'page' : 'pages'}'
      : _formatBytes(file.fileSizeBytes);
  return '$date · $detail';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
