import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.autoLeading = true,
    this.showSearchAction = false,
    this.showSettingsAction = false,
    this.onSettingsPressed,
    this.onSearchPressed,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  /// Shows a back button whenever this screen was pushed onto a navigator.
  ///
  /// Tab roots and other unpushed screens stay leading-free, so this is only
  /// ever visible on a screen the user can actually return from.
  final bool autoLeading;

  /// Adds a Settings action to the header.
  ///
  /// Settings is not a tab, so every destination that can open it asks for this
  /// and the header is the one place it is guaranteed to be reachable from.
  final bool showSettingsAction;

  /// Overrides what the Settings action does. Defaults to pushing `/settings`.
  final VoidCallback? onSettingsPressed;

  /// Adds the notes/PDF search action to the header, immediately before
  /// Settings.
  ///
  /// Search lives under the Notes branch, so this navigates there instead of
  /// pushing a screen over the shell: the bottom bar stays available, exactly
  /// as it did when this shortcut was a floating button above the bar.
  final bool showSearchAction;

  /// Overrides what the search action does.
  final VoidCallback? onSearchPressed;

  /// The header's right-hand controls: this screen's own actions, then search,
  /// then Settings, which stays far right so it does not move between tabs.
  List<Widget> trailingActions(BuildContext context) => [
    ...actions,
    if (showSearchAction)
      IconButton(
        key: const Key('open_notes_search_button'),
        tooltip: 'Search notes',
        onPressed: onSearchPressed ?? () => context.go(RoutePaths.notesSearch),
        icon: const Icon(Icons.search_rounded),
      ),
    if (showSettingsAction)
      IconButton(
        key: const Key('open_settings_button'),
        tooltip: 'Settings',
        onPressed: onSettingsPressed ?? () => context.push(RoutePaths.settings),
        icon: const Icon(Icons.settings_outlined),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final trailing = trailingActions(context);
    final canPop =
        autoLeading && (Navigator.maybeOf(context)?.canPop() ?? false);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        key: const Key('app_scaffold_safe_area'),
        bottom: false,
        child: CustomScrollView(
          key: PageStorageKey(title),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.contentMaxWidth,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (canPop) ...[
                            const AppBackButton(),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (trailing.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.sm),
                            // A compact phone with a large text scale can need more
                            // width than the header has once a screen adds its own
                            // actions. Wrapping keeps every action tappable and at
                            // full size instead of overflowing the row.
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: trailing,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              key: const Key('app_scaffold_content_padding'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppLayout.scaffoldBottomPadding(context),
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.contentMaxWidth,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The app's single back affordance for pushed screens.
///
/// Screens presented with [AppScaffold] have no `AppBar`, so without this a
/// pushed screen could only be left with the Android system back gesture.
class AppBackButton extends StatelessWidget {
  const AppBackButton({this.onPressed, this.tooltip, super.key});

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('app_back_button'),
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
