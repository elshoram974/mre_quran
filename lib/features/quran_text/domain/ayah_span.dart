import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';
import 'ayah_texts.dart';

/// A run of ayahs of one surah, chosen to copy or share.
@immutable
class AyahSpan {
  /// Creates the span of [surah] from ayah [first] to ayah [last].
  const AyahSpan({required this.surah, required this.first, required this.last})
    : assert(first >= 1 && last >= first);

  /// The span of the single ayah [ref].
  AyahSpan.single(AyahRef ref)
    : this(surah: ref.surah, first: ref.ayah, last: ref.ayah);

  /// The surah.
  final int surah;

  /// First and last ayah, inclusive.
  final int first;
  final int last;

  /// How many ayahs the span holds.
  int get length => last - first + 1;

  /// The ayahs, in order.
  List<AyahRef> get refs => [
    for (var ayah = first; ayah <= last; ayah++) AyahRef(surah, ayah),
  ];

  /// The span moved to start at [first] and end at [last], kept inside
  /// [surahLength] ayahs and at most [limit] long. When the two ends cross,
  /// the end that was not moved follows the one that was.
  AyahSpan adjusted({
    int? first,
    int? last,
    required int surahLength,
    required int limit,
  }) {
    var from = (first ?? this.first).clamp(1, surahLength);
    var to = (last ?? this.last).clamp(1, surahLength);
    if (first != null) {
      if (to < from) to = from;
      if (to - from + 1 > limit) to = from + limit - 1;
    } else {
      if (from > to) from = to;
      if (to - from + 1 > limit) from = to - limit + 1;
    }
    return AyahSpan(surah: surah, first: from, last: to);
  }

  @override
  bool operator ==(Object other) =>
      other is AyahSpan &&
      other.surah == surah &&
      other.first == first &&
      other.last == last;

  @override
  int get hashCode => Object.hash(surah, first, last);
}

/// Writes ayahs out as text to paste or send.
abstract final class AyahShareText {
  /// The ayahs of [span] in the reading's copyable text, with tashkeel, each
  /// followed by its number in [digits], inside the ornate brackets:
  /// `﴿… (١) … (٢)﴾`.
  static String body(
    AyahTexts text,
    AyahSpan span,
    String Function(int) digits,
  ) {
    final ayahs = [
      for (final ref in span.refs) '${text.copy(ref)} (${digits(ref.ayah)})',
    ];
    return '﴿${ayahs.join(' ')}﴾';
  }

  /// The pages [span] lies on: its first ayah's page and its last ayah's.
  static ({int first, int last}) pages(AyahTexts text, AyahSpan span) => (
    first: text.pageOf(AyahRef(span.surah, span.first)),
    last: text.pageOf(AyahRef(span.surah, span.last)),
  );
}
