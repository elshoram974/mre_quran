import 'package:flutter/foundation.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// The verified Quran text, indexed by surah and ayah.
///
/// [uthmani] is the verbatim display text with full tashkeel. [clean] is the
/// source's own text without diacritics, kept apart for searching. Neither is
/// ever edited.
@immutable
class QuranText {
  /// Builds the index. Throws [ArgumentError] unless both lists hold exactly
  /// one entry per ayah of [metadata], in order.
  QuranText({
    required this.metadata,
    required List<String> uthmani,
    required List<String> clean,
  }) : _uthmani = List.unmodifiable(uthmani),
       _clean = List.unmodifiable(clean),
       _offsets = _offsetsOf(metadata) {
    final total = metadata.totalAyahs;
    if (uthmani.length != total || clean.length != total) {
      throw ArgumentError(
        'Expected $total ayahs; got ${uthmani.length} and ${clean.length}.',
      );
    }
  }

  /// Surah and page data the text is indexed against.
  final QuranMetadata metadata;

  final List<String> _uthmani;
  final List<String> _clean;
  final List<int> _offsets;

  static List<int> _offsetsOf(QuranMetadata metadata) {
    final offsets = <int>[];
    var running = 0;
    for (final surah in metadata.surahs) {
      offsets.add(running);
      running += surah.ayahCount;
    }
    return offsets;
  }

  /// Number of ayahs.
  int get length => _uthmani.length;

  /// Position of [ref] in reading order, 0-based.
  int indexOf(AyahRef ref) {
    final surah = metadata.surah(ref.surah);
    if (ref.ayah < 1 || ref.ayah > surah.ayahCount) {
      throw RangeError('No ayah ${ref.surah}:${ref.ayah}');
    }
    return _offsets[ref.surah - 1] + ref.ayah - 1;
  }

  /// The ayah at reading-order [index].
  AyahRef refAt(int index) {
    RangeError.checkValidIndex(index, _uthmani);
    var low = 0;
    var high = _offsets.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_offsets[mid] <= index) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return AyahRef(low + 1, index - _offsets[low] + 1);
  }

  /// Display text with tashkeel.
  String uthmani(AyahRef ref) => _uthmani[indexOf(ref)];

  /// Text without diacritics.
  String clean(AyahRef ref) => _clean[indexOf(ref)];

  /// Display text of every ayah of [surah], in order.
  List<String> uthmaniOfSurah(int surah) {
    final start = _offsets[surah - 1];
    return _uthmani.sublist(start, start + metadata.surah(surah).ayahCount);
  }

  /// Display text of the ayahs that start on [page].
  List<({AyahRef ref, String text})> pageAyahs(int page) => [
    for (final ref in metadata.ayahsOnPage(page))
      (ref: ref, text: uthmani(ref)),
  ];
}
