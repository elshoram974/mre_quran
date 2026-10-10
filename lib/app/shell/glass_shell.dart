import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_page_scaffold.dart';
import 'shell_destination.dart';

/// iOS chrome: liquid glass app bar and floating glass tab bar or rail.
class GlassShell extends StatelessWidget {
  /// Creates the glass shell around [child].
  const GlassShell({
    super.key,
    required this.size,
    required this.destinations,
    required this.index,
    required this.onSelected,
    required this.child,
    this.showAppBar = true,
    this.showNavigation = true,
  });

  /// Current window size class.
  final WindowSize size;

  /// Destinations to show.
  final List<ShellDestination> destinations;

  /// Selected destination index.
  final int index;

  /// Called when a destination is chosen.
  final ValueChanged<int> onSelected;

  /// Page content.
  final Widget child;

  /// Whether the shell draws its own app bar. The Mushaf tab draws its own.
  final bool showAppBar;

  /// Whether the tab bar or rail is shown. False in immersive reading.
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final bottomBar = size.usesBottomBar;
    final extended =
        MediaQuery.sizeOf(context).width >=
        ShellNavigation.extendedRailMinWidth;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: GlassScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: showAppBar
            ? GlassAppBar(title: Text(destinations[index].label))
            : null,
        bottomBar: bottomBar && showNavigation
            ? _CenteredBar(
                child: GlassTabBar.bottom(
                  selectedIndex: index,
                  onTabSelected: onSelected,
                  quality: GlassQuality.premium,
                  selectedIconColor: scheme.primary,
                  selectedLabelColor: scheme.primary,
                  unselectedIconColor: scheme.onSurfaceVariant,
                  unselectedLabelColor: scheme.onSurfaceVariant,
                  tabs: [
                    for (final item in destinations)
                      GlassTab(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.activeIcon),
                        label: item.label,
                      ),
                  ],
                ),
              )
            : null,
        body: GlassInsetBody(
          compact: bottomBar && showNavigation,
          hasAppBar: showAppBar,
          child: bottomBar || !showNavigation
              ? ContentContainer(child: child)
              : Row(
                  children: [
                    Padding(
                      // The shell already publishes the bar and system insets
                      // through MediaQuery, so the rail follows them instead of
                      // guessing a height.
                      padding: EdgeInsetsDirectional.fromSTEB(
                        12,
                        MediaQuery.paddingOf(context).top + 12,
                        0,
                        MediaQuery.paddingOf(context).bottom + 12,
                      ),
                      child: AppCard(
                        child: NavigationRail(
                          extended: extended,
                          selectedIndex: index,
                          onDestinationSelected: onSelected,
                          labelType: extended
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.all,
                          destinations: [
                            for (final item in destinations)
                              NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.activeIcon),
                                label: Text(item.label),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: ContentContainer(child: child)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Keeps a floating bar a thumb's reach wide on a tablet instead of stretching
/// it across the whole window. It reports the bar's own height, which the glass
/// scaffold reads to keep the page clear of it.
class _CenteredBar extends StatelessWidget implements PreferredSizeWidget {
  const _CenteredBar({required this.child});

  final GlassTabBar child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ShellNavigation.bottomBarMaxWidth,
      ),
      child: child,
    ),
  );
}
