import 'package:college_os/core/database/database_providers.dart';
import 'package:college_os/features/onboarding/data/drift_onboarding_repository.dart';
import 'package:college_os/features/onboarding/domain/college_setup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => DriftOnboardingRepository(ref.watch(appDatabaseProvider)),
);

final onboardingCompletedProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch()
      .map((settings) => settings.onboardingCompleted);
});

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);

final class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> complete(CollegeSetup setup) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(onboardingRepositoryProvider).completeSetup(setup),
    );
    return !state.hasError;
  }
}
