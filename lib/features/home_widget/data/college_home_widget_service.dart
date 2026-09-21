import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/home_widget_projection.dart';

const collegeHomeWidgetProviderName = 'CollegeOsHomeWidgetProvider';

abstract interface class HomeWidgetPlatformAdapter {
  Future<void> save(String key, String value);
  Future<void> update();
  Future<bool> supportsPinning();
  Future<void> requestPin();
}

final class AndroidHomeWidgetPlatformAdapter
    implements HomeWidgetPlatformAdapter {
  @override
  Future<void> save(String key, String value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<void> update() async {
    await HomeWidget.updateWidget(androidName: collegeHomeWidgetProviderName);
  }

  @override
  Future<bool> supportsPinning() async =>
      await HomeWidget.isRequestPinWidgetSupported() ?? false;

  @override
  Future<void> requestPin() =>
      HomeWidget.requestPinWidget(androidName: collegeHomeWidgetProviderName);
}

enum HomeWidgetPinResult { requested, unsupported, unavailable }

final class CollegeHomeWidgetService {
  CollegeHomeWidgetService(this._platform);

  final HomeWidgetPlatformAdapter _platform;
  String? _lastFingerprint;

  Future<bool> sync(HomeWidgetProjection projection) async {
    if (!_isAndroid || projection.fingerprint == _lastFingerprint) return false;
    try {
      for (final entry in projection.values.entries) {
        await _platform.save(entry.key, entry.value);
      }
      await _platform.update();
      _lastFingerprint = projection.fingerprint;
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<HomeWidgetPinResult> requestPin() async {
    if (!_isAndroid) return HomeWidgetPinResult.unsupported;
    try {
      if (!await _platform.supportsPinning()) {
        return HomeWidgetPinResult.unsupported;
      }
      await _platform.requestPin();
      return HomeWidgetPinResult.requested;
    } on MissingPluginException {
      return HomeWidgetPinResult.unavailable;
    } on PlatformException {
      return HomeWidgetPinResult.unavailable;
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
