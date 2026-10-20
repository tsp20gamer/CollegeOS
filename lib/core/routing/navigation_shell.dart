import 'dart:ui' show ImageFilter;

import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/shared/widgets/dock_lottie_icon.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Text scaling ceiling for destination labels.
const double _maxLabelTextScaleFactor = 1.3;

/// Tracking applied to every destination label.
const double _dockLabelLetterSpacing = .1;

/// Corner radius of the dock.
///
/// Large enough that the strip reads as one smooth floating surface, and well
/// clear of a pill radius, which would clamp to half the dock's height.
const double _dockRadius = AppRadius.xl;

/// How far the dock floats from the left and right screen edges.
const double _dockHorizontalMargin = AppSpacing.md;

/// How far the dock floats above the system navigation area.
const double _dockBottomGap = AppSpacing.sm;

/// Blur applied to whatever passes behind the dock.
const double _glassBlurSigma = 24;

/// Blur radius of the one soft shadow that lifts the dock off the page.
const double _dockShadowBlur = 24;

/// Dock fill.
///
/// A light translucency lets the page tint the glass on the dark theme; the
/// light theme needs the opposite, an almost-opaque white that stays legible
/// over a near-white page without turning into a solid bar.
const Color _darkGlassFill = Color(0x14FFFFFF);
const Color _lightGlassFill = Color(0xBFFFFFFF);

/// Hairline rim: a whisper of white over dark glass, of black over light.
const Color _darkGlassRim = Color(0x14FFFFFF);
const Color _lightGlassRim = Color(0x0F000000);

/// The active destination's dot.
const double _dockDotSize = 4;
const double _dockDotHiddenScale = .2;

/// The feature each destination represents, in navigation order.
AppFeature featureForIndex(int index) => AppFeature.values[index];

// ─── Navigation Shell ───────────────────────────────────────────────────────

class NavigationShell extends StatefulWidget {
  const NavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell>
    with SingleTickerProviderStateMixin {
  late final _transition = AnimationController(
    vsync: this,
    duration: AppDurations.fast,
    value: 1,
  );
  late final _slide = Tween<Offset>(
    begin: const Offset(AppMotion.dockPageSlideFraction, 0),
    end: Offset.zero,
  ).chain(CurveTween(curve: AppCurves.standard)).animate(_transition);
  late final _fade = Tween<double>(
    begin: AppMotion.dockPageFadeOutOpacity,
    end: 1.0,
  ).chain(CurveTween(curve: AppCurves.standard)).animate(_transition);

  /// Tracks the dock's visibility for hide-on-scroll.
  final ValueNotifier<bool> _dockVisible = ValueNotifier(true);

  bool get _reduceMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void didUpdateWidget(covariant NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
            widget.navigationShell.currentIndex &&
        !_reduceMotion) {
      _transition.forward(from: 0);
      // Always show dock when switching tabs.
      _dockVisible.value = true;
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    _dockVisible.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_reduceMotion) return false;
    if (notification is UserScrollNotification) {
      switch (notification.direction) {
        case ScrollDirection.forward:
          _dockVisible.value = true;
        case ScrollDirection.reverse:
          _dockVisible.value = false;
        case ScrollDirection.idle:
          break;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Scaffold(
        key: const Key('navigation_shell_scaffold'),
        extendBody: true,
        body: ClipRect(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              key: const Key('dock_page_motion'),
              position: _slide,
              child: RepaintBoundary(child: widget.navigationShell),
            ),
          ),
        ),
        bottomNavigationBar: _AnimatedDockVisibility(
          visible: _dockVisible,
          reduceMotion: _reduceMotion,
          child: CollegeNavigationBar(
            selectedIndex: currentIndex,
            onSelected: _selectDestination,
          ),
        ),
      ),
    );
  }

  void _selectDestination(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

// ─── Dock hide/show on scroll ───────────────────────────────────────────────

class _AnimatedDockVisibility extends StatelessWidget {
  const _AnimatedDockVisibility({
    required this.visible,
    required this.reduceMotion,
    required this.child,
  });

  final ValueNotifier<bool> visible;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, isVisible, child) {
        return AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 1.5),
          duration: reduceMotion ? Duration.zero : AppDurations.slow,
          curve: isVisible ? AppCurves.dockReveal : Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: child!,
          ),
        );
      },
      child: child,
    );
  }
}

// ─── Floating Glass Dock ─────────────────────────────────────────────────

/// The app's floating navigation dock.
///
/// A translucent, blurred strip that hovers above the content instead of being
/// attached to the screen edge. Five equal destinations, always labelled:
/// - the selected destination is a cobalt icon, a cobalt label and a micro dot
/// - the newly selected icon plays its bundled animation once while it pops,
///   lifts and settles; nothing else animates
/// - the page keeps its short translation and fade behind the dock
class CollegeNavigationBar extends StatelessWidget {
  const CollegeNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Each destination carries the animation that stands in for its glyph plus
  // the Material pair kept as the reduced-motion and load-failure fallback.
  //
  // The five animations are one drawn family on a 36 px canvas, but their held
  // frames still draw their subjects at different sizes, so `glyphScale` is
  // measured per animation until every subject covers the same 19 px inside
  // the 24 px slot — one visual weight across the row. Their first frame is
  // deliberately blank — every stroke draws itself in — so `restAt` is the
  // finished frame: an unselected destination is a still, complete icon and
  // choosing it replays the drawing.
  //
  // Every line also carries a soft glow stroke painted at 28 % opacity and
  // roughly twice the stroke's own width. That halo is part of the family's
  // weight: without it (as the calendar was drawn) one glyph reads visibly
  // lighter and smaller than the other four.
  //
  // The artwork is authored in a cyan→cobalt→violet gradient; the dock still
  // flattens it to its single accent with the `srcIn` filter, exactly as it did
  // for the previous set, so five palettes keep speaking one accent in both
  // themes.
  static const destinations =
      <
        ({
          String label,
          IconData icon,
          IconData selectedIcon,
          String lottie,
          double glyphScale,
          double restAt,
          Key key,
        })
      >[
        (
          label: 'Home',
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
          lottie: 'assets/lottie/home.json',
          glyphScale: .98,
          restAt: 1,
          key: Key('nav_home'),
        ),
        (
          label: 'Attendance',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
          lottie: 'assets/lottie/tasks.json',
          glyphScale: .97,
          restAt: 1,
          key: Key('nav_attendance'),
        ),
        (
          label: 'Timetable',
          icon: Icons.calendar_view_week_outlined,
          selectedIcon: Icons.calendar_view_week_rounded,
          lottie: 'assets/lottie/calendar.json',
          glyphScale: 1.05,
          restAt: 1,
          key: Key('nav_timetable'),
        ),
        (
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          lottie: 'assets/lottie/completed.json',
          glyphScale: 1.11,
          restAt: 1,
          key: Key('nav_tasks'),
        ),
        (
          label: 'Notes',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
          lottie: 'assets/lottie/library.json',
          glyphScale: 1.13,
          restAt: 1,
          key: Key('nav_notes'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Every feature resolves to the one Electric Cobalt accent; mounting the
    // dock without the app theme still yields the primary colour.
    final accent =
        theme
            .extension<FeatureColors>()
            ?.of(featureForIndex(selectedIndex))
            .accent ??
        theme.colorScheme.primary;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final systemInset = MediaQuery.paddingOf(context).bottom;

    return Semantics(
      container: true,
      label: 'Main navigation',
      child: Padding(
        // The dock floats: it keeps its distance from the screen edges and from
        // the system navigation area rather than sitting flush with either.
        padding: EdgeInsets.fromLTRB(
          _dockHorizontalMargin,
          0,
          _dockHorizontalMargin,
          systemInset + _dockBottomGap,
        ),
        child: DecoratedBox(
          key: const Key('navigation_bar_surface'),
          decoration: BoxDecoration(
            color: isDark ? _darkGlassFill : _lightGlassFill,
            borderRadius: BorderRadius.circular(_dockRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .30 : .08),
                blurRadius: _dockShadowBlur,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // The blur sits inside the rounded clip and the hairline rim is
          // painted on top of it: a border on the outer box would be buried
          // under the blurred layer.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_dockRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _glassBlurSigma,
                sigmaY: _glassBlurSigma,
              ),
              child: DecoratedBox(
                key: const Key('navigation_bar_rim'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_dockRadius),
                  border: Border.all(
                    color: isDark ? _darkGlassRim : _lightGlassRim,
                  ),
                ),
                child: SizedBox(
                  height: AppLayout.navigationBarHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Every destination is stretched to the same slot, so the
                      // labels share one type size measured against the widest
                      // of them instead of each shrinking on its own.
                      final labelFontSize = _sharedLabelFontSize(
                        context: context,
                        style: theme.textTheme.labelMedium ?? const TextStyle(),
                        slotWidth: constraints.maxWidth / destinations.length,
                      );
                      return Row(
                        children: [
                          for (
                            var index = 0;
                            index < destinations.length;
                            index++
                          )
                            Expanded(
                              child: _NavigationDestination(
                                key: destinations[index].key,
                                index: index,
                                label: destinations[index].label,
                                icon: destinations[index].icon,
                                selectedIcon: destinations[index].selectedIcon,
                                lottie: destinations[index].lottie,
                                glyphScale: destinations[index].glyphScale,
                                restAt: destinations[index].restAt,
                                labelFontSize: labelFontSize,
                                selected: selectedIndex == index,
                                reduceMotion: reduceMotion,
                                accent: accent,
                                onTap: () => onSelected(index),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Navigation Destination ──────────────────────────────────────────────

class _NavigationDestination extends StatefulWidget {
  const _NavigationDestination({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.lottie,
    required this.glyphScale,
    required this.restAt,
    required this.labelFontSize,
    required this.selected,
    required this.reduceMotion,
    required this.accent,
    required this.onTap,
    super.key,
  });

  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String lottie;
  final double glyphScale;
  final double restAt;

  /// The one size every dock label is drawn at, shared by all destinations.
  final double labelFontSize;
  final bool selected;
  final bool reduceMotion;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_NavigationDestination> createState() => _NavigationDestinationState();
}

class _NavigationDestinationState extends State<_NavigationDestination>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _popScale;
  late final Animation<double> _popLift;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: AppDurations.dockSelection,
      value: 1.0,
    );

    // 1.0 -> 1.10 -> 1.04 -> 1.0: a small rise and settle, never a bounce.
    _popScale = AppMotion.popScale(_popController);

    _popLift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -AppMotion.dockIconLift,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -AppMotion.dockIconLift,
          end: 0,
        ).chain(CurveTween(curve: AppCurves.standard)),
        weight: 70,
      ),
    ]).animate(_popController);
  }

  @override
  void didUpdateWidget(covariant _NavigationDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only the destination that becomes selected reacts to the tap.
    if (widget.selected && !oldWidget.selected && !widget.reduceMotion) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duration = widget.reduceMotion
        ? Duration.zero
        : AppDurations.dockSelection;

    return IndexedSemantics(
      index: widget.index,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.label,
        child: ExcludeSemantics(
          child: PressScale(
            pressedScale: .94,
            child: InkWell(
              key: ValueKey('dock_tap_${widget.label.toLowerCase()}'),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(_dockRadius),
              splashColor: colors.primary.withValues(alpha: .10),
              highlightColor: Colors.transparent,
              child: SizedBox(
                height: AppLayout.navigationBarHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon: pops and lifts when this destination is chosen.
                    AnimatedBuilder(
                      animation: _popController,
                      builder: (context, child) => Transform.translate(
                        key: ValueKey('dock_icon_lift_${widget.label}'),
                        offset: Offset(0, _popLift.value),
                        child: Transform.scale(
                          key: ValueKey('dock_icon_pop_${widget.label}'),
                          scale: _popScale.value,
                          child: child,
                        ),
                      ),
                      child: _DockIcon(
                        label: widget.label,
                        icon: widget.icon,
                        selectedIcon: widget.selectedIcon,
                        asset: widget.lottie,
                        glyphScale: widget.glyphScale,
                        restAt: widget.restAt,
                        selected: widget.selected,
                        reduceMotion: widget.reduceMotion,
                        duration: duration,
                        accent: widget.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    // Label: keeps its place and gains the accent.
                    _DockLabel(
                      label: widget.label,
                      fontSize: widget.labelFontSize,
                      selected: widget.selected,
                      colors: colors,
                      accent: widget.accent,
                      duration: duration,
                    ),
                    // Active dot.
                    _DockDot(
                      label: widget.label,
                      selected: widget.selected,
                      accent: widget.accent,
                      reduceMotion: widget.reduceMotion,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dock Icon ───────────────────────────────────────────────────────────

class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.asset,
    required this.glyphScale,
    required this.restAt,
    required this.selected,
    required this.reduceMotion,
    required this.duration,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String asset;
  final double glyphScale;
  final double restAt;
  final bool selected;
  final bool reduceMotion;
  final Duration duration;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 1.0,
        end: selected ? AppMotion.dockSelectedIconScale : 1.0,
      ),
      duration: duration,
      curve: AppCurves.standard,
      builder: (context, scale, child) => Transform.scale(
        key: ValueKey('dock_icon_rest_$label'),
        scale: scale,
        child: child,
      ),
      // The bundled animation carries the rest-to-selected change instead of
      // the old outline-to-filled cross-fade: it plays once when the
      // destination is chosen and holds its final frame.
      child: DockLottieIcon(
        asset: asset,
        label: label,
        glyphScale: glyphScale,
        restAt: restAt,
        selected: selected,
        reduceMotion: reduceMotion,
        tint: selected ? accent : colors.onSurfaceVariant,
        fallbackIcon: selected ? selectedIcon : icon,
      ),
    );
  }
}

// ─── Dock Label ──────────────────────────────────────────────────────────

/// The single font size every dock label is drawn at.
///
/// The names run from "Home" to "Attendance" while every slot is the same
/// width, so sizing each label on its own shrinks only the long ones and
/// leaves "Home" visibly larger than "Attendance" — five labels, five
/// apparent sizes, one row. Measuring the widest name once and handing that
/// one size to all five keeps the type identical across the strip, and lets
/// the whole row step down together on a narrow screen or under large text
/// scaling instead of clipping a single name.
///
/// The measurement uses the selected weight, which is the widest the label
/// ever gets, and the same clamped text scaler the labels render with, so no
/// label is ever shrunk on its own and the five never drift apart.
double _sharedLabelFontSize({
  required BuildContext context,
  required TextStyle style,
  required double slotWidth,
}) {
  final base = style.fontSize ?? 12;
  final available = slotWidth - AppSpacing.xxs * 2;
  if (!available.isFinite || available <= 0) return base;

  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textScaler: MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: _maxLabelTextScaleFactor),
  );
  var widest = 0.0;
  for (final destination in CollegeNavigationBar.destinations) {
    painter.text = TextSpan(
      text: destination.label,
      style: style.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: _dockLabelLetterSpacing,
      ),
    );
    painter.layout();
    if (painter.width > widest) widest = painter.width;
  }
  painter.dispose();

  if (widest <= available) return base;
  return base * available / widest;
}

class _DockLabel extends StatelessWidget {
  const _DockLabel({
    required this.label,
    required this.fontSize,
    required this.selected,
    required this.colors,
    required this.accent,
    required this.duration,
  });

  final String label;

  /// Shared with every other destination: one row, one type size.
  final double fontSize;

  final bool selected;
  final ColorScheme colors;
  final Color accent;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = (theme.textTheme.labelMedium ?? const TextStyle())
        .copyWith(
          color: selected ? accent : colors.onSurfaceVariant,
          fontSize: fontSize,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: _dockLabelLetterSpacing,
          height: 1.1,
        );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxLabelTextScaleFactor,
      child: AnimatedOpacity(
        opacity: selected ? 1.0 : .8,
        duration: duration,
        child: AnimatedDefaultTextStyle(
          duration: duration,
          curve: AppCurves.standard,
          style: labelStyle,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Text(
                label,
                key: Key('dock_label_$label'),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Active Dot ──────────────────────────────────────────────────────────

/// The micro dot under the selected destination's label.
///
/// Its slot is reserved whether or not the dot is showing, so choosing a
/// destination never nudges its own label or its neighbours'.
class _DockDot extends StatelessWidget {
  const _DockDot({
    required this.label,
    required this.selected,
    required this.accent,
    required this.reduceMotion,
  });

  final String label;
  final bool selected;
  final Color accent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion ? Duration.zero : AppDurations.dockDot;
    return SizedBox(
      height: _dockDotSize + AppSpacing.xxs,
      width: _dockDotSize,
      child: Center(
        child: AnimatedScale(
          key: Key('dock_dot_scale_$label'),
          scale: selected ? 1.0 : _dockDotHiddenScale,
          duration: duration,
          curve: AppCurves.standard,
          child: AnimatedOpacity(
            key: Key('dock_dot_fade_$label'),
            opacity: selected ? 1.0 : 0.0,
            duration: duration,
            child: DecoratedBox(
              key: Key('dock_dot_$label'),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const SizedBox.square(dimension: _dockDotSize),
            ),
          ),
        ),
      ),
    );
  }
}
