import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:flutter/material.dart';

/// Gives an icon the dock's rise-and-settle pop.
///
/// The pop lifts the icon to [AppMotion.dockIconPeakScale], passes through
/// [AppMotion.dockIconPopScale] and settles at its resting size — the same
/// motion the dock plays when a destination is chosen, so an icon anywhere in
/// the app reacts to a change with that spring.
///
/// Two ways to hand it a moment:
///
/// * [popOnMount] plays once as the icon first appears. Pass a [fromScale]
///   below 1 so a fresh icon grows into place instead of snapping.
/// * [trigger] replays the pop every time its value changes, so a control can
///   lend the pop to state that changes under it: a task being ticked, an
///   attendance mark being chosen.
///
/// With reduced motion the icon renders at rest and nothing plays.
class IconPop extends StatefulWidget {
  const IconPop({
    required this.child,
    this.trigger = 0,
    this.popOnMount = false,
    this.fromScale = 1,
    super.key,
  });

  final Widget child;

  /// Any change to this value replays the pop.
  final Object? trigger;

  /// Plays the pop once as the icon first appears.
  final bool popOnMount;

  /// Scale the pop starts from.
  ///
  /// Keep at 1 for icons that are already settled and react to a change; pass
  /// a smaller value to grow an icon into its resting size when it appears.
  final double fromScale;

  @override
  State<IconPop> createState() => _IconPopState();
}

class _IconPopState extends State<IconPop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.dockSelection,
    value: 1,
  );
  Animation<double> _scale = const AlwaysStoppedAnimation<double>(1);
  var _mountHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mountHandled) return;
    _mountHandled = true;
    if (widget.popOnMount && !AppMotion.reduceMotion(context)) {
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant IconPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        !AppMotion.reduceMotion(context)) {
      _play();
    }
  }

  void _play() {
    _scale = AppMotion.popScale(_controller, begin: widget.fromScale);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) =>
          Transform.scale(scale: _scale.value, child: child),
    );
  }
}
