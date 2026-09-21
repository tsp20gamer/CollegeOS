import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Installs local-only last-resort error handling.
///
/// Expected feature failures must still be handled close to their source. This
/// boundary prevents an unexpected build or platform error from replacing the
/// entire release UI with framework diagnostics. No error data leaves the
/// device.
void configureAppErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Unhandled CollegeOS error: $error');
      debugPrintStack(stackTrace: stack);
    }
    return true;
  };
  ErrorWidget.builder = (_) => const CollegeOsErrorView();
}

class CollegeOsErrorView extends StatelessWidget {
  const CollegeOsErrorView({super.key});

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      color: Color(0xFF101116),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: Color(0xFF8FAEFF)),
                SizedBox(height: 12),
                Text(
                  'This section could not be displayed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your CollegeOS data is safe. Go back and try opening it again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB9BDC9)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
