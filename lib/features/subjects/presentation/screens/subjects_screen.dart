import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/semesters/domain/semester_repository.dart';
import 'package:college_os/features/subjects/application/subject_providers.dart';
import 'package:college_os/features/subjects/domain/subject_repository.dart';
import 'package:college_os/features/subjects/presentation/widgets/subject_card.dart';
import 'package:college_os/features/subjects/presentation/widgets/subject_form_sheet.dart';
import 'package:college_os/shared/widgets/app_scaffold.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _SubjectView { active, archived }

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  _SubjectView _view = _SubjectView.active;

  @override
  Widget build(BuildContext context) {
    final activeSemester = ref.watch(activeSemesterProvider);
    final subjects = ref.watch(activeSemesterSubjectsProvider);
    return AppScaffold(
      title: 'Subjects',
      subtitle: activeSemester.when(
        data: (semester) => semester == null
            ? 'Create an active semester before adding subjects.'
            : '${semester.name} · ${semester.academicYear}',
        loading: () => 'Loading your active semester…',
        error: (_, _) => 'Your active semester could not be loaded.',
      ),
      actions: [
        IconButton.filledTonal(
          key: const Key('add_subject_icon_button'),
          tooltip: 'Add Subject',
          onPressed: activeSemester.value == null
              ? null
              : () => _showSubjectForm(activeSemester.value!),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: activeSemester.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => ErrorState(
          title: 'Could not load your semester',
          message: 'Your local data is unchanged. Try loading it again.',
          onRetry: () => ref.invalidate(activeSemesterProvider),
        ),
        data: (semester) {
          if (semester == null) {
            return const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No active semester',
              message:
                  'Subject management needs an active semester. Your existing data has not been changed.',
            );
          }
          return subjects.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => ErrorState(
              title: 'Could not load subjects',
              message: 'Your local subjects are safe. Try loading them again.',
              onRetry: () => ref.invalidate(activeSemesterSubjectsProvider),
            ),
            data: (allSubjects) => _buildSubjects(semester, allSubjects),
          );
        },
      ),
    );
  }

  Widget _buildSubjects(Semester semester, List<Subject> allSubjects) {
    final active = allSubjects
        .where((subject) => !subject.isArchived)
        .toList(growable: false);
    final archived = allSubjects
        .where((subject) => subject.isArchived)
        .toList(growable: false);
    final visible = _view == _SubjectView.active ? active : archived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_SubjectView>(
          segments: [
            ButtonSegment(
              value: _SubjectView.active,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text('Active (${active.length})'),
            ),
            ButtonSegment(
              value: _SubjectView.archived,
              icon: const Icon(Icons.archive_outlined),
              label: Text('Archived (${archived.length})'),
            ),
          ],
          selected: {_view},
          onSelectionChanged: (selection) {
            setState(() => _view = selection.single);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visible.isEmpty)
          EmptyState(
            icon: _view == _SubjectView.active
                ? Icons.menu_book_outlined
                : Icons.inventory_2_outlined,
            title: _view == _SubjectView.active
                ? 'No subjects yet'
                : 'No archived subjects',
            message: _view == _SubjectView.active
                ? 'Add the subjects you study this semester. Nothing is added until you save it.'
                : 'Subjects you archive will remain here with all of their history.',
            action: _view == _SubjectView.active
                ? FilledButton.icon(
                    key: const Key('add_first_subject_button'),
                    onPressed: () => _showSubjectForm(semester),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Your First Subject'),
                  )
                : null,
          )
        else
          ...visible.map(
            (subject) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SubjectCard(
                subject: subject,
                onEdit: () => _showSubjectForm(semester, subject: subject),
                onArchiveChanged: (archived) =>
                    _setArchived(subject, archived: archived),
              ),
            ),
          ),
        if (visible.isNotEmpty && _view == _SubjectView.active) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('add_subject_button'),
            onPressed: () => _showSubjectForm(semester),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Subject'),
          ),
        ],
      ],
    );
  }

  Future<void> _showSubjectForm(Semester semester, {Subject? subject}) async {
    final settings = await ref.read(settingsRepositoryProvider).get();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => SubjectFormSheet(
        semesterId: semester.id,
        defaultAttendanceTarget: settings.defaultAttendanceTarget,
        subject: subject,
      ),
    );
  }

  Future<void> _setArchived(Subject subject, {required bool archived}) async {
    final changed = await ref
        .read(subjectCommandProvider.notifier)
        .setArchived(subject.id, archived: archived);
    if (!mounted) return;
    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The subject could not be updated.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archived
              ? '${subject.name} archived. Its history is preserved.'
              : '${subject.name} restored.',
        ),
        action: archived
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () => ref
                    .read(subjectCommandProvider.notifier)
                    .setArchived(subject.id, archived: false),
              )
            : null,
      ),
    );
  }
}
