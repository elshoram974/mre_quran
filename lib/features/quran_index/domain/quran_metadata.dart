import 'package:flutter/foundation.dart';

/// Where a surah was revealed, as recorded by the source file.
enum Revelation { meccan, medinan }

/// A surah entry of the Quran index.
@immutable
class Surah {
  /// Creates a surah.
  const Surah({
    required this.number,
    required this.ayahCount,
    required this.arabicName,
    required this.transliteration,
    required this.englishName,
    required this.revelation,
    required this.startPage,
  });

  /// 1–114.
  final int number;

  /// Number of ayahs.
  final int ayahCount;

  /// Arabic name, verbatim from the source.
  final String arabicName;

  /// Latin transliteration of the name.
  final String transliteration;

  /// English meaning of the name.
  final String englishName;

  /// Place of revelation.
  final Revelation revelation;

  /// Page of the Madinah Mushaf that contains the first ayah.
  final int startPage;
}

/// A juz (part) entry of the Quran index.
@immutable
class Juz {
  /// Creates a juz.
  const Juz({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.startPage,
  });

  /// 1–30.
  final int number;

  /// Surah of the first ayah.
  final int surah;

  /// Ayah number of the first ayah within [surah].
  final int ayah;

  /// Page of the Madinah Mushaf that contains the first ayah.
  final int startPage;
}

/// First ayah of a Mushaf page.
@immutable
class PageStart {
  /// Creates a page start.
  const PageStart({required this.surah, required this.ayah});

  /// Surah of the first ayah on the page.
  final int surah;

  /// Ayah number within [surah].
  final int ayah;
}

/// Immutable Quran index data parsed from the verified source file.
@immutable
class QuranMetadata {
  /// Creates metadata. [pageStarts] has one entry per page, page 1 first.
  const QuranMetadata({
    required this.surahs,
    required this.juzs,
    required this.pageStarts,
  });

  /// All surahs in order.
  final List<Surah> surahs;

  /// All juz in order.
  final List<Juz> juzs;

  /// First ayah of every page; index 0 is page 1.
  final List<PageStart> pageStarts;

  /// Number of Mushaf pages.
  int get pageCount => pageStarts.length;

  /// Surah by 1-based [number].
  Surah surah(int number) => surahs[number - 1];

  /// Page that contains ayah [ayah] of [surah].
  int pageOf(int surah, int ayah) => pageOfAyah(pageStarts, surah, ayah);

  /// The surah whose ayahs begin on or before [page], preferring the surah
  /// that starts on that page.
  Surah surahAtPage(int page) {
    for (final candidate in surahs) {
      if (candidate.startPage == page) return candidate;
    }
    return surah(pageStarts[page - 1].surah);
  }
}

/// Page that contains ayah [ayah] of [surah], given the ordered [pageStarts].
///
/// This is the last page whose first ayah is at or before the requested one.
int pageOfAyah(List<PageStart> pageStarts, int surah, int ayah) {
  var low = 0;
  var high = pageStarts.length - 1;
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    final start = pageStarts[mid];
    final atOrBefore =
        start.surah < surah || (start.surah == surah && start.ayah <= ayah);
    if (atOrBefore) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low + 1;
}
