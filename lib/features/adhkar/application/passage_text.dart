import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../quran_text/domain/quran_text.dart';
import '../domain/dhikr.dart';
import '../domain/quran_passage.dart';

/// The words of a Quran dhikr, read from the verified Quran text.
///
/// Nothing is typed here. The recitation is, in order: the isti'adha when the
/// passage starts one, then for each span the basmala (only when the span opens
/// a surah that has one: not Al-Fatiha, whose basmala is its first ayah, and
/// not At-Tawba) and the ayahs between ﴿ ﴾. Each is on its own line: the
/// formulas above, the ayahs below.
String composePassage(QuranPassage passage, QuranText text) {
  final parts = <String>[if (passage.istiadha) Recitation.istiadha];
  for (final span in passage.spans) {
    if (span.opensSurah && text.hasBasmala(span.surah)) {
      parts.add(text.basmala);
    }
    final ayahs = [
      for (var ayah = span.from; ayah <= span.to; ayah++)
        text.uthmani(AyahRef(span.surah, ayah)),
    ];
    parts.add('﴿${ayahs.join(' ')}﴾');
  }
  return parts.join('\n');
}

/// "البقرة ٢٥٥" or "آل عمران ١٩٠–٢٠٠" for each span, joined by Arabic commas.
String describePassage(
  QuranPassage passage,
  QuranText text,
  String Function(int) digits,
) => [
  for (final span in passage.spans)
    '${text.metadata.surah(span.surah).arabicName} '
        '${digits(span.from)}${span.to == span.from ? '' : '–${digits(span.to)}'}',
].join('، ');

/// The words to show for a dhikr: its own text, or the passage it recites once
/// the Quran text has loaded.
final dhikrTextProvider = Provider.family<AsyncValue<String>, Dhikr>((
  ref,
  dhikr,
) {
  final passage = dhikr.quran;
  if (passage == null) return AsyncData(dhikr.text);
  return ref
      .watch(quranTextProvider)
      .whenData((text) => composePassage(passage, text));
});
