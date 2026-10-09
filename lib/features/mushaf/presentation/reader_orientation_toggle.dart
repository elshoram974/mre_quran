import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';

/// Lets a reader temporarily choose portrait or landscape reading.
class ReaderOrientationToggle extends StatefulWidget {
  const ReaderOrientationToggle({super.key});

  @override
  State<ReaderOrientationToggle> createState() =>
      _ReaderOrientationToggleState();
}

class _ReaderOrientationToggleState extends State<ReaderOrientationToggle> {
  var _landscape = false;

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _toggle() async {
    final landscape = !_landscape;
    await SystemChrome.setPreferredOrientations(
      landscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
    if (mounted) setState(() => _landscape = landscape);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(
      _landscape
          ? Icons.stay_current_portrait_rounded
          : Icons.stay_current_landscape_rounded,
    ),
    tooltip: _landscape
        ? context.l10n.readerPortrait
        : context.l10n.readerLandscape,
    onPressed: _toggle,
  );
}
