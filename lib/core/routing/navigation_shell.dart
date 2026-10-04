import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/animation_tokens.dart';
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

const double _indicatorInset = 6;

/// Corner radius of the selected-destination pill.
///
/// A pill-sized radius clamps to half the indicator's *shortest* side, and a
/// destination slot in a five-tab bar is narrower than the bar is tall, so
/// [AppRadius.pill] paints an ellipse rather than a capsule. A soft rounded
/// rectangle fills the slot instead and reads the same at every destination.
const double _indicatorRadius = AppRadius.lg;

// ─── Navigation Shell ───────────────────────────────────────────────────────

class NavigationShell extends StatefulWidget {
  const NavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const searchShortcutBranches = <int>{0, 3};

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
        floatingActionButton:
            NavigationShell.searchShortcutBranches.contains(currentIndex)
            ? FloatingActionButton.small(
                key: const Key('search_notes_fab'),
                tooltip: 'Search notes',
                onPressed: _openNotesSearch,
                child: const Icon(Icons.search_rounded),
              )
            : null,
      ),
    );
  }

  void _selectDestination(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _openNotesSearch() {
    context.go(RoutePaths.notesSearch);
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

// ─── Floating Navigation Bar ────────────────────────────────────────────────

/// The app's floating bottom navigation dock.
///
/// A rounded, translucent pill that floats above the content with a
/// glassmorphism backdrop blur. Features:
/// - Spring-driven elastic indicator that stretches while moving
/// - Icon bounce animation on tap
/// - Label slides up when selected
/// - Glow pulse on indicator landing
/// - Hides on scroll-down, reappears on scroll-up
class CollegeNavigationBar extends StatefulWidget {
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
  State<CollegeNavigationBar> createState() => _CollegeNavigationBarState();
}

class _CollegeNavigationBarState extends State<CollegeNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indicatorController;
  late Animation<double> _indicatorPosition; // 0..1 across tabs
  late Animation<double> _indicatorStretch; // 1.0 = normal, >1 = stretched

  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _indicatorController = AnimationController(
      vsync: this,
      duration: AppDurations.dockSpring,
    )..value = 1.0;
    _buildIndicatorAnimations(widget.selectedIndex, widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant CollegeNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _buildIndicatorAnimations(_previousIndex, widget.selectedIndex);
      _indicatorController.forward(from: 0);
    }
  }

  void _buildIndicatorAnimations(int from, int to) {
    final count = CollegeNavigationBar.destinations.length;
    final fromPos = from / count;
    final toPos = to / count;

    _indicatorPosition = Tween<double>(begin: fromPos, end: toPos).animate(
      CurvedAnimation(
        parent: _indicatorController,
        curve: AppCurves.dockSpring,
      ),
    );

    // Stretch: ramp up to peak in the middle of the animation, then settle.
    _indicatorStretch = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: AppMotion.dockIndicatorStretchFactor,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppMotion.dockIndicatorStretchFactor,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: AppCurves.dockBounce)),
        weight: 30,
      ),
    ]).animate(_indicatorController);
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final systemInset = MediaQuery.paddingOf(context).bottom;

    return Semantics(
      container: true,
      label: 'Main navigation',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xs,
          0,
          AppSpacing.xs,
          systemInset + AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Material(
              type: MaterialType.transparency,
              child: DecoratedBox(
                key: const Key('navigation_bar_surface'),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: .08)
                      : Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: .12)
                        : Colors.black.withValues(alpha: .08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? .32 : .10),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: AppLayout.navigationBarHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final count = CollegeNavigationBar.destinations.length;
                      final slotWidth = constraints.maxWidth / count;
                      final indicatorBaseWidth =
                          slotWidth - _indicatorInset * 2;

                      return Stack(
                        children: [
                          // ─ Elastic indicator ─
                          if (!reduceMotion)
                            AnimatedBuilder(
                              animation: _indicatorController,
                              builder: (context, child) {
                                final pos = _indicatorPosition.value;
                                final stretch = _indicatorStretch.value;
                                final left =
                                    pos * constraints.maxWidth +
                                    _indicatorInset;
                                final width = math.max(
                                  0.0,
                                  indicatorBaseWidth * stretch,
                                );
                                // Center the stretched indicator on the slot.
                                final centeredLeft =
                                    left - (width - indicatorBaseWidth) / 2;

                                return Positioned(
                                  left: centeredLeft.clamp(
                                    _indicatorInset,
                                    constraints.maxWidth -
                                        width -
                                        _indicatorInset,
                                  ),
                                  top: 0,
                                  width: width,
                                  height: AppLayout.navigationBarHeight,
                                  child: _IndicatorPill(
                                    key: const Key('navigation_bar_indicator'),
                                    colors: colors,
                                    isDark: isDark,
                                    glowProgress: _indicatorController.value,
                                  ),
                                );
                              },
                            )
                          else
                            Positioned(
                              left:
                                  widget.selectedIndex * slotWidth +
                                  _indicatorInset,
                              top: 0,
                              width: math.max(0.0, indicatorBaseWidth),
                              height: AppLayout.navigationBarHeight,
                              child: _IndicatorPill(
                                key: const Key('navigation_bar_indicator'),
                                colors: colors,
                                isDark: isDark,
                                glowProgress: 1.0,
                              ),
                            ),

                          // ─ Destinations ─
                          Row(
                            children: [
                              for (var index = 0; index < count; index++)
                                Expanded(
                                  child: _NavigationDestination(
                                    key: CollegeNavigationBar
                                        .destinations[index]
                                        .key,
                                    index: index,
                                    label: CollegeNavigationBar
                                        .destinations[index]
                                        .label,
                                    icon: CollegeNavigationBar
                                        .destinations[index]
                                        .icon,
                                    selectedIcon: CollegeNavigationBar
                                        .destinations[index]
                                        .selectedIcon,
                                    selected: widget.selectedIndex == index,
                                    reduceMotion: reduceMotion,
                                    onTap: () => widget.onSelected(index),
                                  ),
                                ),
                            ],
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

// ─── Indicator Pill ─────────────────────────────────────────────────────────

class _IndicatorPill extends StatelessWidget {
  const _IndicatorPill({
    required this.colors,
    required this.isDark,
    required this.glowProgress,
    super.key,
  });

  final ColorScheme colors;
  final bool isDark;
  final double glowProgress;

  @override
  Widget build(BuildContext context) {
    // Glow: brightest at start of move (progress=0), fades as it settles.
    final glowAlpha = (1 - glowProgress).clamp(0.0, 1.0) * 0.18;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: (isDark ? .32 : .22) + glowAlpha),
            colors.primary.withValues(
              alpha: (isDark ? .18 : .12) + glowAlpha * 0.5,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(_indicatorRadius),
        border: Border.all(color: colors.primary.withValues(alpha: .42)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: glowAlpha * 2.5),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
    );
  }
}

// ─── Navigation Destination ─────────────────────────────────────────────────

class _NavigationDestination extends StatefulWidget {
  const _NavigationDestination({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
    super.key,
  });

  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  State<_NavigationDestination> createState() => _NavigationDestinationState();
}

class _NavigationDestinationState extends State<_NavigationDestination>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceOffset;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: AppDurations.dockBounce,
    );

    // Bounce: no vertical offset, just a gentle scale pulse.
    _bounceOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: AppMotion.dockBounceOffset,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: AppMotion.dockBounceOffset,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
    ]).animate(_bounceController);

    // Scale: gentle squeeze-and-release pulse, no overshoot.
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.95,
          end: 1.04,
        ).chain(CurveTween(curve: AppCurves.standard)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.04,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant _NavigationDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bounce the icon when this destination becomes selected.
    if (widget.selected && !oldWidget.selected && !widget.reduceMotion) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final duration = widget.reduceMotion
        ? Duration.zero
        : AppDurations.dockSpring;

    return IndexedSemantics(
      index: widget.index,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.label,
        child: ExcludeSemantics(
          child: PressScale(
            pressedScale: .92,
            child: InkWell(
              key: ValueKey('dock_tap_${widget.label.toLowerCase()}'),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(_indicatorRadius),
              splashColor: colors.primary.withValues(alpha: .10),
              highlightColor: Colors.transparent,
              child: SizedBox(
                height: AppLayout.navigationBarHeight,
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceOffset.value),
                      child: Transform.scale(
                        scale: _bounceScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ─ Icon with morph ─
                      _DockIcon(
                        label: widget.label,
                        icon: widget.icon,
                        selectedIcon: widget.selectedIcon,
                        selected: widget.selected,
                        duration: duration,
                        colors: colors,
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      // ─ Label slides up when selected ─
                      _DockLabel(
                        label: widget.label,
                        selected: widget.selected,
                        colors: colors,
                        reduceMotion: widget.reduceMotion,
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

// ─── Dock Icon ──────────────────────────────────────────────────────────────

class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.duration,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Duration duration;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: selected ? 1.0 : AppMotion.dockSelectedIconScale,
        end: selected ? AppMotion.dockSelectedIconScale : 1.0,
      ),
      duration: duration,
      curve: AppCurves.dockSpring,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: duration.inMilliseconds ~/ 2),
        switchInCurve: AppCurves.standard,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Icon(
          selected ? selectedIcon : icon,
          key: ValueKey('dock_icon_${label}_$selected'),
          color: selected ? colors.primary : colors.onSurfaceVariant,
          size: AppIconSize.md,
        ),
      ),
    );
  }
}

// ─── Dock Label ─────────────────────────────────────────────────────────────

class _DockLabel extends StatelessWidget {
  const _DockLabel({
    required this.label,
    required this.selected,
    required this.colors,
    required this.reduceMotion,
  });

  final String label;
  final bool selected;
  final ColorScheme colors;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.dockLabel;
    final labelStyle = (theme.textTheme.labelMedium ?? const TextStyle())
        .copyWith(
          color: selected ? colors.onSurface : colors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: .1,
          height: 1.1,
        );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxLabelTextScaleFactor,
      child: AnimatedSlide(
        offset: selected ? Offset.zero : const Offset(0, 0.15),
        duration: duration,
        curve: AppCurves.standard,
        child: AnimatedOpacity(
          opacity: selected ? 1.0 : 0.7,
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
      ),
    );
  }
}
