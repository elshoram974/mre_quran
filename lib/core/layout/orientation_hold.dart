import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shortest side, in logical pixels, of a screen on which the system no
/// longer holds an app the way the app asks.
///
/// iPadOS ignores the orientation asked for by an app that can share the
/// screen with others, as this one can (and every app can from iPadOS 26);
/// every iPad is at least 744 points across. Android 16 ignores it on
/// screens 600 dp across or more for apps that target it, as this one does.
const double orientationHoldMaxShortestSide = 600;

/// Whether the system holds the screen in [context] the way the app asks: on
/// a phone it does; on a tablet, or a phone unfolded to one, the screen turns
/// only with the device, whatever the app asks.
///
/// Judged on the whole screen, not the window: an iPad sharing its screen
/// may give the app a phone-sized window, and still ignores the request.
bool canHoldOrientation(BuildContext context) {
  final window = MediaQuery.sizeOf(context);
  final display = View.of(context).display;
  final screen = display.size / display.devicePixelRatio;
  return (screen.isEmpty ? window : screen).shortestSide <
      orientationHoldMaxShortestSide;
}

/// The app's one voice to the system about how the screen is held.
///
/// More than one part of the app holds the screen (the reader sideways, the
/// Qibla compass upright), each only while it is the page in sight. They all
/// ask here, so one letting go never undoes what another still wants: the
/// system is asked for what the newest holder wants, and for the app's own
/// orientations (an empty list: the Info.plist on iOS, the manifest on
/// Android) when nobody holds anything.
class OrientationHolds {
  /// What each holder wants, the newest last.
  final Map<Object, List<DeviceOrientation>> _wanted = {};

  /// What the system was last asked for. The app starts with its own
  /// orientations, so nothing needs asking until somebody holds the screen.
  List<DeviceOrientation> _asked = const [];

  /// Holds the screen [orientations] for [holder], in place of whatever it
  /// wanted before. An empty list lets go.
  void hold(Object holder, List<DeviceOrientation> orientations) {
    final before = _wanted[holder] ?? const <DeviceOrientation>[];
    if (listEquals(before, orientations)) return;
    _wanted.remove(holder);
    if (orientations.isNotEmpty) _wanted[holder] = orientations;
    final wanted = _wanted.isEmpty
        ? const <DeviceOrientation>[]
        : _wanted.values.last;
    if (listEquals(wanted, _asked)) return;
    _asked = wanted;
    SystemChrome.setPreferredOrientations(wanted);
  }
}

/// Provides the app's [OrientationHolds].
final orientationHoldsProvider = Provider<OrientationHolds>(
  (ref) => OrientationHolds(),
);

/// Holds the screen [orientations] while [child] is the page in sight, and
/// lets go whenever it is not: covered by another page, on a tab out of
/// sight, or gone.
///
/// Being in sight is read from [TickerMode], which the shell turns off for
/// the tabs out of sight and the navigator for a page covered by another. An
/// empty list holds nothing.
class OrientationHoldScope extends ConsumerStatefulWidget {
  /// Creates the scope around [child].
  const OrientationHoldScope({
    super.key,
    required this.orientations,
    required this.child,
  });

  /// How the screen is held while [child] is in sight.
  final List<DeviceOrientation> orientations;

  /// The page.
  final Widget child;

  @override
  ConsumerState<OrientationHoldScope> createState() =>
      _OrientationHoldScopeState();
}

class _OrientationHoldScopeState extends ConsumerState<OrientationHoldScope> {
  /// Kept from the first build: it is needed once more when the scope goes,
  /// and nothing can be read from the providers by then.
  late final OrientationHolds _holds = ref.read(orientationHoldsProvider);

  @override
  void dispose() {
    _holds.hold(this, const []);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inSight = TickerMode.valuesOf(context).enabled;
    _holds.hold(this, inSight ? widget.orientations : const []);
    return widget.child;
  }
}
