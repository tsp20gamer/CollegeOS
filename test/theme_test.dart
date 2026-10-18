import 'package:college_os/core/theme/app_theme.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/effects.dart';
import 'package:college_os/core/theme/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollegeOS themes', () {
    test('use Material 3 with distinct premium surfaces', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(
        light.scaffoldBackgroundColor,
        isNot(dark.scaffoldBackgroundColor),
      );
      expect(dark.scaffoldBackgroundColor, AppColors.darkSurface);
      expect(dark.colorScheme.surfaceContainerLow, AppColors.darkSurfaceLow);
      // Primary accent is Electric Cobalt in both modes.
      expect(light.colorScheme.primary, AppColors.cobalt);
      expect(dark.colorScheme.primary, AppColors.cobalt);
      // Secondary is also cobalt (unified single accent).
      expect(light.colorScheme.secondary, AppColors.cobalt);
      expect(dark.colorScheme.secondary, AppColors.cobalt);
      expect(dark.textTheme.bodyMedium?.fontFamily, isNot('Inter'));
      expect(dark.textTheme.labelSmall?.fontFamily, isNot('Geist'));
    });

    test('provide complete semantic status colors in both modes', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final semantic = theme.extension<AppSemanticColors>();
        expect(semantic, isNotNull);
        expect(
          _contrastRatio(
            semantic!.onSuccessContainer,
            semantic.successContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(
            semantic.onWarningContainer,
            semantic.warningContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(semantic.onInfoContainer, semantic.infoContainer),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('retain accessible touch targets and motion configuration', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
        final iconSize = theme.iconButtonTheme.style?.minimumSize?.resolve({});
        expect(
          iconSize?.width,
          greaterThanOrEqualTo(AppLayout.minimumTouchTarget),
        );
        expect(
          iconSize?.height,
          greaterThanOrEqualTo(AppLayout.minimumTouchTarget),
        );
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<CollegePageTransitionsBuilder>(),
        );
      }
    });

    test('AppGlows.text returns empty list (no neon text glow)', () {
      final shadows = AppGlows.text(strength: 1.0);
      expect(shadows, isEmpty);
    });

    testWidgets('pages fade and rise in, and fade back out when popped', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Destination')),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Destination'), findsOneWidget);
      final openingTransition = find.byKey(const Key('app_page_transition'));
      expect(openingTransition, findsOneWidget);
      final openingOpacity = tester.widget<Opacity>(openingTransition).opacity;
      // The page is on screen and mid-flight: visible, but not yet at rest.
      expect(openingOpacity, greaterThan(0));
      expect(openingOpacity, lessThan(1));

      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(openingTransition).opacity, 1);

      Navigator.of(tester.element(find.text('Destination'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final closingTransition = find.byKey(const Key('app_page_transition'));
      expect(closingTransition, findsOneWidget);
      expect(tester.widget<Opacity>(closingTransition).opacity, lessThan(1));
    });

    testWidgets('reduced motion removes the page transition entirely', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Destination')),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Destination'), findsOneWidget);
      expect(find.byKey(const Key('app_page_transition')), findsNothing);
    });
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
