import 'package:meta/meta.dart';

import 'quran_passage.dart';

/// One dhikr or dua with the number of times to say it and its evidence.
@immutable
class Dhikr {
  /// Creates a dhikr.
  const Dhikr({
    required this.order,
    required this.text,
    required this.repeat,
    required this.repeatLabel,
    required this.source,
    required this.variant,
    this.label,
    this.virtue,
    this.hadithText,
    this.vocabulary,
    this.quran,
    this.onlyAfter = const {},
  });

  /// Position in its source file. Unique inside one file.
  final int order;

  /// The words to say, with tashkeel, exactly as in the source file. Empty
  /// for a [quran] dhikr, whose words come from the Quran text.
  final String text;

  /// How many times to say it. At least 1.
  final int repeat;

  /// [repeat] written in words, with tashkeel.
  final String repeatLabel;

  /// The evidence: the Quran reference or the hadith reference and its grading.
  final String source;

  /// Which part of a shared file this belongs to. The collection filters by it
  /// (for the morning and evening file: 0 both, 1 morning only, 2 evening only).
  final int variant;

  /// A short line above the words saying when or by whom they are said ("when
  /// he sneezes", "the dua of Yunus"), when the words alone would not tell.
  final String? label;

  /// The reward or benefit mentioned in the evidence, if the source states one.
  final String? virtue;

  /// The hadith the dhikr is taken from, with its chain, if the source has it.
  final String? hadithText;

  /// Prayers (`fajr`, `dhuhr`, `asr`, `maghrib`, `isha`) it is said after,
  /// when it is not said after every prayer. Empty means after any.
  final Set<String> onlyAfter;

  /// The ayahs to recite, for a dhikr that is a passage of the Quran.
  final QuranPassage? quran;

  /// Explanation of difficult words in [hadithText], if the source has it.
  final String? vocabulary;
}
