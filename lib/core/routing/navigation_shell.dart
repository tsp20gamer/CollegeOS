import 'dart:ui' show ImageFilter;

import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Text scaling ceiling for destination labels.
const double _maxLabelTextScaleFactor = 1.3;

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
/// - the newly selected icon pops, lifts and settles; nothing else animates
/// - the page keeps its short translation and fade behind the dock
class CollegeNavigationBar extends StatelessWidget {
  const CollegeNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const destinations =
      <({String label, IconData icon, IconData selectedIcon, Key key})>[
        (
          label: 'Home',
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
          key: Key('nav_home'),
        ),
        (
          label: 'Attendance',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
          key: Key('nav_attendance'),
        ),
        (
          label: 'Timetable',
          icon: Icons.calendar_view_week_outlined,
          selectedIcon: Icons.calendar_view_week_rounded,
          key: Key('nav_timetable'),
        ),
        (
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          key: Key('nav_tasks'),
        ),
        (
          label: 'Notes',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
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
                  child: Row(
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        Expanded(
                          child: _NavigationDestination(
                            key: destinations[index].key,
                            index: index,
                            label: destinations[index].label,
                            icon: destinations[index].icon,
                            selectedIcon: destinations[index].selectedIcon,
                            selected: selectedIndex == index,
                            reduceMotion: reduceMotion,
                            accent: accent,
                            onTap: () => onSelected(index),
                          ),
                        ),
                    ],
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
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: AppMotion.dockIconPeakScale,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppMotion.dockIconPeakScale,
          end: AppMotion.dockIconPopScale,
        ).chain(CurveTween(curve: AppCurves.standard)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppMotion.dockIconPopScale,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
    ]).animate(_popController);

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
                        selected: widget.selected,
                        duration: duration,
                        accent: widget.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxs),
                    // Label: keeps its place and gains the accent.
                    _DockLabel(
                      label: widget.label,
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
    required this.selected,
    required this.duration,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
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
      // Outline to filled is a short fade and scale, never an instant swap.
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppCurves.standard,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .9, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Icon(
          selected ? selectedIcon : icon,
          key: ValueKey('dock_icon_${label}_$selected'),
          color: selected ? accent : colors.onSurfaceVariant,
          size: AppIconSize.md,
        ),
      ),
    );
  }
}

// ─── Dock Label ──────────────────────────────────────────────────────────

class _DockLabel extends StatelessWidget {
  const _DockLabel({
    required this.label,
    required this.selected,
    required this.colors,
    required this.accent,
    required this.duration,
  });

  final String label;
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
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: .1,
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
