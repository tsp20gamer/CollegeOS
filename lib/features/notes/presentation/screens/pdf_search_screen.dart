import 'dart:async';

import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';

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
                  PdfViewerScreen.open(
                    context,
                    file: file,
                    initialPageNumber: result.pageNumber,
                    initialSearchQuery: _query,
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
