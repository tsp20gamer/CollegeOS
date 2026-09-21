import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GettingStartedScreen extends StatelessWidget {
  const GettingStartedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Your CollegeOS is ready',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Set up these two essentials once, then daily attendance takes only a few taps.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _GuideStep(
                number: '1',
                icon: Icons.menu_book_outlined,
                title: 'Add your subjects',
                body:
                    'Subjects connect your timetable, attendance, exams, and marks.',
              ),
              const SizedBox(height: AppSpacing.sm),
              const _GuideStep(
                number: '2',
                icon: Icons.calendar_view_week_outlined,
                title: 'Create your weekly timetable',
                body:
                    'Add each recurring class once. CollegeOS will show the correct classes on every semester date.',
              ),
              const SizedBox(height: AppSpacing.sm),
              const _GuideStep(
                number: '3',
                icon: Icons.fact_check_outlined,
                title: 'Mark attendance by day',
                body:
                    'Use Present Day for a full day, or edit individual classes when you bunk one.',
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                key: const Key('start_with_subjects_button'),
                onPressed: () => context.go(RoutePaths.subjects),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Add Subjects'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.go(RoutePaths.home),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 32),
              Positioned(
                right: -8,
                top: -8,
                child: CircleAvatar(
                  radius: 10,
                  child: Text(number, style: const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
