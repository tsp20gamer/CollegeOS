import 'package:college_os/features/attendance/application/attendance_providers.dart';
import 'package:college_os/features/home_widget/data/college_home_widget_service.dart';
import 'package:college_os/features/home_widget/domain/home_widget_projection.dart';
import 'package:college_os/features/timetable/application/timetable_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeWidgetPlatformAdapterProvider = Provider<HomeWidgetPlatformAdapter>(
  (ref) => AndroidHomeWidgetPlatformAdapter(),
);

final collegeHomeWidgetServiceProvider = Provider<CollegeHomeWidgetService>(
  (ref) =>
      CollegeHomeWidgetService(ref.watch(homeWidgetPlatformAdapterProvider)),
);

final collegeHomeWidgetProjectionProvider =
    Provider<AsyncValue<HomeWidgetProjection>>((ref) {
      final nowValue = ref.watch(localMinuteProvider);
      final nextValue = ref.watch(nextClassProvider);
      final now = nowValue.value ?? DateTime.now();
      final dayValue = ref.watch(attendanceDayProvider(now));
      if (nowValue.isLoading || nextValue.isLoading || dayValue.isLoading) {
        return const AsyncLoading();
      }
      if (nextValue.hasError) {
        return AsyncError(nextValue.error!, nextValue.stackTrace!);
      }
      if (dayValue.hasError) {
        return AsyncError(dayValue.error!, dayValue.stackTrace!);
      }
      return AsyncData(
        HomeWidgetProjectionBuilder.build(
          now: now,
          nextClass: nextValue.value!,
          attendanceDay: dayValue.value,
        ),
      );
    });

final homeWidgetPinControllerProvider =
    AsyncNotifierProvider<HomeWidgetPinController, void>(
      HomeWidgetPinController.new,
    );

final class HomeWidgetPinController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<HomeWidgetPinResult> requestPin() async {
    state = const AsyncLoading();
    final result = await ref
        .read(collegeHomeWidgetServiceProvider)
        .requestPin();
    state = const AsyncData(null);
    return result;
  }
}
