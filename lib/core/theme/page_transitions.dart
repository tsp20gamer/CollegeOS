import 'package:flutter/material.dart';

/// Page transition tuned for perceived speed: a pushed page appears at once,
/// while a popped page fades out completely. Animations are skipped entirely
/// for the first route and when the system requests reduced motion.
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

    // Open instantly: any forward progress renders the page fully opaque.
    // Closing keeps the standard ease-in fade so the page leaves gracefully.
    final opacityAnimation = CurvedAnimation(
      parent: animation,
      curve: const Threshold(0),
      reverseCurve: Curves.easeIn,
    );

    return AnimatedBuilder(
      animation: opacityAnimation,
      builder: (context, _) => Opacity(
        key: const Key('optimized_page_transition'),
        opacity: opacityAnimation.value,
        child: child,
      ),
    );
  }
}
