import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../core/l10n/l10n.dart';
import '../core/layout/adaptive_layout.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/app_card.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = WindowSize.fromWidth(constraints.maxWidth);
      final compact = size == WindowSize.compact;
      final destinations = _destinations(context);
      final current = destinations[navigationShell.currentIndex];
      return Material(
        type: MaterialType.transparency,
        child: GlassScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: GlassAppBar(title: Text(current.label)),
          bottomBar: compact
              ? GlassTabBar.bottom(
                  selectedIndex: navigationShell.currentIndex,
                  onTabSelected: _goBranch,
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
          body: _InsetBody(
            compact: compact,
            child: compact
                ? ContentContainer(child: navigationShell)
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
                            selectedIndex: navigationShell.currentIndex,
                            onDestinationSelected: _goBranch,
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
                      Expanded(child: ContentContainer(child: navigationShell)),
                    ],
                  ),
          ),
        ),
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
      _Destination(l10n.reader, Icons.menu_book_outlined, Icons.menu_book),
      _Destination(l10n.bookmarks, Icons.bookmark_border, Icons.bookmark),
      _Destination(l10n.settings, Icons.settings_outlined, Icons.settings),
    ];
  }
}

/// Publishes the floating glass bar heights so pages can pad their content.
class _InsetBody extends StatelessWidget {
  const _InsetBody({required this.compact, required this.child});

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          top: media.padding.top + AppTokens.appBarHeight,
          bottom: media.padding.bottom + (compact ? AppTokens.barClearance : 0),
        ),
      ),
      child: child,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
