import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/application/ayah_texts_provider.dart';
import '../../quran_text/application/quran_text_providers.dart';
import '../../quran_text/domain/quran_text.dart';
import '../domain/dhikr.dart';
import '../domain/quran_passage.dart';

/// The words of a Quran dhikr, read from the verified Quran text, in the script
/// the reader shows ([QuranText.mushaf]).
///
/// Nothing is typed here. The recitation is, in order: the isti'adha when the
/// passage starts one (always when it begins inside a surah, as an ayah is
/// recited; and when the data asks for it before a surah), then for each span the basmala (only when the span opens
/// a surah that has one: not Al-Fatiha, whose basmala is its first ayah, and
/// not At-Tawba) and the ayahs between ﴿ ﴾. Each is on its own line: the
/// formulas above, the ayahs below.
String composePassage(QuranPassage passage, QuranText text) {
  // An ayah from inside a surah is recited after the isti'adha; a surah from its
  // beginning after its basmala.
  final insideSurah =
      passage.spans.isNotEmpty && !passage.spans.first.opensSurah;
  final parts = <String>[
    if (passage.istiadha || insideSurah) Recitation.istiadha,
  ];
  for (final span in passage.spans) {
    if (span.opensSurah && text.hasBasmala(span.surah)) {
      parts.add(text.mushafBasmala);
    }
    final ayahs = [
      for (var ayah = span.from; ayah <= span.to; ayah++)
        text.mushaf(AyahRef(span.surah, ayah)),
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

/// The words of a dhikr and the font that draws them.
typedef DhikrWords = ({String text, String fontFamily});

/// The words to show for a dhikr: its own text, or the passage it recites once
/// the Quran text has loaded, which is drawn in the Quran's own font.
final dhikrTextProvider = Provider.family<AsyncValue<DhikrWords>, Dhikr>((
  ref,
  dhikr,
) {
  final passage = dhikr.quran;
  if (passage == null) {
    return AsyncData((text: dhikr.text, fontFamily: AppTokens.quranFontFamily));
  }
  return ref
      .watch(quranTextProvider)
      .whenData(
        (text) => (
          text: composePassage(passage, text),
          fontFamily: appQuranFont(text),
        ),
      );
});
