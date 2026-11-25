/// Whether [trace], the steps the native StartupTrace kept of an earlier
/// launch that never showed its first frame, is a stall worth reporting.
///
/// A trace reads `<os> <version>[ debug] from <source>: step@ms step@ms …`,
/// each time counted from the start of that launch (`onCreate` on Android,
/// `didFinishLaunching` on iOS). It is not reported when:
///
/// - this launch is a debug build ([debugBuild]), or that one was (`debug`
///   before `from`): a debug build starts slowly (its Dart is compiled as it
///   runs), and a debugger ends it whenever the developer stops or reruns it,
///   so its launches say nothing about the app people have;
/// - it showed its first frame after all (`displayed` or `dart:firstFrame`);
/// - the person had it on the launch screen for less than [least] in all
///   (the time until they left it, plus any time after they came back): it
///   was still opening when they went, which the launch hold's own limit
///   allows.
///
/// A launch that ended while it was on the screen (no `pause`, `stop`,
/// `background` or `destroy` after it was last shown) is reported whatever
/// its times: the person cannot leave without one of those, so the app
/// crashed, or the system ended a launch that hung.
bool isLaunchStallWorthReporting(
  String trace, {
  required bool debugBuild,
  required Duration least,
}) {
  if (debugBuild) return false;
  final from = trace.indexOf(' from ');
  final header = from < 0 ? '' : trace.substring(0, from);
  if (header.split(' ').contains('debug')) return false;
  var onScreen = Duration.zero;
  var shownAt = Duration.zero;
  var shown = true; // The launch screen shows from the tap.
  for (final match in _step.allMatches(trace)) {
    final step = match.group(1)!;
    final at = Duration(milliseconds: int.parse(match.group(2)!));
    if (_firstFrame.contains(step)) return false;
    if (shown && _left.contains(step)) {
      shown = false;
      onScreen += at - shownAt;
    } else if (!shown && _back.contains(step)) {
      shown = true;
      shownAt = at;
    }
  }
  return shown || onScreen >= least;
}

/// One step and its milliseconds: `resume@120`, `release:limit@4100`.
final RegExp _step = RegExp(r'(?<=\s)([^\s@]+)@(\d+)(?=\s|$)');

/// The steps that mean the first frame was on the screen.
const Set<String> _firstFrame = {'displayed', 'dart:firstFrame'};

/// The steps that mean the person left (Android's activity, iOS's scene).
const Set<String> _left = {'pause', 'stop', 'background', 'destroy'};

/// The steps that mean the launch screen was shown again.
const Set<String> _back = {'start', 'resume', 'active'};
