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
    required this.revelationOrder,
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

  /// Its place in the order of revelation, 1–114, as the source records it.
  final int revelationOrder;

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

/// A hizb (half a juz) entry of the Quran index.
@immutable
class Hizb {
  /// Creates a hizb.
  const Hizb({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.startPage,
  });

  /// 1–60.
  final int number;

  /// Surah of the first ayah.
  final int surah;

  /// Ayah number of the first ayah within [surah].
  final int ayah;

  /// Page of the Madinah Mushaf that contains the first ayah.
  final int startPage;

  /// The juz (1–30) this hizb is half of: two hizb to a juz.
  int get juz => (number - 1) ~/ 2 + 1;
}

/// A rub' al-hizb (a quarter of a hizb), the unit the Mushaf marks in its
/// margin: the hizb it is part of, and how far into that hizb it begins.
@immutable
class HizbQuarter {
  /// The quarter numbered [rub], 1–240, through the whole Quran.
  const HizbQuarter(this.rub) : assert(rub >= 1);

  /// 1–240, in reading order.
  final int rub;

  /// The hizb (1–60) this quarter is part of: four quarters to a hizb.
  int get hizb => (rub - 1) ~/ 4 + 1;

  /// How many quarters of [hizb] come before this one: 0 where the hizb
  /// begins, then 1 (a quarter of it), 2 (half) and 3 (three quarters).
  int get quarter => (rub - 1) % 4;

  @override
  bool operator ==(Object other) => other is HizbQuarter && other.rub == rub;

  @override
  int get hashCode => rub.hashCode;

  @override
  String toString() => 'rub $rub (hizb $hizb, quarter $quarter)';
}

/// An ayah at which the reader prostrates (sajdat al-tilawa), as marked in the
/// Madinah Mushaf: fifteen in all.
@immutable
class Sajda {
  /// Creates a sajda.
  const Sajda({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.startPage,
  });

  /// 1–15, in reading order.
  final int number;

  /// Surah of the ayah.
  final int surah;

  /// Ayah number within [surah].
  final int ayah;

  /// Page of the Madinah Mushaf that contains the ayah.
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
    required this.sajdas,
  });

  /// All surahs in order.
  final List<Surah> surahs;

  /// All juz in order.
  final List<Juz> juzs;

  /// First ayah of every page; index 0 is page 1.
  final List<PageStart> pageStarts;

  /// The sajda ayahs in reading order.
  final List<Sajda> sajdas;

  /// First ayah of each rub' al-hizb (quarter of a hizb); index 0 is rub' 1.
  /// There are 240, so 60 hizb of four quarters each.
  final List<AyahRef> rubStarts;

  /// All 60 hizb in order. A hizb is four quarters (rub'), so each begins at
  /// every fourth entry of [rubStarts]: derived from the bundled source, not
  /// listed by hand.
  late final List<Hizb> hizbs = List.unmodifiable([
    for (var number = 1; number <= rubStarts.length ~/ 4; number++)
      Hizb(
        number: number,
        surah: rubStarts[(number - 1) * 4].surah,
        ayah: rubStarts[(number - 1) * 4].ayah,
        startPage: pageOf(
          rubStarts[(number - 1) * 4].surah,
          rubStarts[(number - 1) * 4].ayah,
        ),
      ),
  ]);

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

  /// The juz (1–30) that contains [ref]: the last one that begins at or before
  /// it.
  int juzOf(AyahRef ref) {
    var juz = 1;
    for (final candidate in juzs) {
      if (AyahRef(candidate.surah, candidate.ayah).compareTo(ref) > 0) break;
      juz = candidate.number;
    }
    return juz;
  }

  /// The hizb (1–60) that contains [ref].
  int hizbOf(AyahRef ref) => (rubOf(ref) - 1) ~/ 4 + 1;

  /// The last rub' that begins on or before each page; index 0 is page 1.
  /// Built once, when first asked: the reader asks for every page it builds.
  late final List<int> _rubByPage = () {
    final table = List<int>.filled(pageCount, 1);
    var rub = 1;
    for (var page = 1; page <= pageCount; page++) {
      // The next rub' is rubStarts[rub]: it counts once its page is reached.
      while (rub < rubStarts.length &&
          pageOf(rubStarts[rub].surah, rubStarts[rub].ayah) <= page) {
        rub++;
      }
      table[page - 1] = rub;
    }
    return table;
  }();

  /// The rub' al-hizb that [page] belongs to: the last one that begins on or
  /// before it, the rule [juzOfPage] follows for the juz.
  ///
  /// A rub' begins on the page that holds its first ayah. So a page on which
  /// a hizb or a quarter begins part way down is named by the new one, as the
  /// mark in its margin names it, though its first ayahs still belong to the
  /// one before.
  HizbQuarter quarterOfPage(int page) => HizbQuarter(_rubByPage[page - 1]);

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
