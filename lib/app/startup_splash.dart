import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CollegeStartupSplash extends StatefulWidget {
  const CollegeStartupSplash({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<CollegeStartupSplash> createState() => _CollegeStartupSplashState();
}

class _CollegeStartupSplashState extends State<CollegeStartupSplash>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 2700);
  static const _reducedMotionHold = Duration(milliseconds: 350);
  static const _reducedMotionFade = Duration(milliseconds: 250);
  static const _handoffStart = 2200 / 2700;

  static const _background = Color(0xFF03091E);
  static const _referenceWidth = 808.0;
  static const _referenceHeight = 859.0;

  static const _assetRoot = 'assets/splash';
  static const _calendarAsset = '$_assetRoot/collegeos_calendar.png';
  static const _capAsset = '$_assetRoot/collegeos_cap.png';
  static const _checkAsset = '$_assetRoot/collegeos_check.png';
  static const _wordmarkAsset = '$_assetRoot/collegeos_wordmark.png';
  static const _glowAsset = '$_assetRoot/splash_glow.png';
  static const _noiseAsset = '$_assetRoot/subtle_noise.png';
  static const _backgroundAsset = '$_assetRoot/splash_background_1080x1920.png';

  static const _splashAssets = <String>[
    _backgroundAsset,
    _noiseAsset,
    _glowAsset,
    _calendarAsset,
    _capAsset,
    _checkAsset,
    _wordmarkAsset,
  ];

  late final AnimationController _controller;
  late final Animation<double> _calendarOpacity;
  late final Animation<double> _calendarScale;
  late final Animation<double> _capOpacity;
  late final Animation<double> _capOffset;
  late final Animation<double> _checkOpacity;
  late final Animation<double> _checkScale;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _wordmarkOffset;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;
  late final Animation<double> _checkGlowOpacity;
  late final Animation<double> _handoff;
  late final Animation<double> _logoExitScale;

  Timer? _reducedMotionTimer;
  var _prepared = false;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..addStatusListener(_handleAnimationStatus);
    _configureAnimations();
  }

  void _configureAnimations() {
    _calendarOpacity = _curvedTween(
      begin: 0,
      end: 1,
      startMs: 200,
      endMs: 650,
      curve: Curves.easeOutCubic,
    );
    _calendarScale = _curvedTween(
      begin: .78,
      end: 1,
      startMs: 200,
      endMs: 750,
      curve: const Cubic(.18, .89, .32, 1.08),
    );
    _capOpacity = _curvedTween(
      begin: 0,
      end: 1,
      startMs: 550,
      endMs: 980,
      curve: Curves.easeOutCubic,
    );
    _capOffset = _curvedTween(
      begin: -120,
      end: 0,
      startMs: 550,
      endMs: 1100,
      curve: const Cubic(.18, .89, .32, 1.10),
    );
    _checkOpacity = _curvedTween(
      begin: 0,
      end: 1,
      startMs: 950,
      endMs: 1180,
      curve: Curves.easeOutCubic,
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 68,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.18,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 32,
      ),
    ]).animate(_interval(950, 1400));
    _wordmarkOpacity = _curvedTween(
      begin: 0,
      end: 1,
      startMs: 1250,
      endMs: 1800,
      curve: Curves.easeOutCubic,
    );
    _wordmarkOffset = _curvedTween(
      begin: 54,
      end: 0,
      startMs: 1250,
      endMs: 1800,
      curve: Curves.easeOutCubic,
    );
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .15, end: .55), weight: 45),
      TweenSequenceItem(tween: Tween(begin: .55, end: .25), weight: 55),
    ]).animate(_interval(1300, 2100, curve: Curves.easeInOutCubic));
    _glowScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .90, end: 1.08), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 55),
    ]).animate(_interval(1300, 2100, curve: Curves.easeInOutCubic));
    _checkGlowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: .48), weight: 46),
      TweenSequenceItem(tween: Tween(begin: .48, end: 0), weight: 54),
    ]).animate(_interval(950, 1500, curve: Curves.easeInOutCubic));
    _handoff = CurvedAnimation(
      parent: _controller,
      curve: const Interval(_handoffStart, 1, curve: Curves.easeInOutCubic),
    );
    _logoExitScale = Tween(begin: 1.0, end: .96).animate(_handoff);
  }

  Animation<double> _interval(
    int startMs,
    int endMs, {
    Curve curve = Curves.linear,
  }) => CurvedAnimation(
    parent: _controller,
    curve: Interval(startMs / 2700, endMs / 2700, curve: curve),
  );

  Animation<double> _curvedTween({
    required double begin,
    required double end,
    required int startMs,
    required int endMs,
    required Curve curve,
  }) => Tween(
    begin: begin,
    end: end,
  ).animate(_interval(startMs, endMs, curve: curve));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prepared && widget.enabled) {
      _prepared = true;
      unawaited(_prepareAndStart());
    }
  }

  Future<void> _prepareAndStart() async {
    await Future.wait(
      _splashAssets.map(
        (asset) => precacheImage(AssetImage(asset), context).catchError((_) {}),
      ),
    );
    if (!mounted || !widget.enabled) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = _handoffStart;
      _reducedMotionTimer = Timer(_reducedMotionHold, () {
        if (mounted) {
          unawaited(_controller.animateTo(1, duration: _reducedMotionFade));
        }
      });
      return;
    }
    unawaited(_controller.forward());
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _finished = true);
    }
  }

  @override
  void didUpdateWidget(covariant CollegeStartupSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled && !_finished) {
      _reducedMotionTimer?.cancel();
      _controller.stop();
      _finished = true;
    }
  }

  @override
  void dispose() {
    _reducedMotionTimer?.cancel();
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _finished) return widget.child;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            key: const Key('startup_content_fade'),
            opacity: _handoff,
            child: widget.child,
          ),
          FadeTransition(
            key: const Key('startup_splash'),
            opacity: ReverseAnimation(_handoff),
            child: _SplashCanvas(
              calendarOpacity: _calendarOpacity,
              calendarScale: _calendarScale,
              capOpacity: _capOpacity,
              capOffset: _capOffset,
              checkOpacity: _checkOpacity,
              checkScale: _checkScale,
              wordmarkOpacity: _wordmarkOpacity,
              wordmarkOffset: _wordmarkOffset,
              glowOpacity: _glowOpacity,
              glowScale: _glowScale,
              checkGlowOpacity: _checkGlowOpacity,
              logoExitScale: _logoExitScale,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashCanvas extends StatelessWidget {
  const _SplashCanvas({
    required this.calendarOpacity,
    required this.calendarScale,
    required this.capOpacity,
    required this.capOffset,
    required this.checkOpacity,
    required this.checkScale,
    required this.wordmarkOpacity,
    required this.wordmarkOffset,
    required this.glowOpacity,
    required this.glowScale,
    required this.checkGlowOpacity,
    required this.logoExitScale,
  });

  final Animation<double> calendarOpacity;
  final Animation<double> calendarScale;
  final Animation<double> capOpacity;
  final Animation<double> capOffset;
  final Animation<double> checkOpacity;
  final Animation<double> checkScale;
  final Animation<double> wordmarkOpacity;
  final Animation<double> wordmarkOffset;
  final Animation<double> glowOpacity;
  final Animation<double> glowScale;
  final Animation<double> checkGlowOpacity;
  final Animation<double> logoExitScale;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('startup_background'),
      color: _CollegeStartupSplashState._background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _CollegeStartupSplashState._backgroundAsset,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.low,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.08),
                radius: .78,
                colors: [Color(0x55203A7D), Color(0x0003091E)],
                stops: [0, 1],
              ),
            ),
          ),
          Opacity(
            opacity: .045,
            child: Image.asset(
              _CollegeStartupSplashState._noiseAsset,
              fit: BoxFit.none,
              repeat: ImageRepeat.repeat,
              excludeFromSemantics: true,
              filterQuality: FilterQuality.low,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final widthByScreen = constraints.maxWidth * .72;
              final widthByHeight =
                  constraints.maxHeight *
                  .42 *
                  _CollegeStartupSplashState._referenceWidth /
                  _CollegeStartupSplashState._referenceHeight;
              final logoWidth = math.min(
                340.0,
                math.min(widthByScreen, widthByHeight),
              );
              final logoHeight =
                  logoWidth *
                  _CollegeStartupSplashState._referenceHeight /
                  _CollegeStartupSplashState._referenceWidth;

              return Center(
                child: Semantics(
                  label: 'CollegeOS',
                  image: true,
                  child: ScaleTransition(
                    key: const Key('startup_logo'),
                    scale: logoExitScale,
                    child: SizedBox(
                      width: logoWidth,
                      height: logoHeight,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          key: const Key('startup_logo_canvas'),
                          width: _CollegeStartupSplashState._referenceWidth,
                          height: _CollegeStartupSplashState._referenceHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _GlowLayer(
                                opacity: glowOpacity,
                                scale: glowScale,
                              ),
                              _CheckGlowLayer(opacity: checkGlowOpacity),
                              Positioned(
                                left: 173,
                                top: 253,
                                width: 453,
                                height: 421,
                                child: FadeTransition(
                                  key: const Key('startup_calendar'),
                                  opacity: calendarOpacity,
                                  child: ScaleTransition(
                                    scale: calendarScale,
                                    child: _asset(
                                      _CollegeStartupSplashState._calendarAsset,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 134,
                                top: 0,
                                width: 535,
                                height: 332,
                                child: FadeTransition(
                                  key: const Key('startup_cap'),
                                  opacity: capOpacity,
                                  child: AnimatedBuilder(
                                    animation: capOffset,
                                    child: _asset(
                                      _CollegeStartupSplashState._capAsset,
                                    ),
                                    builder: (context, child) =>
                                        Transform.translate(
                                          offset: Offset(0, capOffset.value),
                                          child: child,
                                        ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 412,
                                top: 452,
                                width: 156,
                                height: 139,
                                child: FadeTransition(
                                  key: const Key('startup_check'),
                                  opacity: checkOpacity,
                                  child: ScaleTransition(
                                    scale: checkScale,
                                    child: _asset(
                                      _CollegeStartupSplashState._checkAsset,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 671,
                                width: 808,
                                height: 188,
                                child: FadeTransition(
                                  key: const Key('startup_wordmark'),
                                  opacity: wordmarkOpacity,
                                  child: AnimatedBuilder(
                                    animation: wordmarkOffset,
                                    child: _asset(
                                      _CollegeStartupSplashState._wordmarkAsset,
                                    ),
                                    builder: (context, child) =>
                                        Transform.translate(
                                          offset: Offset(
                                            0,
                                            wordmarkOffset.value,
                                          ),
                                          child: child,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _asset(String path) => Image.asset(
    path,
    fit: BoxFit.fill,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.high,
  );
}

class _GlowLayer extends StatelessWidget {
  const _GlowLayer({required this.opacity, required this.scale});

  final Animation<double> opacity;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 60,
      top: -4,
      width: 684,
      height: 684,
      child: FadeTransition(
        key: const Key('startup_glow'),
        opacity: opacity,
        child: ScaleTransition(
          scale: scale,
          child: Image.asset(
            _CollegeStartupSplashState._glowAsset,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
            filterQuality: FilterQuality.low,
          ),
        ),
      ),
    );
  }
}

class _CheckGlowLayer extends StatelessWidget {
  const _CheckGlowLayer({required this.opacity});

  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 374,
      top: 406,
      width: 232,
      height: 232,
      child: FadeTransition(
        key: const Key('startup_check_glow'),
        opacity: opacity,
        child: Image.asset(
          _CollegeStartupSplashState._glowAsset,
          fit: BoxFit.fill,
          excludeFromSemantics: true,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}
