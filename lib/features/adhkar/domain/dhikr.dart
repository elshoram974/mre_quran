import 'package:meta/meta.dart';

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
    this.virtue,
    this.hadithText,
    this.vocabulary,
  });

  /// Position in its source file. Unique inside one file.
  final int order;

  /// The words to say, with tashkeel, exactly as in the source file.
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

  /// The reward or benefit mentioned in the evidence, if the source states one.
  final String? virtue;

  /// The hadith the dhikr is taken from, with its chain, if the source has it.
  final String? hadithText;

  /// Explanation of difficult words in [hadithText], if the source has it.
  final String? vocabulary;
}
