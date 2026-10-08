import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/layout/adaptive_layout.dart';
import '../core/theme/app_platform.dart';
import '../features/mushaf/application/reader_immersive_provider.dart';
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
      final reader = AppRoute.tabs[index] == AppRoute.reader;
      final immersive = reader && ref.watch(readerImmersiveProvider);
      final shell = context.isCupertino
          ? GlassShell(
              size: size,
              destinations: destinations,
              index: index,
              onSelected: (index) => _goBranch(ref, index),
              showAppBar: !reader,
              showNavigation: !immersive,
              child: navigationShell,
            )
          : MaterialShell(
              size: size,
              destinations: destinations,
              index: index,
              onSelected: (index) => _goBranch(ref, index),
              showAppBar: !reader,
              showNavigation: !immersive,
              child: navigationShell,
            );

      return PopScope(
        // Sheets and pushed reader routes are above the shell and dismiss
        // normally. At the reader root, back first restores the controls.
        canPop: !immersive,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && immersive) {
            ref.read(readerImmersiveProvider.notifier).exit();
          }
        },
        child: _KeepScreenAwake(enabled: reader, child: shell),
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

class _KeepScreenAwake extends StatefulWidget {
  const _KeepScreenAwake({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends State<_KeepScreenAwake>
    with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _update();
  }

  @override
  void didUpdateWidget(covariant _KeepScreenAwake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  void _update({bool? enabled}) {
    WakelockPlus.toggle(
      enable:
          enabled ??
          (widget.enabled && _lifecycleState == AppLifecycleState.resumed),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
