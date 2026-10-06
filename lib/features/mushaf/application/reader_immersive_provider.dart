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
  void toggle() => state = !state;

  /// Shows the bars again.
  void exit() => state = false;

  /// Hides the bars.
  void hide() => state = true;
}
