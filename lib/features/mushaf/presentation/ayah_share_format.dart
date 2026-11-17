import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../quran_text/domain/ayah_share_text.dart';
import '../../quran_text/domain/ayah_texts.dart';

/// The most ayahs copied or shared at once. Longer choices are better read
/// in the Mushaf itself.
const int ayahShareLimit = 50;

/// The ayahs of [range] with their references, ready to paste. Each surah's
/// ayahs come in their own brackets with the reference under them:
/// `﴿… (٢٨٦)﴾` and `[البقرة: ٢٨٦ · صفحة ٤٩]`, then the next surah. Every
/// line is set to read right to left in any app and any language.
String ayahShareText(
  BuildContext context,
  AyahTexts text,
  AyahRange range,
  String Function(int) digits,
) {
  final l10n = context.l10n;
  final order = AyahOrder.of(text);
  final parts = [
    for (final run in order.runs(range))
      '${AyahShareText.body(text, run, digits)}\n'
          '${l10n.ayahShareReference(text.metadata.surah(run.surah).arabicName, runAyahs(context, run, digits), runPages(context, text, run, digits))}',
  ];
  return AyahShareText.rightToLeft(parts.join('\n'));
}

/// The ayah numbers of [run]: `٢٥٥` or `٢٥٥–٢٥٧`.
String runAyahs(BuildContext context, SurahRun run, String Function(int) d) =>
    run.first == run.last
    ? d(run.first)
    : context.l10n.ayahRange(d(run.first), d(run.last));

/// The pages [run] lies on: `صفحة ٤٢` or `صفحة ٤٢–٤٣`.
String runPages(
  BuildContext context,
  AyahTexts text,
  SurahRun run,
  String Function(int) d,
) {
  final pages = AyahShareText.pages(text, run);
  return pages.first == pages.last
      ? context.l10n.pageNumber(d(pages.first))
      : context.l10n.pageRange(d(pages.first), d(pages.last));
}

/// Where [ref] is, in a few words: `البقرة ٢٨٥`.
String ayahPlace(
  BuildContext context,
  AyahTexts text,
  AyahRef ref,
  String Function(int) d,
) => context.l10n.surahAyah(
  text.metadata.surah(ref.surah).arabicName,
  d(ref.ayah),
);

/// Where [range] is: `البقرة ٢٥٥`, `البقرة ٢٥٥–٢٥٧`, or across surahs
/// `البقرة ٢٨٥ – آل عمران ٣`.
String rangePlace(
  BuildContext context,
  AyahTexts text,
  AyahRange range,
  String Function(int) d,
) {
  if (range.isSingle) return ayahPlace(context, text, range.start, d);
  if (range.isOneSurah) {
    return context.l10n.surahAyah(
      text.metadata.surah(range.start.surah).arabicName,
      context.l10n.ayahRange(d(range.start.ayah), d(range.end.ayah)),
    );
  }
  return '${ayahPlace(context, text, range.start, d)} – '
      '${ayahPlace(context, text, range.end, d)}';
}
