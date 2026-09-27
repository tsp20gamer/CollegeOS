import 'dart:ui';
import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/notes/application/ai_search_providers.dart';
import 'package:college_os/features/notes/domain/ai_context.dart';
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
    super.dispose();
  }

  void _submit(String question) {
    if (question.trim().isEmpty) return;
    _questionController.text = question;
    _focusNode.unfocus();

    List<int>? allowedFileIds;
    if (widget.subjectId != null) {
      final files = ref.read(subjectFilesProvider(widget.subjectId!)).value;
      if (files != null) {
        allowedFileIds = files.map((f) => f.id).toList();
      }
    }

    ref.read(aiSearchControllerProvider.notifier).search(question, allowedFileIds: allowedFileIds);
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (searchState.value == null && !searchState.isLoading)
                  _buildSuggestions(theme),
                if (searchState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (searchState.hasError)
                  _buildErrorState(theme, searchState.error.toString())
                else if (searchState.value != null)
                  _buildAnswer(theme, searchState.value!),
              ],
            ),
          ),
        ),
        _buildInputArea(theme, isDark, searchState.isLoading),
      ],
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Column(
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
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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

  Widget _buildErrorState(ThemeData theme, String error) {
    return Container(
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
              'An error occurred. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer(ThemeData theme, AiSearchResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.violet.withValues(alpha: 0.2),
            ),
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
      ],
    );
  }


  Widget _buildInputArea(ThemeData theme, bool isDark, bool isLoading) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.7 : 0.9),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
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
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                  color: AppColors.violet,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
    );
  }
}

/// A cached provider that resolves a [SubjectFile] by its ID.
///
/// Because it's a family provider, Riverpod automatically caches the result
/// for each unique `fileId`. This guarantees that if the AI cites the same
/// PDF 5 times, we only query the local database once.
final _subjectFileProvider = FutureProvider.family<SubjectFile?, int>((ref, fileId) {
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        file: file,
                        initialPageNumber: source.pageNumber,
                      ),
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: AppColors.violet,
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
                        color: AppColors.violet.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Page ${source.pageNumber}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.violet,
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

