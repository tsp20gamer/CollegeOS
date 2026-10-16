import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
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
///
/// Every subject starts collapsed, so the tab stays a short list of subjects no
/// matter how many PDFs have been collected, and only the subjects the student
/// opens show their files.
class NotesHomeScreen extends ConsumerStatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  ConsumerState<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends ConsumerState<NotesHomeScreen> {
  _MaterialFilter _filter = _MaterialFilter.all;

  /// Which subjects are showing their files inline.
  ///
  /// Ephemeral on purpose: which section is open is screen state, not data the
  /// student would expect to find again after a restart.
  final Set<int> _expandedSubjects = <int>{};

  void _toggleSubject(int subjectId) {
    setState(() {
      if (_expandedSubjects.remove(subjectId)) {
        return;
      }
      _expandedSubjects.add(subjectId);
    });
  }

  void _toggleAll(List<Subject> subjects) {
    final ids = subjects.map((subject) => subject.id);
    final allExpanded =
        subjects.isNotEmpty &&
        subjects.every((subject) => _expandedSubjects.contains(subject.id));
    setState(() {
      _expandedSubjects.clear();
      if (!allExpanded) {
        _expandedSubjects.addAll(ids);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final semester = ref.watch(activeSemesterProvider);
    final subjects = ref.watch(activeSemesterSubjectsProvider);
    final activeSemesterName = semester.value?.name;
    final loadedSubjects = subjects.value ?? const <Subject>[];
    final allExpanded =
        loadedSubjects.isNotEmpty &&
        loadedSubjects.every(
          (subject) => _expandedSubjects.contains(subject.id),
        );

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
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
              ),
              if (loadedSubjects.isNotEmpty)
                TextButton.icon(
                  key: const Key('notes_expand_all'),
                  onPressed: () => _toggleAll(loadedSubjects),
                  icon: Icon(
                    allExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    size: 18,
                  ),
                  label: Text(allExpanded ? 'Collapse all' : 'Expand all'),
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
          else if (loadedSubjects.isEmpty)
            const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              message:
                  'Add a subject from Settings to start keeping notes and PDFs.',
            )
          else
            for (final subject in loadedSubjects)
              _SubjectSection(
                subject: subject,
                filter: _filter,
                expanded: _expandedSubjects.contains(subject.id),
                onToggle: () => _toggleSubject(subject.id),
              ),
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

/// One subject's material, as a heading that opens its files inline.
///
/// The heading is the toggle, so the whole row is one large target; the
/// trailing action still opens the subject's own screen with its notes, files
/// and per-subject PDF search.
class _SubjectSection extends ConsumerWidget {
  const _SubjectSection({
    required this.subject,
    required this.filter,
    required this.expanded,
    required this.onToggle,
  });

  final Subject subject;
  final _MaterialFilter filter;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final files = ref.watch(subjectFilesProvider(subject.id));
    final metadata = ref.watch(pdfSearchMetadataProvider).value;
    final pages = <int, int?>{};
    for (final row in metadata ?? const []) {
      pages[row.fileId] = row.pageCount;
    }
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: ValueKey('notes_subject_${subject.id}'),
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Semantics(
                    button: true,
                    expanded: expanded,
                    label:
                        '${subject.name} material, '
                        '${expanded ? 'expanded' : 'collapsed'}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        children: [
                          AnimatedRotation(
                            turns: expanded ? .25 : 0,
                            duration: reduceMotion
                                ? Duration.zero
                                : AppDurations.fast,
                            curve: AppCurves.standard,
                            child: Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: AppIconSize.md,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: ValueKey('notes_open_subject_${subject.id}'),
                tooltip: 'Open ${subject.name} notes and files',
                onPressed: () => context.push(
                  RoutePaths.subjectNotes.replaceFirst(
                    ':subjectId',
                    '${subject.id}',
                  ),
                ),
                icon: const Icon(Icons.folder_open_rounded),
              ),
            ],
          ),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : AppDurations.fast,
            curve: AppCurves.standard,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: _SubjectMaterial(
                      subject: subject,
                      filter: filter,
                      files: files,
                      visible: visible,
                      pages: pages,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The file list of one expanded subject, with its loading and empty states.
class _SubjectMaterial extends StatelessWidget {
  const _SubjectMaterial({
    required this.subject,
    required this.filter,
    required this.files,
    required this.visible,
    required this.pages,
  });

  final Subject subject;
  final _MaterialFilter filter;
  final AsyncValue<List<SubjectFile>> files;
  final List<SubjectFile> visible;
  final Map<int, int?> pages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (files.isLoading) {
      return _MutedLine(text: 'Loading files…', theme: theme);
    }
    if (files.hasError) {
      return _MutedLine(text: 'Could not load files.', theme: theme);
    }
    if (visible.isEmpty) {
      return _MutedLine(
        text: files.value!.isEmpty
            ? 'No files yet. Upload slides or a PDF to keep them here.'
            : 'No ${_materialFilterLabel(filter).toLowerCase()} here yet.',
        theme: theme,
      );
    }
    return PremiumSurface(
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
          PdfViewerScreen.open(context, file: file);
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
