import 'package:college_os/features/home_widget/data/college_home_widget_service.dart';
import 'package:college_os/features/home_widget/domain/home_widget_projection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('sync stores projection and skips an unchanged projection', () async {
    final adapter = _FakeAdapter();
    final service = CollegeHomeWidgetService(adapter);

    expect(await service.sync(_projection()), isTrue);
    expect(adapter.saved, hasLength(10));
    expect(adapter.updates, 1);

    expect(await service.sync(_projection()), isFalse);
    expect(adapter.saved, hasLength(10));
    expect(adapter.updates, 1);
  });

  test('sync writes and redraws when visible content changes', () async {
    final adapter = _FakeAdapter();
    final service = CollegeHomeWidgetService(adapter);
    await service.sync(_projection());

    final changed = _projection(classTitle: 'Physics');
    expect(await service.sync(changed), isTrue);
    expect(adapter.updates, 2);
    expect(adapter.saved['widget_class_title'], 'Physics');
  });

  test('pin request reports launcher capability', () async {
    final supportedAdapter = _FakeAdapter();
    final supported = CollegeHomeWidgetService(supportedAdapter);
    expect(await supported.requestPin(), HomeWidgetPinResult.requested);
    expect(supportedAdapter.pinRequests, 1);

    final unsupportedAdapter = _FakeAdapter()..pinSupported = false;
    final unsupported = CollegeHomeWidgetService(unsupportedAdapter);
    expect(await unsupported.requestPin(), HomeWidgetPinResult.unsupported);
    expect(unsupportedAdapter.pinRequests, 0);
  });
}

HomeWidgetProjection _projection({String classTitle = 'Mathematics'}) =>
    HomeWidgetProjection(
      classLabel: 'NEXT CLASS',
      classTitle: classTitle,
      classTime: 'Today · 9:30 AM',
      classMeta: 'A-201 · Dr Rao',
      attendanceTitle: 'TODAY\'S ATTENDANCE',
      attendanceSummary: '2 present · 0 absent',
      attendanceMeta: '1 unmarked',
      attendanceStatus: '1 pending',
      attendanceProgress: 67,
      dateKey: '2026-08-13',
    );

final class _FakeAdapter implements HomeWidgetPlatformAdapter {
  final saved = <String, String>{};
  var updates = 0;
  var pinRequests = 0;
  var pinSupported = true;

  @override
  Future<void> save(String key, String value) async => saved[key] = value;

  @override
  Future<void> update() async => updates++;

  @override
  Future<bool> supportsPinning() async => pinSupported;

  @override
  Future<void> requestPin() async => pinRequests++;
}
