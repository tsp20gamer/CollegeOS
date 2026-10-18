import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:flutter/material.dart';

/// Page transition used by every route in the app.
///
/// A pushed page fades in while rising a few pixels and settling from a hair
/// below full size, so navigation reads as one quick, visible motion instead
/// of an instant swap. Popping runs the same tween backwards, so the page
/// sinks and fades away. The first route and reduced-motion requests skip the
/// transition entirely.
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
    if (route.isFirst || AppMotion.reduceMotion(context)) return child;

    final progress = CurvedAnimation(
      parent: animation,
      curve: AppCurves.standard,
      reverseCurve: Curves.easeIn,
    );
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final value = progress.value;
        return Opacity(
          key: const Key('app_page_transition'),
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, AppMotion.pageSlideDistance * (1 - value)),
            child: Transform.scale(
              // Settles from just under full size, so the page reads as
              // arriving at the viewer rather than simply appearing.
              scale:
                  AppMotion.routeStartScale +
                  (1 - AppMotion.routeStartScale) * value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
