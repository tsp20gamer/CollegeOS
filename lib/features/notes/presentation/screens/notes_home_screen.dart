import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/effects.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/subject_files/application/subject_files_providers.dart';
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

/// The Notes destination: everything the student has collected for a subject,
/// with search one tap away.
///
/// Browsing stays subject-based so the tab answers "what do I have for this
/// subject", while [RoutePaths.notesSearch] answers "where is this topic". The
/// two entry points deliberately stay separate rather than duplicating each
/// other in one screen.
class NotesHomeScreen extends ConsumerWidget {
  const NotesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            for (final subject in subjects.value!) ...[
              _SubjectNotesCard(subject: subject),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumSurface(
      key: const Key('notes_search_entry'),
      onTap: onTap,
      semanticLabel: 'Search all notes',
      color: colors.primaryContainer.withValues(alpha: isDark ? .38 : .52),
      borderColor: colors.primary.withValues(alpha: .32),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search all notes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  'Every indexed PDF page, plus answers from your own notes.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _SubjectNotesCard extends ConsumerWidget {
  const _SubjectNotesCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color(subject.displayColor);
    final files = ref.watch(subjectFilesProvider(subject.id));

    final details = [
      if (subject.shortCode.isNotEmpty) subject.shortCode,
      if (subject.room.isNotEmpty) 'Room ${subject.room}',
      if (files.hasValue) '${files.value!.length} files',
      if (subject.isArchived) 'Archived',
    ];

    return PremiumSurface(
      key: ValueKey('notes_subject_${subject.id}'),
      onTap: () => context.push(
        RoutePaths.subjectNotes.replaceFirst(':subjectId', '${subject.id}'),
      ),
      semanticLabel: '${subject.name}, open notes and files',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? .22 : .14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: accent.withValues(alpha: .42)),
              boxShadow: AppGlows.subjectAccent(
                accent,
                brightness: Theme.of(context).brightness,
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: AppIconSize.sm,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxxs),
                  Text(
                    details.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
