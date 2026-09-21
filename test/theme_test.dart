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
      expect(light.colorScheme.primary, AppColors.violet);
      expect(dark.colorScheme.primary, AppColors.violet);
      expect(light.colorScheme.secondary, AppColors.blue);
      expect(dark.colorScheme.secondary, AppColors.blue);
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

    test('subject accent glow stays tight and restrained', () {
      final shadows = AppGlows.subjectAccent(
        const Color(0xFF008000),
        brightness: Brightness.dark,
      );

      expect(shadows, hasLength(2));
      expect(shadows.first.blurRadius, 6);
      expect(shadows.first.spreadRadius, 0);
      expect(shadows.last.blurRadius, 14);
      expect(shadows.last.spreadRadius, lessThan(0));
      expect(shadows.first.color.a, lessThan(.4));
    });

    testWidgets('normal pages open quickly and close with a complete fade', (
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
      final optimizedTransition = find.byKey(
        const Key('optimized_page_transition'),
      );
      expect(optimizedTransition, findsOneWidget);
      expect(
        tester.widget<Opacity>(optimizedTransition).opacity,
        greaterThan(.82),
      );

      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Destination'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final closingTransition = find.byKey(
        const Key('optimized_page_transition'),
      );
      expect(closingTransition, findsOneWidget);
      expect(tester.widget<Opacity>(closingTransition).opacity, lessThan(.82));
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
