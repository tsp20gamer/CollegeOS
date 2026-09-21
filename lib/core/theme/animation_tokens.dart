import 'package:flutter/animation.dart';

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}

abstract final class AppMotion {
  static const pageSlideDistance = 14.0;
  static const routeSlideFraction = 0.035;
  static const routeStartScale = 0.985;
  static const dockSelectedIconScale = 1.08;
  static const dockPageSlideFraction = .012;
}
