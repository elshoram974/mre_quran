import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// The ayah to show highlighted on its page, set when the reader arrives from
/// a search result or a bookmark. A tap on the page clears it.
final highlightedAyahProvider =
    NotifierProvider<HighlightedAyahNotifier, AyahRef?>(
      HighlightedAyahNotifier.new,
    );

/// Owns the highlighted ayah.
class HighlightedAyahNotifier extends Notifier<AyahRef?> {
  @override
  AyahRef? build() => null;

  /// Highlights [ayah].
  void show(AyahRef ayah) => state = ayah;

  /// Removes the highlight.
  void clear() => state = null;
}

/// One tap on an ayah: which, and how many taps there have been, so the same
/// ayah tapped twice flashes twice.
@immutable
class AyahTouch {
  /// Creates the touch.
  const AyahTouch(this.ayah, this.serial);

  /// The ayah touched.
  final AyahRef ayah;

  /// Counts the touches.
  final int serial;
}

/// The ayah a single tap just touched: its page flashes it under the ink for
/// a moment, as a pressed button shows it was pressed.
final ayahTouchProvider = NotifierProvider<AyahTouchNotifier, AyahTouch?>(
  AyahTouchNotifier.new,
);

/// Owns the last touch.
class AyahTouchNotifier extends Notifier<AyahTouch?> {
  var _serial = 0;

  @override
  AyahTouch? build() => null;

  /// Says [ayah] was just tapped.
  void touch(AyahRef ayah) => state = AyahTouch(ayah, ++_serial);
}
