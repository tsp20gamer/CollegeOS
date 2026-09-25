import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/shared/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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

  late final _dockScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]).animate(_transition);

  @override
  void didUpdateWidget(covariant NavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
            widget.navigationShell.currentIndex &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context)) {
      _transition.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('navigation_shell_scaffold'),
      extendBody: true,
      body: Stack(
        key: const Key('navigation_shell_overlay'),
        children: [
          Positioned.fill(
            child: ClipRect(
              child: SlideTransition(
                key: const Key('dock_page_motion'),
                position: _slide,
                child: RepaintBoundary(child: widget.navigationShell),
              ),
            ),
          ),
          Positioned(
            key: const Key('floating_navigation_dock'),
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.sm,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: SizedBox(
                height: AppLayout.dockHeight,
                child: ScaleTransition(
                  scale: _dockScale,
                  alignment: Alignment.bottomCenter,
                  child: CollegeNavigationDock(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onSelected: _selectDestination,
                  ),
                ),
              ),
            ),
          ),
        ],
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

class CollegeNavigationDock extends StatelessWidget {
  const CollegeNavigationDock({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _collapsedWidth = 48.0;
  static const _pillHeight = 52.0;
  static const _defaultGap = 6.0;
  static const _minGap = 4.0;

  static const destinations =
      <
        ({
          String label,
          IconData icon,
          IconData selectedIcon,
          double width,
          Key key,
        })
      >[
        (
          label: 'Home',
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
          width: 86,
          key: Key('nav_home'),
        ),
        (
          label: 'Attendance',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check_rounded,
          width: 116,
          key: Key('nav_attendance'),
        ),
        (
          label: 'Timetable',
          icon: Icons.calendar_view_week_outlined,
          selectedIcon: Icons.calendar_view_week_rounded,
          width: 112,
          key: Key('nav_timetable'),
        ),
        (
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          width: 86,
          key: Key('nav_tasks'),
        ),
        (
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          width: 104,
          key: Key('nav_settings'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        key: const ValueKey('college-navigation-dock'),
        height: AppLayout.dockHeight,
        width: double.infinity,
        child: Align(
          alignment: Alignment.center,
          child: GestureDetector(
            key: const Key('dock_gap_shield'),
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: LayoutBuilder(
              builder: (context, constraints) {
                var gap = _defaultGap;
                const widestPill = 116.0;
                final roomyGap =
                    (constraints.maxWidth -
                        widestPill -
                        _collapsedWidth * (destinations.length - 1)) /
                    (destinations.length - 1);
                gap = roomyGap.clamp(_minGap, _defaultGap);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (
                      var index = 0;
                      index < destinations.length;
                      index++
                    ) ...[
                      _DockPill(
                        key: destinations[index].key,
                        label: destinations[index].label,
                        icon: destinations[index].icon,
                        selectedIcon: destinations[index].selectedIcon,
                        selectedWidth: destinations[index].width,
                        selected: selectedIndex == index,
                        onTap: () => onSelected(index),
                      ),
                      if (index < destinations.length - 1) SizedBox(width: gap),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DockPill extends StatelessWidget {
  const _DockPill({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selectedWidth,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final double selectedWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.fast;
    final slug = label.toLowerCase();

    return Semantics(
      button: true,
      selected: selected,
      label: '$label tab',
      child: ExcludeSemantics(
        child: PressScale(
          pressedScale: 0.96,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('dock_tap_$slug'),
              onTap: () {
                if (!selected) {
                  HapticFeedback.selectionClick();
                }
                onTap();
              },
              borderRadius: BorderRadius.circular(selected ? 19 : 16),
              splashColor: colors.primary.withValues(alpha: 0.10),
              highlightColor: isDark
                  ? Colors.white.withValues(alpha: 0.035)
                  : Colors.black.withValues(alpha: 0.04),
              child: AnimatedContainer(
                duration: duration,
                curve: AppCurves.standard,
                width: selected
                    ? selectedWidth
                    : CollegeNavigationDock._collapsedWidth,
                height: CollegeNavigationDock._pillHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: selected
                        ? [
                            isDark
                                ? const Color(0xF222242C)
                                : Colors.white.withValues(alpha: 0.95),
                            colors.primary.withValues(
                              alpha: isDark ? 0.17 : 0.12,
                            ),
                          ]
                        : isDark
                        ? const [Color(0xE617181E), Color(0xD90B0C10)]
                        : [
                            Colors.white.withValues(alpha: 0.90),
                            colors.surfaceContainerLow.withValues(alpha: 0.90),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(selected ? 19 : 16),
                  border: Border.all(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.44)
                        : isDark
                        ? Colors.white.withValues(alpha: 0.09)
                        : colors.outlineVariant.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.42),
                      blurRadius: selected ? 18 : 14,
                      offset: const Offset(0, 7),
                    ),
                    if (selected)
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.13),
                        blurRadius: 14,
                      ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: OverflowBox(
                  minWidth: selectedWidth,
                  maxWidth: selectedWidth,
                  minHeight: CollegeNavigationDock._pillHeight,
                  maxHeight: CollegeNavigationDock._pillHeight,
                  child: AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: AppCurves.standard,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.96,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                    ),
                    child: selected
                        ? Padding(
                            key: const ValueKey('selected'),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selectedIcon,
                                  key: ValueKey('dock_icon_${label}_true'),
                                  color: colors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 7),
                                Flexible(
                                  child: Text(
                                    label,
                                    key: Key('dock_label_$label'),
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.1,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            key: const ValueKey('inactive'),
                            child: Tooltip(
                              message: label,
                              child: Icon(
                                icon,
                                key: ValueKey('dock_icon_${label}_false'),
                                color: colors.onSurfaceVariant,
                                size: 23,
                              ),
                            ),
                          ),
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
