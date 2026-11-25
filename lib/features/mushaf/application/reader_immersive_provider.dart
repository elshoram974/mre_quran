import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Mushaf is shown without bars. A tap on the page toggles it,
/// and turning a page hides the bars again, as in a printed-Mushaf app.
final readerImmersiveProvider = NotifierProvider<ReaderImmersiveNotifier, bool>(
  ReaderImmersiveNotifier.new,
);

/// Owns the immersive reading flag.
class ReaderImmersiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Shows or hides the bars.
  void toggle() {
    state = !state;
    if (state) ref.read(readerScrubberProvider.notifier).close();
  }

  /// Shows the bars again.
  void exit() => state = false;

  /// Hides the bars, and the page scrubber with them.
  void hide() {
    state = true;
    ref.read(readerScrubberProvider.notifier).close();
  }
}

/// Whether the page scrubber is open in place of the page pill. A tap on the
/// page, or back, closes it before anything else; the bars going away close
/// it too.
final readerScrubberProvider = NotifierProvider<ReaderScrubberNotifier, bool>(
  ReaderScrubberNotifier.new,
);

/// Owns whether the page scrubber is open.
class ReaderScrubberNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Opens the scrubber.
  void open() => state = true;

  /// Closes the scrubber.
  void close() => state = false;
}
