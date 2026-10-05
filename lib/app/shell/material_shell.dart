import 'package:flutter/material.dart';

import '../../core/layout/adaptive_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    final compact = size == WindowSize.compact;
    return Scaffold(
      appBar: AppBar(title: Text(destinations[index].label)),
      body: compact
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
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: onSelected,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.activeIcon),
                    label: item.label,
                  ),
              ],
            )
          : null,
    );
  }
}
