import 'package:college_os/core/theme/spacing.dart';
import 'package:flutter/material.dart';

class OfflineHelpScreen extends StatelessWidget {
  const OfflineHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.offline_bolt_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'CollegeOS works completely offline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Your timetable, attendance, tasks, exams, and marks stay on this device. Export a full backup before changing or resetting your phone.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HelpSection(
            icon: Icons.rocket_launch_outlined,
            title: 'Start here',
            steps: [
              'Add every subject you study in Settings > Subjects.',
              'Create the weekly timetable once. Choose the correct subject, day, and class time.',
              'Open Attendance each day. Your scheduled classes appear automatically.',
              'Mark the whole day or change individual classes when attendance is mixed.',
            ],
          ),
          const _HelpSection(
            icon: Icons.fact_check_outlined,
            title: 'Attendance',
            steps: [
              'Calendar and Classes show the same attendance records; edits in either view update everywhere.',
              'Only Present and Absent classes count toward attendance percentage.',
              'Cancelled, unmarked, holiday, and college-closed classes are excluded.',
              'Pending Attendance lists past classes that still need a decision. CollegeOS never marks them absent automatically.',
            ],
          ),
          const _HelpSection(
            icon: Icons.calendar_month_outlined,
            title: 'Calendar and timetable changes',
            steps: [
              'Use Academic Calendar for holiday ranges, college closures, exam periods, and events.',
              'Changing a timetable keeps historical marked attendance intact.',
              'Use semester rollover to preserve history while copying subjects and timetable into the next semester.',
            ],
          ),
          const _HelpSection(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Reports and backups',
            steps: [
              'Reports can be filtered by week, month, semester, or subject and saved as printable PDF files.',
              'Automatic backups stay on this phone and help with local recovery.',
              'Export Full Backup creates a portable .collegeos file for transferring all data to another phone.',
            ],
          ),
          const _HelpSection(
            icon: Icons.notifications_none_rounded,
            title: 'Reminders',
            steps: [
              'Notifications are device-only and work without Firebase or a network connection.',
              'Permission is requested only when you enable notifications or create a reminder.',
            ],
          ),
        ],
      ),
    ),
  );
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(step)),
              ],
            ),
          ),
      ],
    ),
  );
}
