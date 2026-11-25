import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the person asked the reader to be held.
enum ReaderOrientation {
  /// As the device is turned: what the reader does until the person asks.
  free,

  /// Kept upright.
  portrait,

  /// Kept sideways, where a printed page reads bigger.
  landscape,
}

/// How the reader is held, chosen in the display options or from the hint
/// that follows a pinch on a printed page. It lasts while the app runs, and
/// is applied only while the reader is on screen (`ReaderOrientationScope`):
/// the rest of the app always turns as it normally does.
final readerOrientationProvider =
    NotifierProvider<ReaderOrientationNotifier, ReaderOrientation>(
      ReaderOrientationNotifier.new,
    );

/// Owns how the reader is held.
class ReaderOrientationNotifier extends Notifier<ReaderOrientation> {
  @override
  ReaderOrientation build() => ReaderOrientation.free;

  /// Holds the reader [orientation].
  void hold(ReaderOrientation orientation) => state = orientation;
}
