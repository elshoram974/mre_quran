import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_texts.dart';
import '../domain/mushaf_edition.dart';

/// Ayahs chosen on the pages of the reader, to copy or share together.
///
/// It starts on the ayah pressed and grows to each ayah tapped after it,
/// on the same page or another, before or after the first one.
@immutable
class AyahSelection {
  /// Creates the selection of [range], started at [anchor].
  const AyahSelection({
    required this.edition,
    required this.texts,
    required this.anchor,
    required this.range,
  });

  /// The reading whose pages it was made on.
  final MushafEdition edition;

  /// That reading's text, which the ayahs are copied from.
  final AyahTexts texts;

  /// The ayah it started at: one end of [range] always.
  final AyahRef anchor;

  /// The ayahs chosen.
  final AyahRange range;
}

/// The ayahs chosen on the reader's pages, or null when none are.
final ayahSelectionProvider =
    NotifierProvider<AyahSelectionNotifier, AyahSelection?>(
      AyahSelectionNotifier.new,
    );

/// Owns the reader's ayah selection.
class AyahSelectionNotifier extends Notifier<AyahSelection?> {
  @override
  AyahSelection? build() => null;

  /// Starts a selection of [ayah] alone, on the pages of [edition].
  void start(MushafEdition edition, AyahTexts texts, AyahRef ayah) =>
      state = AyahSelection(
        edition: edition,
        texts: texts,
        anchor: ayah,
        range: AyahRange.single(ayah),
      );

  /// Grows or shrinks the selection to run from its first ayah to [ayah],
  /// at most [limit] ayahs. Returns false when [limit] cut it short.
  bool extendTo(AyahRef ayah, {required int limit}) {
    final current = state;
    if (current == null) return true;
    final order = AyahOrder.of(current.texts);
    final anchor = current.anchor;
    var range = AyahRange.between(anchor, ayah);
    final fits = order.length(range) <= limit;
    if (!fits) {
      range = ayah.compareTo(anchor) >= 0
          ? AyahRange(anchor, order.step(anchor, limit - 1))
          : AyahRange(order.step(anchor, 1 - limit), anchor);
    }
    state = AyahSelection(
      edition: current.edition,
      texts: current.texts,
      anchor: anchor,
      range: range,
    );
    return fits;
  }

  /// Ends the selection.
  void clear() => state = null;
}
