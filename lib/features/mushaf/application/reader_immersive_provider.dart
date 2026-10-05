import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Mushaf is shown without bars. A tap on the page toggles it.
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
}
