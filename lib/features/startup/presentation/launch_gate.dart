import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/launch_hold.dart';
import '../application/startup_providers.dart';

/// Lets the native launch screen go once the first screen is ready
/// ([startupReadyProvider]: the Quran text read and, when the app opens on
/// the Mushaf, its page drawn), so no loading is ever seen. The hold's own
/// limit lets it go anyway on a slow device. It draws nothing.
class LaunchGate extends ConsumerStatefulWidget {
  /// Creates the gate over [child].
  const LaunchGate({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<LaunchGate> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(startupReadyProvider, (_, ready) {
      // Out of the frame being built: the first frame is scheduled only
      // while the scheduler is idle.
      if (ready) Timer.run(ref.read(launchHoldProvider).release);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
