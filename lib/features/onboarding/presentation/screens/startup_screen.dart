import 'package:college_os/features/onboarding/application/onboarding_providers.dart';
import 'package:college_os/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(onboardingCompletedProvider);
    return Scaffold(
      body: SafeArea(
        child: status.hasError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorState(
                    title: 'CollegeOS could not open its local data',
                    message:
                        'Your data has not been changed. Try opening it again.',
                    onRetry: () => ref.invalidate(onboardingCompletedProvider),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
