import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:flutter/material.dart';

class CollegePageTransitionsBuilder extends PageTransitionsBuilder {
  const CollegePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst || MediaQuery.disableAnimationsOf(context)) return child;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final reversing = animation.status == AnimationStatus.reverse;
        final opacity = reversing
            ? Curves.easeInOutCubic.transform(animation.value)
            : .82 + (.18 * AppCurves.standard.transform(animation.value));
        return Opacity(
          key: const Key('optimized_page_transition'),
          opacity: opacity.clamp(0, 1),
          child: child,
        );
      },
    );
  }
}
