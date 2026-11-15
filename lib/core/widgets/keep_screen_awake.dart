import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while this widget is shown and [enabled], and the app
/// is in the foreground: while reading, or counting adhkar.
///
/// Several can be on screen at once (the reader under an adhkar sheet), so
/// the wakelock is held while any one of them wants it and released only when
/// the last lets go.
class KeepScreenAwake extends StatefulWidget {
  /// Creates the guard around [child].
  const KeepScreenAwake({super.key, this.enabled = true, required this.child});

  /// Whether this part of the app wants the screen kept on.
  final bool enabled;

  /// The content.
  final Widget child;

  /// The instances that currently want the screen on.
  static final Set<Object> _holders = {};

  static void _set(Object holder, {required bool wanted}) {
    final before = _holders.isNotEmpty;
    wanted ? _holders.add(holder) : _holders.remove(holder);
    final after = _holders.isNotEmpty;
    if (before != after) WakelockPlus.toggle(enable: after);
  }

  @override
  State<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends State<KeepScreenAwake>
    with WidgetsBindingObserver {
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _update();
  }

  @override
  void didUpdateWidget(covariant KeepScreenAwake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _update();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    KeepScreenAwake._set(this, wanted: false);
    super.dispose();
  }

  void _update() => KeepScreenAwake._set(
    this,
    wanted: widget.enabled && _lifecycle == AppLifecycleState.resumed,
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
