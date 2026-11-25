import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_platform.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../application/reader_orientation_provider.dart';

/// Shortest side, in logical pixels, of a screen on which the system no
/// longer turns an app the way the app asks.
///
/// iPadOS ignores the orientation asked for by an app that can share the
/// screen with others, as this one can (and every app can from iPadOS 26);
/// every iPad is at least 744 points across. Android 16 ignores it on
/// screens 600 dp across or more for apps that target it, as this one does.
const double readerTurnMaxShortestSide = 600;

/// Whether the reader in [context] can be turned between portrait and
/// landscape by the app: on a phone it can; on a tablet the system turns it
/// only with the device, whatever the app asks.
///
/// Judged on the whole screen, not the window: an iPad sharing its screen
/// may give the app a phone-sized window, and still ignores the request.
bool readerCanTurn(BuildContext context) {
  final window = MediaQuery.sizeOf(context);
  final display = View.of(context).display;
  final screen = display.size / display.devicePixelRatio;
  return (screen.isEmpty ? window : screen).shortestSide <
      readerTurnMaxShortestSide;
}

/// The orientations to ask the system for while the reader is held
/// [orientation]; on iOS when [cupertino].
///
/// Free is an empty list, which hands the choice back to the app's own (the
/// Info.plist on iOS, the manifest on Android). Upright on iOS asks for
/// portrait only: an iPhone app cannot be upside down (the Info.plist lists
/// no such orientation), and since iOS 16 the engine passes the whole list to
/// the window scene as it is.
List<DeviceOrientation> readerOrientations(
  ReaderOrientation orientation, {
  required bool cupertino,
}) => switch (orientation) {
  ReaderOrientation.free => const [],
  ReaderOrientation.landscape => const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ],
  ReaderOrientation.portrait when cupertino => const [
    DeviceOrientation.portraitUp,
  ],
  ReaderOrientation.portrait => const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ],
};

/// Holds the reader the way the person asked ([readerOrientationProvider])
/// while the reader is on screen, and gives the app back its own
/// orientations whenever it is not.
///
/// The reader is a tab that stays alive behind the others, so leaving it is
/// seen through [TickerMode], which the shell turns off for the tabs out of
/// sight and the navigator for a page covered by another. Where the system
/// ignores what the app asks ([readerCanTurn] is false) nothing is asked.
class ReaderOrientationScope extends ConsumerStatefulWidget {
  /// Creates the scope around the reader [child].
  const ReaderOrientationScope({super.key, required this.child});

  /// The reader.
  final Widget child;

  @override
  ConsumerState<ReaderOrientationScope> createState() =>
      _ReaderOrientationScopeState();
}

class _ReaderOrientationScopeState
    extends ConsumerState<ReaderOrientationScope> {
  /// What the system was last asked for. The app starts with its own
  /// orientations, so nothing needs asking until the person turns the
  /// reader.
  List<DeviceOrientation> _asked = const [];

  void _ask(List<DeviceOrientation> orientations) {
    if (listEquals(orientations, _asked)) return;
    _asked = orientations;
    SystemChrome.setPreferredOrientations(orientations);
  }

  @override
  void dispose() {
    _ask(const []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = ref.watch(readerOrientationProvider);
    final onScreen = TickerMode.valuesOf(context).enabled;
    _ask(
      onScreen && readerCanTurn(context)
          ? readerOrientations(orientation, cupertino: context.isCupertino)
          : const [],
    );
    return widget.child;
  }
}

/// A row that turns the reader between portrait and landscape, with the gap
/// above it; nothing where the reader cannot be turned ([readerCanTurn]),
/// as on a tablet.
///
/// It reads what the screen is doing now rather than remembering its own last
/// tap: a phone already held sideways would otherwise need two taps before
/// anything changed.
class ReaderOrientationTile extends ConsumerWidget {
  /// Creates the row.
  const ReaderOrientationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!readerCanTurn(context)) return const SizedBox.shrink();
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppTokens.spaceMedium),
      child: AppTileCard(
        icon: landscape
            ? Icons.stay_current_portrait_rounded
            : Icons.stay_current_landscape_rounded,
        title: landscape
            ? context.l10n.readerPortrait
            : context.l10n.readerLandscape,
        onTap: () => ref
            .read(readerOrientationProvider.notifier)
            .hold(
              landscape
                  ? ReaderOrientation.portrait
                  : ReaderOrientation.landscape,
            ),
      ),
    );
  }
}
