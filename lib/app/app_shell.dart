import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquidify/liquidify.dart';

import '../core/l10n/l10n.dart';
import '../core/layout/adaptive_layout.dart';

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
        appBar:
            AppBar(
              title: Text(destinations[navigationShell.currentIndex].label),
              scrolledUnderElevation: 0,
            ).liquidGlass(
              options: LiquidGlassOptions.frosted(
                blur: 12,
                interactive: !MediaQuery.disableAnimationsOf(context),
              ),
            ),
        body: SafeArea(
          child: Row(
            children: [
              if (!compact) ...[
                NavigationRail(
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
                ).liquidGlass(
                  options: LiquidGlassOptions.frosted(
                    blur: 12,
                    interactive: !MediaQuery.disableAnimationsOf(context),
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: ContentContainer(child: navigationShell)),
            ],
          ),
        ),
        bottomNavigationBar: compact
            ? NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _goBranch,
                destinations: [
                  for (final item in destinations)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                ],
              ).liquidGlass(
                options: LiquidGlassOptions.frosted(
                  blur: 12,
                  interactive: !MediaQuery.disableAnimationsOf(context),
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
