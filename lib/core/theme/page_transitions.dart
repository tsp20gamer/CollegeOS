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

    final curveTween = CurveTween(curve: AppCurves.standard);
    final fadeAnimation = animation.drive(curveTween);
    
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, AppMotion.routeSlideFraction),
      end: Offset.zero,
    ).animate(fadeAnimation);

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}
