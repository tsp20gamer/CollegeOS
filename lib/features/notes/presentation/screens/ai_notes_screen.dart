import 'dart:ui';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/features/notes/application/ai_search_providers.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
import 'package:college_os/features/notes/domain/ai_note_search_state.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
import 'package:college_os/features/subject_files/domain/subject_file.dart';
import 'package:college_os/features/subject_files/presentation/screens/pdf_viewer_screen.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiNotesScreen extends ConsumerStatefulWidget {
  const AiNotesScreen({super.key, this.subjectId});

  final int? subjectId;

  @override
  ConsumerState<AiNotesScreen> createState() => _AiNotesScreenState();
}

class _AiNotesScreenState extends ConsumerState<AiNotesScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// Tracks the last question submitted, so retry can re-ask it.
  String _lastQuestion = '';

  static const _suggestions = [
    "Explain PN junction diode",
    "What is ion-exchange method?",
    "Give me a short answer about potable water treatment",
    "Summarize this topic",
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit(String question) {
    if (question.trim().isEmpty) return;
    _questionController.text = question;
    _lastQuestion = question.trim();
    _focusNode.unfocus();

    List<int>? allowedFileIds;
    if (widget.subjectId != null) {
      final files = ref.read(subjectFilesProvider(widget.subjectId!)).value;
      if (files != null) {
        allowedFileIds = files.map((f) => f.id).toList();
      }
    }

    ref
        .read(aiSearchControllerProvider.notifier)
        .ask(question, allowedFileIds: allowedFileIds);

    // Scroll to top to show the result as it appears.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppDurations.medium,
        curve: AppCurves.standard,
      );
    }
  }

  void _retry() {
    if (_lastQuestion.isNotEmpty) {
      _submit(_lastQuestion);
    }
  }

  void _clearAndAskNew() {
    _questionController.clear();
    ref.read(aiSearchControllerProvider.notifier).reset();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(aiSearchControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              switchInCurve: AppCurves.standard,
              switchOutCurve: Curves.easeInCubic,
              child: _buildContent(theme, searchState),
            ),
          ),
        ),
        _buildInputArea(theme, isDark, searchState),
      ],
    );
  }

  /// Builds the main content area based on the current search state.
  Widget _buildContent(ThemeData theme, AiNoteSearchStatus searchState) {
    if (searchState.phase == AiNoteSearchPhase.idle) {
      return _buildSuggestions(theme);
    }

    if (searchState.isBusy) {
      return _buildProgressState(theme, searchState);
    }

    if (searchState.phase == AiNoteSearchPhase.offline ||
        searchState.phase == AiNoteSearchPhase.apiError) {
      return _buildErrorState(theme, searchState.message ?? '');
    }

    if (searchState.phase == AiNoteSearchPhase.noContext) {
      return _buildNoContextState(theme);
    }

    if (searchState.result != null) {
      return _buildAnswer(theme, searchState.result!);
    }

    return _buildSuggestions(theme);
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Column(
      key: const ValueKey('suggestions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _suggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion),
              onPressed: () => _submit(suggestion),
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressState(ThemeData theme, AiNoteSearchStatus searchState) {
    return Center(
      key: const ValueKey('progress'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Text(
                searchState.progressLabel ?? 'Working…',
                key: ValueKey(searchState.phase),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (searchState.sourcePageCount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${searchState.sourcePageCount} pages found',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Column(
      key: const ValueKey('error'),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message.isEmpty
                      ? 'An error occurred. Please try again.'
                      : message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: _clearAndAskNew,
              child: const Text('Ask something else'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoContextState(ThemeData theme) {
    final colors = theme.colorScheme;
    return Column(
      key: const ValueKey('noContext'),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 40,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Couldn't find this in your notes",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Make sure the relevant PDF is indexed, or try rephrasing your question.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton.icon(
          onPressed: _clearAndAskNew,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Try a different question'),
        ),
      ],
    );
  }

  Widget _buildAnswer(ThemeData theme, AiSearchResult result) {
    return Column(
      key: const ValueKey('answer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: MarkdownBody(
            data: result.answer,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              h1: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h2: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              h3: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              listBullet: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              strong: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.6,
              ),
              em: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              blockSpacing: 12.0,
            ),
          ),
        ),
        if (result.hasSources) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Sources',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...result.sources.map((s) => _SourceItemCard(source: s)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            onPressed: _clearAndAskNew,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Ask another question'),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(
    ThemeData theme,
    bool isDark,
    AiNoteSearchStatus searchState,
  ) {
    final isLoading = searchState.isBusy;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: isDark ? 0.7 : 0.9,
            ),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _submit(val),
                    decoration: InputDecoration(
                      hintText: 'Ask something from your notes...',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isLoading
                        ? AppColors.cobalt.withValues(alpha: 0.6)
                        : AppColors.cobalt,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isLoading
                        ? null
                        : () => _submit(_questionController.text),
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.arrow_upward, color: Colors.white),
                    tooltip: 'Ask AI',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A cached provider that resolves a [SubjectFile] by its ID.
///
/// Because it's a family provider, Riverpod automatically caches the result
/// for each unique `fileId`. This guarantees that if the AI cites the same
/// PDF 5 times, we only query the local database once.
final _subjectFileProvider = FutureProvider.family<SubjectFile?, int>((
  ref,
  fileId,
) {
  return ref.watch(subjectFileRepositoryProvider).getById(fileId);
});

class _SourceItemCard extends ConsumerWidget {
  const _SourceItemCard({required this.source});

  final AiSourceReference source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch the cached FutureProvider for this specific fileId.
    final fileAsync = ref.watch(_subjectFileProvider(source.fileId));
    final file = fileAsync.value;

    // Resolve the display title based on the async state.
    final title = fileAsync.when(
      data: (f) => f?.title ?? 'Document',
      loading: () => 'Loading PDF...',
      error: (err, stack) => 'Document',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: file == null
              ? null
              : () {
                  PdfViewerScreen.open(
                    context,
                    file: file,
                    initialPageNumber: source.pageNumber,
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: AppColors.cobalt,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cobalt.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Page ${source.pageNumber}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.cobalt,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
