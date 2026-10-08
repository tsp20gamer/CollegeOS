import 'package:flutter/animation.dart';

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);

  /// Duration of the dock icon's selection pop.
  ///
  /// Long enough for the rise-and-settle to read as one motion, short enough
  /// that the icon is back at rest while the page is still moving.
  static const dockSelection = Duration(milliseconds: 240);

  /// Duration for the dock's active indicator dot.
  static const dockDot = Duration(milliseconds: 150);

  /// Duration the timetable day pill takes to glide between day slots.
  ///
  /// Slightly longer than the dock's pop: the pill travels a real distance, so
  /// it needs the extra time to read as one continuous slide.
  static const dayPillGlide = Duration(milliseconds: 260);

  /// Duration for a day change's content cross-fade.
  static const dayContent = Duration(milliseconds: 220);
}

abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;

  /// A gentle deceleration for the dock hide/show.
  static const dockReveal = Curves.easeOutQuart;
}

abstract final class AppMotion {
  static const pageSlideDistance = 14.0;
  static const routeSlideFraction = 0.035;
  static const routeStartScale = 0.985;

  /// Resting scale of the selected dock icon.
  ///
  /// A touch stronger than its neighbours: selection reads from the cobalt
  /// glyph, the cobalt label and the dot underneath it, never from a capsule.
  static const dockSelectedIconScale = 1.04;

  /// Peak of the icon's selection pop, before it settles back.
  static const dockIconPeakScale = 1.10;

  /// Scale the pop passes through on the way down.
  static const dockIconPopScale = 1.04;

  /// How far the icon lifts during the pop, in logical pixels.
  static const dockIconLift = 2.5;

  /// Fraction of horizontal slide for page transition on tab switch.
  static const dockPageSlideFraction = .018;

  /// Opacity the outgoing page fades to during a tab switch.
  static const dockPageFadeOutOpacity = 0.6;

  /// Fraction of horizontal travel for the timetable day content.
  static const dayContentSlide = 0.02;
}
