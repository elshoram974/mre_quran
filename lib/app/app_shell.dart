import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';
import '../core/layout/adaptive_layout.dart';
import '../core/widgets/liquid_glass_surface.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = WindowSize.fromWidth(constraints.maxWidth);
      final compact = size == WindowSize.compact;
      final destinations = _destinations(context);
      return Scaffold(
        extendBody: compact,
        appBar: LiquidGlassAppBar(
          appBar: AppBar(
            title: Text(destinations[navigationShell.currentIndex].label),
            scrolledUnderElevation: 0,
          ),
        ),
        body: SafeArea(
          child: Row(
            children: [
              if (!compact) ...[
                LiquidGlassSurface(
                  child: NavigationRail(
                    extended: size == WindowSize.expanded,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _goBranch,
                    labelType: size == WindowSize.medium
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.none,
                    destinations: [
                      for (final item in destinations)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: ContentContainer(child: navigationShell)),
            ],
          ),
        ),
        bottomNavigationBar: compact
            ? LiquidGlassSurface(
                child: NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  destinations: [
                    for (final item in destinations)
                      NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ),
                  ],
                ),
              )
            : null,
      );
    },
  );

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  List<_Destination> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      _Destination(l10n.reader, Icons.menu_book_outlined),
      _Destination(l10n.bookmarks, Icons.bookmark_border),
      _Destination(l10n.settings, Icons.settings_outlined),
    ];
  }
}

class _Destination {
  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}
