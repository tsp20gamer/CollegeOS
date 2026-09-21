import 'package:college_os/core/theme/animation_tokens.dart';
import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:flutter/material.dart';
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
                child: CollegeNavigationDock(
                  selectedIndex: widget.navigationShell.currentIndex,
                  onSelected: _selectDestination,
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
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          key: Key('nav_settings'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? .22 : .09),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              key: const Key('navigation_glass_surface'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          colors.surfaceContainerHigh.withValues(alpha: .78),
                          colors.surfaceContainerLowest.withValues(alpha: .70),
                        ]
                      : [
                          Colors.white.withValues(alpha: .70),
                          colors.surfaceContainerLowest.withValues(alpha: .64),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: .22)
                      : Colors.white.withValues(alpha: .70),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Row(
                children: [
                  for (final (index, destination) in destinations.indexed)
                    Expanded(
                      child: _DockDestination(
                        key: destination.key,
                        label: destination.label,
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        selected: selectedIndex == index,
                        onTap: () => onSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockDestination extends StatelessWidget {
  const _DockDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.medium;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: AnimatedContainer(
              duration: duration,
              curve: AppCurves.standard,
              constraints: const BoxConstraints(minHeight: 52),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.xxs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: selected ? 1 : 0),
                    duration: duration,
                    curve: AppCurves.emphasized,
                    builder: (context, progress, child) {
                      final emphasizedColor = Color.lerp(
                        colors.onSurfaceVariant,
                        Colors.white,
                        progress,
                      )!;
                      return Transform.translate(
                        offset: Offset(0, -.75 * progress),
                        child: Center(
                          child: SizedBox.square(
                            key: Key('dock_selection_surface_$label'),
                            dimension: 46,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: progress == 0
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.blue.withValues(
                                            alpha: .92 * progress,
                                          ),
                                          AppColors.violet.withValues(
                                            alpha: .88 * progress,
                                          ),
                                        ],
                                      ),
                                border: progress == 0
                                    ? null
                                    : Border.all(
                                        color: Colors.white.withValues(
                                          alpha: .30 * progress,
                                        ),
                                      ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Transform.scale(
                                  key: Key('dock_icon_scale_$label'),
                                  scale:
                                      1 +
                                      ((AppMotion.dockSelectedIconScale - 1) *
                                          progress),
                                  child: AnimatedSwitcher(
                                    duration: duration,
                                    switchInCurve: AppCurves.standard,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                    child: Icon(
                                      selected ? selectedIcon : icon,
                                      key: ValueKey(
                                        'dock_icon_${label}_$selected',
                                      ),
                                      size: 22,
                                      color: emphasizedColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: AppLayout.dockLabelHeight,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: duration,
                      child: ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            selected ? label : '',
                            key: Key('dock_label_$label'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
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
    );
  }
}
