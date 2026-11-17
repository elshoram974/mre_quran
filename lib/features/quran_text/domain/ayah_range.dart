import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';
import 'ayah_texts.dart';

/// A run of ayahs in Quran order, chosen to copy or share. It may cross
/// from the end of one surah into the next: the last ayahs of Al-Baqarah
/// and the first of Al Imran are one range.
@immutable
class AyahRange {
  /// Creates the range from [start] to [end], both included.
  const AyahRange(this.start, this.end);

  /// The range of the single ayah [ref].
  const AyahRange.single(AyahRef ref) : start = ref, end = ref;

  /// The range between [a] and [b], whichever comes first in the Quran.
  factory AyahRange.between(AyahRef a, AyahRef b) =>
      a.compareTo(b) <= 0 ? AyahRange(a, b) : AyahRange(b, a);

  /// First ayah, included.
  final AyahRef start;

  /// Last ayah, included.
  final AyahRef end;

  /// Whether [ref] lies inside the range.
  bool contains(AyahRef ref) =>
      start.compareTo(ref) <= 0 && ref.compareTo(end) <= 0;

  /// Whether the range is one ayah.
  bool get isSingle => start == end;

  /// Whether the range stays inside one surah.
  bool get isOneSurah => start.surah == end.surah;

  @override
  bool operator ==(Object other) =>
      other is AyahRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start–$end';
}

/// The ayahs of one surah inside a range: [surah] from [first] to [last].
typedef SurahRun = ({int surah, int first, int last});

/// Numbers every ayah of a reading in Quran order, so ranges can be
/// counted, stepped, and cut across surahs. Readings count some surahs'
/// ayahs differently, so the counts come from the reading's own text.
class AyahOrder {
  /// Numbers the ayahs of [surahCount] surahs, [ayahCount] of each.
  AyahOrder({required int surahCount, required int Function(int) ayahCount})
    : _counts = [for (var s = 1; s <= surahCount; s++) ayahCount(s)] {
    var total = 0;
    for (final count in _counts) {
      _before.add(total);
      total += count;
    }
    this.total = total;
  }

  /// The order of [text]'s ayahs.
  factory AyahOrder.of(AyahTexts text) => AyahOrder(
    surahCount: text.metadata.surahs.length,
    ayahCount: text.ayahCount,
  );

  final List<int> _counts;
  final List<int> _before = [];

  /// How many ayahs there are.
  late final int total;

  /// How many surahs there are.
  int get surahCount => _counts.length;

  /// How many ayahs [surah] has.
  int ayahCount(int surah) => _counts[surah - 1];

  /// The ayah's place in the Quran, from 0.
  int indexOf(AyahRef ref) => _before[ref.surah - 1] + ref.ayah - 1;

  /// The ayah at [index], kept inside the Quran.
  AyahRef at(int index) {
    final clamped = index.clamp(0, total - 1);
    var low = 0;
    var high = _before.length - 1;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_before[middle] <= clamped) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return AyahRef(low + 1, clamped - _before[low] + 1);
  }

  /// [ref] kept inside the Quran: a surah's last ayah at most.
  AyahRef clamp(AyahRef ref) {
    final surah = ref.surah.clamp(1, surahCount);
    return AyahRef(surah, ref.ayah.clamp(1, ayahCount(surah)));
  }

  /// How many ayahs [range] holds.
  int length(AyahRange range) => indexOf(range.end) - indexOf(range.start) + 1;

  /// The ayahs of [range], in order.
  List<AyahRef> refs(AyahRange range) => [
    for (var i = indexOf(range.start); i <= indexOf(range.end); i++) at(i),
  ];

  /// [range] cut at each surah's end.
  List<SurahRun> runs(AyahRange range) => [
    for (var surah = range.start.surah; surah <= range.end.surah; surah++)
      (
        surah: surah,
        first: surah == range.start.surah ? range.start.ayah : 1,
        last: surah == range.end.surah ? range.end.ayah : ayahCount(surah),
      ),
  ];

  /// [range] with its start moved to [start]. The end follows when the two
  /// cross, and stays at most [limit] ayahs away.
  AyahRange moveStart(AyahRange range, AyahRef start, {required int limit}) {
    final from = indexOf(clamp(start));
    var to = indexOf(range.end);
    if (to < from) to = from;
    if (to - from + 1 > limit) to = from + limit - 1;
    return AyahRange(at(from), at(to));
  }

  /// [range] with its end moved to [end]. The start follows when the two
  /// cross, and stays at most [limit] ayahs away.
  AyahRange moveEnd(AyahRange range, AyahRef end, {required int limit}) {
    final to = indexOf(clamp(end));
    var from = indexOf(range.start);
    if (from > to) from = to;
    if (to - from + 1 > limit) from = to - limit + 1;
    return AyahRange(at(from), at(to));
  }

  /// The ayah [steps] after [ref] (before it when negative), kept inside the
  /// Quran.
  AyahRef step(AyahRef ref, int steps) => at(indexOf(ref) + steps);
}
