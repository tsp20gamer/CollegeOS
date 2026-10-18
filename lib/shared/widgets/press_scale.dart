import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A wrapper that shrinks its [child] while the pointer is held down, then
/// springs back with a natural overshoot when released.
///
/// Uses a [SpringSimulation] instead of a canned curve, so the release feels
/// physically motivated rather than robotically timed. The press-down is still
/// a fast ease-out so the visual response is immediate.
///
/// A pointer that slides more than a touch slop releases the press, so starting
/// a scroll from a card or a chip never leaves that card held down while the
/// finger drags: inside a scrollable that touch is a scroll, not a press.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, this.pressedScale = 0.96, super.key});

  final Widget child;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;

  /// Spring that drives the release bounce-back.
  static final _releaseSpring = SpringDescription(
    mass: 1.0,
    stiffness: 500,
    damping: 18,
  );

  /// Duration for the press-down (pointer held).
  static const _pressDuration = Duration(milliseconds: 80);

  bool _pressed = false;

  /// Where the active pointer went down, so a finger that slides away can
  /// release the press instead of holding the child down through a scroll.
  Offset? _downPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1.0);
    _scaleAnimation = AlwaysStoppedAnimation(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    _pressed = pressed;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;

    if (pressed) {
      // Quick ease-out to the pressed scale.
      _scaleAnimation =
          Tween<double>(
            begin: _scaleAnimation.value,
            end: widget.pressedScale,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.duration = _pressDuration;
      _controller.forward(from: 0);
    } else {
      // Spring back from wherever we are to 1.0.
      final sim = SpringSimulation(
        _releaseSpring,
        _scaleAnimation.value, // current
        1.0, // target
        0, // velocity
      );
      // Approximate the spring settling time for the controller duration.
      _controller.duration = Duration(
        milliseconds: (sim.tolerance.distance < 0.001 ? 400 : 350),
      );
      _scaleAnimation = _SpringAnimation(
        parent: _controller,
        spring: _releaseSpring,
        start: _scaleAnimation.value,
        end: 1.0,
      );
      _controller.forward(from: 0);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _setPressed(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final origin = _downPosition;
    if (origin == null) return;
    if ((event.position - origin).distance > kTouchSlop) {
      _releasePress();
    }
  }

  void _releasePress() {
    _downPosition = null;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: (_) => _releasePress(),
      onPointerCancel: (_) => _releasePress(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// An [Animation] that maps controller progress through a [SpringSimulation].
class _SpringAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _SpringAnimation({
    required this.parent,
    required SpringDescription spring,
    required double start,
    required double end,
  }) : _sim = SpringSimulation(spring, start, end, 0);

  @override
  final Animation<double> parent;

  final SpringSimulation _sim;

  @override
  double get value => _sim.x(parent.value);
}
