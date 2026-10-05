import 'package:meta/meta.dart';

/// An ayah, identified by surah and ayah number.
@immutable
class AyahRef implements Comparable<AyahRef> {
  /// Creates a reference. Both numbers are 1-based.
  const AyahRef(this.surah, this.ayah);

  /// Surah number, 1–114.
  final int surah;

  /// Ayah number within [surah].
  final int ayah;

  @override
  int compareTo(AyahRef other) =>
      surah != other.surah ? surah - other.surah : ayah - other.ayah;

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}

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
  QuranMetadata({
    required this.surahs,
    required this.juzs,
    required this.pageStarts,
    required this.rubStarts,
  });

  /// All surahs in order.
  final List<Surah> surahs;

  /// All juz in order.
  final List<Juz> juzs;

  /// First ayah of every page; index 0 is page 1.
  final List<PageStart> pageStarts;

  /// First ayah of each rub' al-hizb (quarter of a hizb); index 0 is rub' 1.
  /// There are 240, so 60 hizb of four quarters each.
  final List<AyahRef> rubStarts;

  late final Map<AyahRef, int> _rubByStart = {
    for (var i = 0; i < rubStarts.length; i++) rubStarts[i]: i + 1,
  };

  /// The rub' (1–240) that begins exactly at [ref], or null.
  int? rubStartingAt(AyahRef ref) => _rubByStart[ref];

  /// The rub' (1–240) that contains [ref].
  int rubOf(AyahRef ref) {
    var low = 0;
    var high = rubStarts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (rubStarts[mid].compareTo(ref) <= 0) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  /// The hizb (1–60) that contains [ref].
  int hizbOf(AyahRef ref) => (rubOf(ref) - 1) ~/ 4 + 1;

  /// Number of Mushaf pages.
  int get pageCount => pageStarts.length;

  /// Number of ayahs in the whole Quran.
  int get totalAyahs => surahs.fold(0, (sum, surah) => sum + surah.ayahCount);

  /// The ayahs that start on [page], in reading order.
  ///
  /// An ayah that begins on an earlier page and runs over is listed on the
  /// page where it begins, matching the page starts in the source file.
  List<AyahRef> ayahsOnPage(int page) {
    final start = pageStarts[page - 1];
    final end = page < pageStarts.length ? pageStarts[page] : null;
    final refs = <AyahRef>[];
    var surah = start.surah;
    var ayah = start.ayah;
    while (surah <= surahs.length) {
      if (end != null && surah == end.surah && ayah == end.ayah) break;
      refs.add(AyahRef(surah, ayah));
      if (ayah == this.surah(surah).ayahCount) {
        surah++;
        ayah = 1;
      } else {
        ayah++;
      }
    }
    return refs;
  }

  /// Surah by 1-based [number].
  Surah surah(int number) => surahs[number - 1];

  /// Page that contains ayah [ayah] of [surah].
  int pageOf(int surah, int ayah) => pageOfAyah(pageStarts, surah, ayah);

  /// The juz that [page] belongs to: the last juz starting on or before it.
  Juz juzOfPage(int page) =>
      juzs.lastWhere((juz) => juz.startPage <= page, orElse: () => juzs.first);

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
