import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/layout/adaptive_layout.dart';
import '../core/theme/app_platform.dart';
import '../features/startup/application/startup_providers.dart';
import 'router.dart';
import 'shell/glass_shell.dart';
import 'shell/material_shell.dart';
import 'shell/shell_destination.dart';

/// Top-level scaffold. Picks native chrome for the current platform.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      final size = WindowSize.fromWidth(constraints.maxWidth);
      final destinations = ShellDestination.of(context);
      final index = navigationShell.currentIndex;
      return context.isCupertino
          ? GlassShell(
              size: size,
              destinations: destinations,
              index: index,
              onSelected: (index) => _goBranch(ref, index),
              child: navigationShell,
            )
          : MaterialShell(
              size: size,
              destinations: destinations,
              index: index,
              onSelected: (index) => _goBranch(ref, index),
              child: navigationShell,
            );
    },
  );

  void _goBranch(WidgetRef ref, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    unawaited(
      ref.read(lastTabRepositoryProvider).save(AppRoute.tabs[index].path),
    );
  }
}
