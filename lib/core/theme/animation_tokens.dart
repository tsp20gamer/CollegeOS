import 'package:flutter/widgets.dart';

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);

  /// Base duration of a screen's content settling in after it opens.
  static const entrance = Duration(milliseconds: 320);

  /// Delay added per stagger step, so a screen's sections settle in as a
  /// short wave instead of fading as one block.
  static const entranceStagger = Duration(milliseconds: 40);

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

  /// The dock's rise-and-settle pop as a scale animation driven by [parent].
  ///
  /// 1.0 → 1.10 → through 1.04 → back to 1.0: a small rise and settle, never a
  /// bounce. [begin] lets an icon that is appearing start below its resting
  /// size so it grows into place. The dock's chosen icon and every icon pop
  /// elsewhere share this sequence, so one pop everywhere reads the same way.
  static Animation<double> popScale(
    Animation<double> parent, {
    double begin = 1,
  }) => TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: begin,
        end: dockIconPeakScale,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: dockIconPeakScale,
        end: dockIconPopScale,
      ).chain(CurveTween(curve: AppCurves.standard)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: dockIconPopScale,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
  ]).animate(parent);

  /// Fraction of horizontal slide for page transition on tab switch.
  static const dockPageSlideFraction = .018;

  /// Opacity the outgoing page fades to during a tab switch.
  static const dockPageFadeOutOpacity = 0.6;

  /// Fraction of horizontal travel for the timetable day content.
  static const dayContentSlide = 0.02;

  /// How far a settling section rises while it fades in, in logical pixels.
  static const entranceRise = 12.0;

  /// Highest stagger step that still adds delay.
  ///
  /// Deep lists settle together past this point instead of starting their
  /// tail late, so nothing on screen ever waits noticeably to appear.
  static const entranceMaxStaggerSteps = 5;

  /// Whether motion should be suppressed for accessibility.
  ///
  /// True when the platform asks to remove animations and when accessibility
  /// navigation is on. Every animation the app adds checks this first and
  /// shows its final frame immediately when it is set.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
}
