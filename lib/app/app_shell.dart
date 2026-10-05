import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/adaptive_layout.dart';
import '../core/theme/app_platform.dart';
import 'shell/glass_shell.dart';
import 'shell/material_shell.dart';
import 'shell/shell_destination.dart';

/// Top-level scaffold. Picks native chrome for the current platform.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = WindowSize.fromWidth(constraints.maxWidth);
      final destinations = ShellDestination.of(context);
      final index = navigationShell.currentIndex;
      return context.isCupertino
          ? GlassShell(
              size: size,
              destinations: destinations,
              index: index,
              onSelected: _goBranch,
              child: navigationShell,
            )
          : MaterialShell(
              size: size,
              destinations: destinations,
              index: index,
              onSelected: _goBranch,
              child: navigationShell,
            );
    },
  );

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}
