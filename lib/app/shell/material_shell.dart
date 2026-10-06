import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
import '../../core/theme/app_tokens.dart';
import 'shell_destination.dart';

/// Android chrome: Material 3 top app bar, navigation bar, and rail.
class MaterialShell extends StatelessWidget {
  /// Creates the Material shell around [child].
  const MaterialShell({
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
    return Scaffold(
      // The tab bar floats; every page runs under it and keeps clear of it
      // through the bottom padding the Scaffold publishes.
      extendBody: true,
      appBar: showAppBar
          ? AppBar(title: Text(destinations[index].label))
          : null,
      body: compact || !showNavigation
          ? ContentContainer(child: child)
          : Row(
              children: [
                NavigationRail(
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
                Expanded(child: ContentContainer(child: child)),
              ],
            ),
      bottomNavigationBar: compact && showNavigation
          ? _FloatingNavigationBar(
              index: index,
              onSelected: onSelected,
              destinations: destinations,
            )
          : null,
    );
  }
}

/// The Material 3 navigation bar, floating: a rounded, raised pill held off
/// the screen edges and above the system navigation bar. Only the selected
/// destination shows its label.
class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.index,
    required this.onSelected,
    required this.destinations,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final List<ShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard + 4),
    );
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppTokens.floatingBarGap),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppTokens.gutterCompact,
        ),
        child: Material(
          color: scheme.surfaceContainerLowest,
          elevation: 3,
          shadowColor: scheme.shadow.withValues(alpha: 0.4),
          surfaceTintColor: Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: NavigationBar(
              height: AppTokens.floatingBarHeight,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: index,
              onDestinationSelected: onSelected,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
