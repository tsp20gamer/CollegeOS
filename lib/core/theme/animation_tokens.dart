import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);

  /// Duration for the dock indicator's spring-driven slide.
  ///
  /// Slightly longer than [medium] so the overshoot has room to settle,
  /// but the perceived speed is faster because the spring reaches 90 %
  /// of the target in about 180 ms.
  static const dockSpring = Duration(milliseconds: 500);

  /// Duration for the icon bounce after a dock tap.
  static const dockBounce = Duration(milliseconds: 450);

  /// Duration for the label slide up/down.
  static const dockLabel = Duration(milliseconds: 300);
}

abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;

  /// A spring curve for the dock indicator and similar bouncy motions.
  ///
  /// The parameters give a visible overshoot (~8 %) that settles quickly,
  /// which reads as responsive without feeling jittery.
  static const dockSpring = _SpringCurve(
    mass: 1.0,
    stiffness: 280,
    damping: 18,
  );

  /// A snappier spring for the icon bounce.
  static const dockBounce = _SpringCurve(
    mass: 0.8,
    stiffness: 400,
    damping: 12,
  );

  /// A gentle deceleration for the dock hide/show.
  static const dockReveal = Curves.easeOutQuart;
}

abstract final class AppMotion {
  static const pageSlideDistance = 14.0;
  static const routeSlideFraction = 0.035;
  static const routeStartScale = 0.985;

  /// How much the selected icon scales up.
  static const dockSelectedIconScale = 1.08;

  /// How far the icon bounces up (in logical pixels) when tapped.
  /// Set to 0 to disable vertical bounce (scale-only transition).
  static const dockBounceOffset = 0.0;

  /// Fraction of horizontal slide for page transition on tab switch.
  static const dockPageSlideFraction = .018;

  /// Opacity the outgoing page fades to during a tab switch.
  static const dockPageFadeOutOpacity = 0.6;

  /// How much the indicator stretches wider while moving between tabs.
  static const dockIndicatorStretchFactor = 1.15;
}

/// A [Curve] backed by a [SpringSimulation] for physically motivated motion.
///
/// Unlike the canned cubic curves, a spring gives a natural overshoot that
/// settles precisely at the target, producing the "snappy dock" feel without
/// requiring manual keyframe tuning.
class _SpringCurve extends Curve {
  const _SpringCurve({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });

  final double mass;
  final double stiffness;
  final double damping;

  @override
  double transformInternal(double t) {
    final sim = SpringSimulation(
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping),
      0, // start
      1, // end
      0, // initial velocity
    );
    return sim.x(t);
  }
}
