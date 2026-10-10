import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';

/// Turns the reader between portrait and landscape with one tap, and back with
/// the next.
///
/// It reads what the screen is doing now rather than remembering its own last
/// tap: a tablet already held wide would otherwise need two taps before
/// anything changed.
class ReaderOrientationToggle extends StatefulWidget {
  /// Creates the toggle.
  const ReaderOrientationToggle({super.key});

  @override
  State<ReaderOrientationToggle> createState() =>
      _ReaderOrientationToggleState();
}

class _ReaderOrientationToggleState extends State<ReaderOrientationToggle> {
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _toggle(bool landscapeNow) =>
      SystemChrome.setPreferredOrientations(
        landscapeNow
            ? const [
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]
            : const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ],
      );

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return IconButton(
      icon: Icon(
        landscape
            ? Icons.stay_current_portrait_rounded
            : Icons.stay_current_landscape_rounded,
      ),
      tooltip: landscape
          ? context.l10n.readerPortrait
          : context.l10n.readerLandscape,
      onPressed: () => _toggle(landscape),
    );
  }
}
