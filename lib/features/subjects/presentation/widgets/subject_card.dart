import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SubjectCardAction { notes, edit, archive, restore }

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onArchiveChanged,
    super.key,
  });

  final Subject subject;
  final VoidCallback onEdit;
  final ValueChanged<bool> onArchiveChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(subject.displayColor);
    return Card(
      key: ValueKey('subject_card_${subject.id}'),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  _monogram,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (subject.shortCode.isNotEmpty)
                          _InfoChip(
                            icon: Icons.tag_rounded,
                            label: subject.shortCode,
                          ),
                        if (subject.professor.isNotEmpty)
                          _InfoChip(
                            icon: Icons.person_outline_rounded,
                            label: subject.professor,
                          ),
                        if (subject.room.isNotEmpty)
                          _InfoChip(
                            icon: Icons.meeting_room_outlined,
                            label: subject.room,
                          ),
                        _InfoChip(
                          icon: Icons.track_changes_rounded,
                          label:
                              '${_formatPercent(subject.attendanceTarget * 100)}% target',
                          color: accent,
                        ),
                        if (subject.isArchived)
                          _InfoChip(
                            icon: Icons.archive_outlined,
                            label: 'Archived',
                            color: colors.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Notes',
                icon: const Icon(Icons.notes_rounded),
                onPressed: () => context.push(
                  RoutePaths.subjectNotes.replaceFirst(
                    ':subjectId',
                    '${subject.id}',
                  ),
                ),
              ),
              PopupMenuButton<SubjectCardAction>(
                tooltip: 'Subject actions',
                onSelected: (action) {
                  switch (action) {
                    case SubjectCardAction.notes:
                      context.push(
                        RoutePaths.subjectNotes.replaceFirst(
                          ':subjectId',
                          '${subject.id}',
                        ),
                      );
                    case SubjectCardAction.edit:
                      onEdit();
                    case SubjectCardAction.archive:
                      onArchiveChanged(true);
                    case SubjectCardAction.restore:
                      onArchiveChanged(false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SubjectCardAction.notes,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notes_rounded),
                      title: Text('Notes'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: SubjectCardAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: subject.isArchived
                        ? SubjectCardAction.restore
                        : SubjectCardAction.archive,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        subject.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
                      title: Text(subject.isArchived ? 'Restore' : 'Archive'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _monogram {
    if (subject.shortCode.trim().isNotEmpty) {
      final code = subject.shortCode.trim();
      return code.substring(0, code.length.clamp(1, 2)).toUpperCase();
    }
    final words = subject.name.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  String _formatPercent(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = color ?? colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
