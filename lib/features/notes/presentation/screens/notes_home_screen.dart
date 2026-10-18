import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notes/application/notes_providers.dart';
import 'package:college_os/features/notes/application/pdf_search_providers.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/entrance.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:college_os/shared/widgets/icon_pop.dart';
import 'package:college_os/shared/widgets/loading_state.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
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
/// The tab is a library rather than a settings page: a header card carries the
/// search field and the numbers behind it, and every subject is one card whose
/// own name, colour, counts and files answer the question without a second tap
/// to find out what is inside. Every subject still starts collapsed, so the tab
/// stays a short list of subjects no matter how many PDFs have been collected.
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
    final subjectIds = {for (final subject in loadedSubjects) subject.id};
    // One stream of the student's files, narrowed to the subjects this tab
    // lists. Browsing is per subject, so the header totals have to be measured
    // against the same material the cards below it show.
    final library =
        (ref.watch(searchableFilesProvider(null)).value ??
                const <SubjectFile>[])
            .where((file) => subjectIds.contains(file.subjectId))
            .toList(growable: false);
    final pages = <int, int?>{};
    for (final row in ref.watch(pdfSearchMetadataProvider).value ?? const []) {
      pages[row.fileId] = row.pageCount;
    }
    final indexedPages = library.fold<int>(
      0,
      (sum, file) => sum + (pages[file.id] ?? 0),
    );
    final libraryBytes = library.fold<int>(
      0,
      (sum, file) => sum + file.fileSizeBytes,
    );
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
          Entrance(
            index: 0,
            child: _LibraryCard(
              onSearch: () => context.go(RoutePaths.notesSearch),
              loading: semester.isLoading || subjects.isLoading,
              subjects: loadedSubjects.length,
              files: library.length,
              indexedPages: indexedPages,
              bytes: libraryBytes,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Entrance(
            index: 1,
            child: Row(
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
                          label: Text(
                            _materialFilterLabel(
                              filter,
                              _countMatching(filter, library),
                            ),
                          ),
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ),
                if (loadedSubjects.isNotEmpty)
                  PressScale(
                    pressedScale: .9,
                    child: IconButton(
                      key: const Key('notes_expand_all'),
                      tooltip: allExpanded
                          ? 'Collapse all subjects'
                          : 'Expand all subjects',
                      onPressed: () => _toggleAll(loadedSubjects),
                      // The icon flips with a small pop instead of hard-cutting
                      // between the two chevron glyphs.
                      icon: AnimatedSwitcher(
                        duration: AppMotion.reduceMotion(context)
                            ? Duration.zero
                            : AppDurations.fast,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: Icon(
                          allExpanded
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          key: ValueKey(allExpanded),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
            for (final (index, subject) in loadedSubjects.indexed)
              Entrance(
                index: 2 + index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SubjectSection(
                    subject: subject,
                    filter: _filter,
                    expanded: _expandedSubjects.contains(subject.id),
                    onToggle: () => _toggleSubject(subject.id),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// The tab's header: the search field it stands in for, and the size of the
/// library behind it.
///
/// The counts are the material actually listed below — subjects, files, the
/// pages PDF search has indexed, and the space those files take on the device.
/// Nothing here is estimated, and a number that is still unknown simply does not
/// appear yet.
class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.onSearch,
    required this.loading,
    required this.subjects,
    required this.files,
    required this.indexedPages,
    required this.bytes,
  });

  final VoidCallback onSearch;
  final bool loading;
  final int subjects;
  final int files;
  final int indexedPages;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stats = <({String value, String label})>[
      (value: '$subjects', label: subjects == 1 ? 'subject' : 'subjects'),
      (value: '$files', label: files == 1 ? 'file' : 'files'),
      if (indexedPages > 0)
        (
          value: '$indexedPages',
          label: indexedPages == 1 ? 'page indexed' : 'pages indexed',
        ),
      if (bytes > 0) (value: _formatBytes(bytes), label: 'on this device'),
    ];
    return PremiumSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('notes_search_entry'),
            onTap: onSearch,
            child: Container(
              // A step above the card it sits in, so the field reads as the
              // input it stands in for rather than as another row of the list.
              color: colors.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Search notes and PDFs…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
          ),
          if (!loading) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Wrap(
                key: const Key('notes_library_stats'),
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final stat in stats)
                    _LibraryStat(value: stat.value, label: stat.label),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One figure in the library card, written as a sentence: "12 files".
class _LibraryStat extends StatelessWidget {
  const _LibraryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// One subject's material, as a card that opens its own files inline.
///
/// The heading is the toggle, so the whole row is one large target; the trailing
/// action still opens the subject's own screen with its notes, files and
/// per-subject PDF search. The monogram is painted in the subject's own display
/// colour — the one place this tab borrows a colour, and the same convention the
/// Subjects screen already uses — so a semester reads as a set of subjects
/// rather than a list of identical rows.
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
    final notes = ref.watch(subjectNotesProvider(subject.id));
    final pages = <int, int?>{};
    for (final row in ref.watch(pdfSearchMetadataProvider).value ?? const []) {
      pages[row.fileId] = row.pageCount;
    }
    final fileCount = files.value?.length;
    final noteCount = notes.value?.length;
    final details = [
      if (subject.shortCode.isNotEmpty) subject.shortCode,
      if (subject.room.isNotEmpty) 'Room ${subject.room}',
      if (noteCount != null && noteCount > 0)
        '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
      if (fileCount != null) '$fileCount ${fileCount == 1 ? 'file' : 'files'}',
      if (subject.isArchived) 'Archived',
    ];
    final visible = (files.value ?? const <SubjectFile>[])
        .where((file) => _matchesFilter(filter, file))
        .toList(growable: false);

    return PremiumSurface(
      key: ValueKey('notes_subject_card_${subject.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('notes_subject_${subject.id}'),
            onTap: onToggle,
            child: Semantics(
              button: true,
              expanded: expanded,
              label:
                  '${subject.name} material, '
                  '${expanded ? 'expanded' : 'collapsed'}',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.xxs,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _SubjectMonogram(subject: subject),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (details.isNotEmpty)
                            Text(
                              details.join('  ·  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
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
                    PressScale(
                      pressedScale: .9,
                      child: IconButton(
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : AppDurations.fast,
            curve: AppCurves.standard,
            alignment: Alignment.topCenter,
            child: expanded
                ? _SubjectMaterial(
                    subject: subject,
                    filter: filter,
                    files: files,
                    visible: visible,
                    pages: pages,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The subject's monogram, tinted with the colour the student chose for it.
///
/// It grows in with a small pop as the card arrives, the way a dock icon
/// settles — the one glyph that identifies the subject should land, not fade.
class _SubjectMonogram extends StatelessWidget {
  const _SubjectMonogram({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final accent = Color(subject.displayColor);
    return IconPop(
      popOnMount: true,
      fromScale: .8,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          _monogram(subject),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// The file list of one expanded subject.
///
/// It opens inside the subject's own card — a divider and rows, not a second
/// surface — so an expanded subject still reads as one record.
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
    if (files.isLoading) {
      return const _MaterialNotice(text: 'Loading files…');
    }
    if (files.hasError) {
      return const _MaterialNotice(text: 'Could not load files.');
    }
    if (visible.isEmpty) {
      return _MaterialNotice(
        text: files.value!.isEmpty
            ? 'No files yet. Open the subject to upload slides or a PDF.'
            : 'No ${_materialFilterName(filter).toLowerCase()} here yet.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        for (var index = 0; index < visible.length; index++) ...[
          _MaterialRow(
            file: visible[index],
            subject: subject,
            pages: pages[visible[index].id],
          ),
          if (index != visible.length - 1)
            const Divider(
              height: 1,
              indent: _materialRowTextInset,
              endIndent: AppSpacing.md,
            ),
        ],
      ],
    );
  }
}

/// Left inset that lines a row's divider up with its title rather than its icon.
const _materialRowTextInset = AppSpacing.md + 36 + AppSpacing.sm;

/// A quiet line inside a subject card: loading, failure, or nothing to show.
class _MaterialNotice extends StatelessWidget {
  const _MaterialNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One stored file: its type as an icon tile, its title, and when-and-how-big
/// it is.
///
/// A PDF — the one kind of file this library can search inside — keeps the
/// cobalt tile; every other format uses a neutral one, and the glyph tells the
/// kinds apart without inventing a second accent.
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
    final isPdf = file.fileExtension.toLowerCase() == 'pdf';
    final tint = isPdf ? colors.primary : colors.onSurfaceVariant;
    return InkWell(
      key: ValueKey('notes_file_${file.id}'),
      // Opening a file keeps the behaviour the subject screen already had:
      // PDFs open in the viewer, everything else opens or shares through the
      // platform.
      onTap: () {
        if (isPdf) {
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
                color: tint.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(_fileIcon(file.fileExtension), size: 18, color: tint),
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

String _monogram(Subject subject) {
  final code = subject.shortCode.trim();
  if (code.isNotEmpty) {
    return code.substring(0, code.length.clamp(1, 2)).toUpperCase();
  }
  final words = subject.name.trim().split(RegExp(r'\s+'));
  return words.take(2).map((word) => word[0]).join().toUpperCase();
}

String _materialFilterName(_MaterialFilter filter) => switch (filter) {
  _MaterialFilter.all => 'All',
  _MaterialFilter.pdfs => 'PDFs',
  _MaterialFilter.text => 'Text',
  _MaterialFilter.others => 'Others',
};

String _materialFilterLabel(_MaterialFilter filter, int count) =>
    '${_materialFilterName(filter)} $count';

int _countMatching(_MaterialFilter filter, List<SubjectFile> files) =>
    files.where((file) => _matchesFilter(filter, file)).length;

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
