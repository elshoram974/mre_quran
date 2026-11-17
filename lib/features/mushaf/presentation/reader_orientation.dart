import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_tile_card.dart';

/// Holds the reader's orientation lock for as long as the reader is shown,
/// and releases it when the reader goes, so the rest of the app turns freely.
///
/// The lock itself is set by [ReaderOrientationTile], which may live in a
/// short-lived sheet; the lock must outlive that sheet.
class ReaderOrientationScope extends StatefulWidget {
  /// Creates the scope around the reader [child].
  const ReaderOrientationScope({super.key, required this.child});

  /// The reader.
  final Widget child;

  @override
  State<ReaderOrientationScope> createState() => _ReaderOrientationScopeState();
}

class _ReaderOrientationScopeState extends State<ReaderOrientationScope> {
  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A row that turns the reader between portrait and landscape.
///
/// It reads what the screen is doing now rather than remembering its own last
/// tap: a tablet already held wide would otherwise need two taps before
/// anything changed.
class ReaderOrientationTile extends StatelessWidget {
  /// Creates the row.
  const ReaderOrientationTile({super.key});

  static Future<void> _toggle(bool landscapeNow) =>
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
    return AppTileCard(
      icon: landscape
          ? Icons.stay_current_portrait_rounded
          : Icons.stay_current_landscape_rounded,
      title: landscape
          ? context.l10n.readerPortrait
          : context.l10n.readerLandscape,
      onTap: () => _toggle(landscape),
    );
  }
}
