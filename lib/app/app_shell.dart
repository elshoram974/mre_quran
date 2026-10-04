import 'package:flutter/material.dart';

import '../core/layout/adaptive_layout.dart';
import '../features/bookmarks/presentation/bookmarks_page.dart';
import '../features/mushaf/presentation/mushaf_page.dart';
import '../features/settings/presentation/settings_controller.dart';
import '../features/settings/presentation/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.settings});
  final SettingsController settings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;
  static const _destinations = [
    (label: 'المصحف', icon: Icons.menu_book_outlined),
    (label: 'العلامات', icon: Icons.bookmark_border),
    (label: 'الإعدادات', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = WindowSize.fromWidth(constraints.maxWidth);
      final compact = size == WindowSize.compact;
      return Scaffold(
        appBar: AppBar(title: Text(_destinations[_selected].label)),
        body: SafeArea(
          child: Row(
            children: [
              if (!compact) ...[
                SingleChildScrollView(
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      extended: size == WindowSize.expanded,
                      selectedIndex: _selected,
                      onDestinationSelected: _select,
                      labelType: size == WindowSize.medium
                          ? NavigationRailLabelType.all
                          : NavigationRailLabelType.none,
                      destinations: [
                        for (final item in _destinations)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: ContentContainer(
                  child: IndexedStack(
                    index: _selected,
                    children: [
                      const MushafPage(),
                      const BookmarksPage(),
                      SettingsPage(controller: widget.settings),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: compact
            ? NavigationBar(
                selectedIndex: _selected,
                onDestinationSelected: _select,
                destinations: [
                  for (final item in _destinations)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                ],
              )
            : null,
      );
    },
  );

  void _select(int index) => setState(() => _selected = index);
}
