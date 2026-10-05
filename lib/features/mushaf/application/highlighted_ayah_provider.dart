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
