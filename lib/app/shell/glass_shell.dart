import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/theme/app_tokens.dart';
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
    final compact = size == WindowSize.compact;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: GlassScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: showAppBar
            ? GlassAppBar(title: Text(destinations[index].label))
            : null,
        bottomBar: compact && showNavigation
            ? GlassTabBar.bottom(
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
              )
            : null,
        body: GlassInsetBody(
          compact: compact && showNavigation,
          hasAppBar: showAppBar,
          child: compact || !showNavigation
              ? ContentContainer(child: child)
              : Row(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        AppTokens.appBarHeight + 48,
                        0,
                        12,
                      ),
                      child: AppCard(
                        child: NavigationRail(
                          extended: size == WindowSize.expanded,
                          selectedIndex: index,
                          onDestinationSelected: onSelected,
                          labelType: size == WindowSize.medium
                              ? NavigationRailLabelType.all
                              : NavigationRailLabelType.none,
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
