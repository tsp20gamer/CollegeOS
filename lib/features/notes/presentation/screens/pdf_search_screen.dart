import 'dart:async';

import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/notes/domain/pdf_search_result.dart';

import 'package:college_os/features/notes/application/pdf_search_providers.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keyword search across the text CollegeOS has extracted from the student's
/// own PDFs.
///
/// Everything here runs on device against the local FTS5 index; the screen
/// makes no network request. It lives inside the Notes tab, so the dock stays
/// the way back and the header needs no back arrow.
class PdfSearchScreen extends ConsumerStatefulWidget {
  const PdfSearchScreen({this.subjectId, super.key});

  /// Scopes the results and the indexing indicator to one subject's files.
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
        setState(() {
          _query = query;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Reconcile files in the current search scope. A library-wide search also
    // queues older PDFs so pre-existing scanned files gain OCR indexes.
    final subjectId = widget.subjectId;
    if (subjectId != null) {
      ref.listen(subjectFilesProvider(subjectId), (previous, next) {
        final files = next.value;
        if (files != null && files.isNotEmpty) {
          ref.read(pdfIndexCommandProvider.notifier).indexMissingPdfs(files);
        }
      });
    } else {
      ref.listen(searchableFilesProvider(null), (previous, next) {
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
              // Search is a pushed screen, so it carries the app's one back
              // affordance: the dock stays the way between destinations, and
              // the arrow is what returns to the screen search was opened from.
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
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            setState(() => _query = '');
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
    final failedFiles = <({SubjectFile file, int pageCount, String message})>[];
    for (final file in files) {
      final meta = metadata.where((m) => m.fileId == file.id).firstOrNull;
      if (meta != null && meta.status.startsWith('indexing')) {
        final progress = RegExp(r'\((\d+)\/(\d+)\)').firstMatch(meta.status);
        final statusText = progress == null
            ? 'Preparing searchable text…'
            : 'Indexing • ${progress.group(1)} of ${progress.group(2)} pages';
        indexingFiles.add('${file.title}: $statusText');
      } else if (meta?.status == 'ocr_error') {
        failedFiles.add((
          file: file,
          pageCount: meta?.pageCount ?? 0,
          message: 'OCR could not read some scanned pages.',
        ));
      } else if (meta?.status == 'error') {
        failedFiles.add((
          file: file,
          pageCount: meta?.pageCount ?? 0,
          message: 'Text extraction stopped before indexing completed.',
        ));
      }
    }
    if (indexingFiles.isEmpty && failedFiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          if (indexingFiles.isNotEmpty)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onPrimaryContainer,
              ),
            )
          else
            Icon(
              Icons.document_scanner_outlined,
              size: 18,
              color: colors.onPrimaryContainer,
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (indexingFiles.isNotEmpty)
                  Text(
                    indexingFiles.join('\n'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                for (final failure in failedFiles)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${failure.file.title}: ${failure.message}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onPrimaryContainer),
                            ),
                            if (failure.pageCount > 0)
                              ref
                                  .watch(
                                    pdfPagesWithoutSearchTextProvider((
                                      fileId: failure.file.id,
                                      pageCount: failure.pageCount,
                                    )),
                                  )
                                  .when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, _) => const SizedBox.shrink(),
                                    data: (pages) {
                                      if (pages.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      final shownPages = pages
                                          .take(8)
                                          .join(', ');
                                      final remaining = pages.length - 8;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.xxs,
                                        ),
                                        child: Text(
                                          'No indexed text on pages $shownPages${remaining > 0 ? ' and $remaining more' : ''}. Blank pages may be included.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color:
                                                    colors.onPrimaryContainer,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(pdfIndexCommandProvider.notifier)
                            .retryIndexing(
                              failure.file.id,
                              failure.file.relativeFilePath,
                            ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(
      pdfSearchProvider((query: _query, subjectId: widget.subjectId)),
    );
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

        final grouped = <int, List<PdfSearchResult>>{};
        for (final result in results) {
          if (fileMap.containsKey(result.fileId)) {
            grouped.putIfAbsent(result.fileId, () => []).add(result);
          }
        }

        if (grouped.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results found',
            message:
                'Try another keyword or check whether this PDF has finished indexing.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final fileId = grouped.keys.elementAt(index);
            final file = fileMap[fileId]!;
            final matches = grouped[fileId]!;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                          '${matches.length} ${matches.length == 1 ? 'page' : 'pages'}',
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
                    for (final result in matches)
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () => PdfViewerScreen.open(
                          context,
                          file: file,
                          initialPageNumber: result.pageNumber,
                          initialSearchQuery: _query,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 54,
                                child: Text(
                                  'p. ${result.pageNumber}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Expanded(child: _HtmlText(html: result.snippet)),
                              const Icon(Icons.chevron_right_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
