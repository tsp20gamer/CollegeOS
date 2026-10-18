import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:flutter/material.dart';

/// Reveals [child] once with a short fade and rise as it first appears.
///
/// [index] staggers sections that appear together: every step waits a little
/// longer for its turn, so a screen's cards settle in as a wave instead of
/// fading as one block. The delay stops growing after
/// [AppMotion.entranceMaxStaggerSteps], so no section ever waits noticeably.
///
/// When the platform asks for reduced motion the child is shown at rest
/// immediately and no animation runs.
class Entrance extends StatefulWidget {
  const Entrance({
    required this.child,
    this.index = 0,
    this.rise = AppMotion.entranceRise,
    super.key,
  });

  final Widget child;

  /// Position in the settle wave. Section 0 starts immediately.
  final int index;

  /// How far the child travels up as it settles, in logical pixels.
  final double rise;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final int _steps = widget.index.clamp(
    0,
    AppMotion.entranceMaxStaggerSteps,
  );
  late final Duration _totalDuration =
      AppDurations.entrance + AppDurations.entranceStagger * _steps;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _totalDuration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _steps *
          AppDurations.entranceStagger.inMicroseconds /
          _totalDuration.inMicroseconds,
      1,
      curve: AppCurves.standard,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.translate(
          offset: Offset(0, widget.rise * (1 - _animation.value)),
          child: child,
        ),
      ),
    );
  }
}
