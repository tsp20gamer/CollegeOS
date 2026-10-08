import 'dart:async';

import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';

import 'package:college_os/features/notes/application/ai_search_providers.dart';
import 'package:college_os/features/notes/application/pdf_search_providers.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_note_search_state.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfSearchScreen extends ConsumerStatefulWidget {
  const PdfSearchScreen({this.subjectId, super.key});

  /// Scopes the AI answer and the indexing indicator to one subject's files.
  ///
  /// Null means the whole library: keyword search has always been global, and
  /// the Notes destination and its search shortcut open this screen unscoped.
  final int? subjectId;

  @override
  ConsumerState<PdfSearchScreen> createState() => _PdfSearchScreenState();
}

class _PdfSearchScreenState extends ConsumerState<PdfSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        // The AI answer belongs to the question it was asked for. Once the box
        // no longer holds that question, drop it instead of showing an answer
        // next to unrelated results.
        final aiStatus = ref.read(aiSearchControllerProvider);
        if (aiStatus.hasResult && aiStatus.question != query.trim()) {
          ref.read(aiSearchControllerProvider.notifier).reset();
        }
        setState(() {
          _query = query;
        });
      }
    });
  }

  /// Sends the current query to the AI layer.
  ///
  /// Retrieval and prompting live behind `aiSearchControllerProvider`; this
  /// only decides what the question is and which PDFs may be searched.
  void _askAi() {
    final question = _query.trim();
    if (question.isEmpty) return;

    // Scope the answer to this subject's PDFs, matching what the list below
    // shows. An unloaded file list means "no scope", not "no files", and an
    // unscoped screen searches everything the student has indexed.
    final subjectId = widget.subjectId;
    final files = subjectId == null
        ? null
        : ref.read(subjectFilesProvider(subjectId)).value;
    final allowedFileIds = (files == null || files.isEmpty)
        ? null
        : files.map((f) => f.id).toList();

    ref
        .read(aiSearchControllerProvider.notifier)
        .ask(question, allowedFileIds: allowedFileIds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Indexing is reconciled per subject. An unscoped search has no file list
    // of its own, and every subject is already covered by its own screen.
    final subjectId = widget.subjectId;
    if (subjectId != null) {
      ref.listen(subjectFilesProvider(subjectId), (previous, next) {
        final files = next.value;
        if (files != null && files.isNotEmpty) {
          ref.read(pdfIndexCommandProvider.notifier).indexMissingPdfs(files);
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search PDFs',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Find keywords inside your documents',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search for a topic, keyword...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildIndexingStatus(colors),
            const SizedBox(height: AppSpacing.md),
            _buildAiSection(colors),
            const SizedBox(height: AppSpacing.md),
            // Results area — Expanded so it fills the remaining screen
            Expanded(
              child: _query.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_rounded,
                      title: 'Search inside documents',
                      message:
                          'Type above to search across all extracted PDF text.',
                    )
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexingStatus(ColorScheme colors) {
    final metadataAsync = ref.watch(pdfSearchMetadataProvider);
    final filesAsync = ref.watch(searchableFilesProvider(widget.subjectId));
    if (metadataAsync.isLoading ||
        filesAsync.isLoading ||
        metadataAsync.hasError ||
        filesAsync.hasError) {
      return const SizedBox.shrink();
    }
    final metadata = metadataAsync.value ?? [];
    final files = filesAsync.value ?? [];
    final indexingFiles = <String>[];
    for (final file in files) {
      final meta = metadata.where((m) => m.fileId == file.id).firstOrNull;
      if (meta != null && meta.status.startsWith('indexing')) {
        String statusText = 'Indexing PDF...';
        if (meta.status.contains('(')) {
          statusText = 'Indexing PDF... ${meta.status.split(' ').last} pages';
        }
        indexingFiles.add('${file.title}: $statusText');
      }
    }
    if (indexingFiles.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              indexingFiles.join('\n'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  /// The AI layer, added on top of local search without replacing it.
  ///
  /// The button is always available; pressing it with no configured key or no
  /// network produces an explanatory card while the keyword results below keep
  /// working exactly as before.
  Widget _buildAiSection(ColorScheme colors) {
    final status = ref.watch(aiSearchControllerProvider);
    final theme = Theme.of(context);
    final canAsk = _query.trim().isNotEmpty && !status.isBusy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Local search finds pages. AI explains them.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: canAsk ? _askAi : null,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Ask AI'),
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ],
          ),
          if (status.isBusy) _buildAiProgress(colors, status),
          if (!status.isBusy && status.hasResult)
            _buildAiAnswer(colors, status),
        ],
      ),
    );
  }

  /// Renders retrieval/generation progress above the local results.
  Widget _buildAiProgress(ColorScheme colors, AiNoteSearchStatus status) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                status.progressLabel ?? 'Working…',
                key: ValueKey(status.phase),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnswer(ColorScheme colors, AiNoteSearchStatus status) {
    final theme = Theme.of(context);
    final result = status.result!;
    final files =
        ref.watch(searchableFilesProvider(widget.subjectId)).value ?? [];
    final fileMap = {for (final f in files) f.id: f};

    if (status.phase != AiNoteSearchPhase.success) {
      // Offline, API error or "not in your notes" — all explanatory, none of
      // them a substitute for the local results still shown below.
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  status.phase == AiNoteSearchPhase.offline
                      ? Icons.wifi_off_rounded
                      : status.phase == AiNoteSearchPhase.noContext
                      ? Icons.search_off_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    status.message ?? result.answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (status.phase != AiNoteSearchPhase.noContext) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _askAi,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'AI answer',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (status.sourcePageCount > 0)
                Text(
                  '${status.sourcePageCount} pages searched',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Bounded so a long answer cannot push the local results off screen.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: result.answer,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
          ),
          if (result.hasSources) ...[
            const SizedBox(height: AppSpacing.sm),
            ...result.sources.map(
              (source) => _AiSourceRow(
                source: source,
                file: fileMap[source.fileId],
                query: status.question ?? _query,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(pdfSearchProvider(_query));
    final filesAsync = ref.watch(searchableFilesProvider(widget.subjectId));

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (results) {
        if (results.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results found',
            message:
                'Try a different keyword or check if the PDF has been indexed.',
          );
        }

        final files = filesAsync.value ?? [];
        final Map<int, SubjectFile> fileMap = {for (final f in files) f.id: f};

        // Filter results to only show files that belong to this subject
        final subjectResults = results
            .where((r) => fileMap.containsKey(r.fileId))
            .toList();

        if (subjectResults.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results in this subject',
            message: 'Matches were found in other subjects, but not here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: subjectResults.length,
          itemBuilder: (context, index) {
            final result = subjectResults[index];
            final file = fileMap[result.fileId]!;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        file: file,
                        initialPageNumber: result.pageNumber,
                        initialSearchQuery: _query,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              file.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Page ${result.pageNumber}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _HtmlText(html: result.snippet),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// One validated citation, rendered under an AI answer.
///
/// Only sources that passed local validation reach this widget, and [file] is
/// looked up locally, so a tap always opens a real page.
class _AiSourceRow extends StatelessWidget {
  const _AiSourceRow({
    required this.source,
    required this.file,
    required this.query,
  });

  final AiSourceReference source;
  final SubjectFile? file;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = source.fileName ?? file?.title ?? 'Document';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: file == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(
                    file: file!,
                    initialPageNumber: source.pageNumber,
                    initialSearchQuery: query,
                  ),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 14,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              'Page ${source.pageNumber}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HtmlText extends StatelessWidget {
  final String html;

  const _HtmlText({required this.html});

  @override
  Widget build(BuildContext context) {
    // Basic snippet parser for SQLite FTS5 '<b>' '</b>' highlights
    final spans = <TextSpan>[];
    final parts = html.split('<b>');

    for (int i = 0; i < parts.length; i++) {
      if (i == 0) {
        spans.add(TextSpan(text: parts[i]));
      } else {
        final subParts = parts[i].split('</b>');
        if (subParts.isNotEmpty) {
          spans.add(
            TextSpan(
              text: subParts[0],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                backgroundColor: Color(0x337367F0),
              ),
            ),
          );
          if (subParts.length > 1) {
            spans.add(TextSpan(text: subParts[1]));
          }
        }
      }
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: spans,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
