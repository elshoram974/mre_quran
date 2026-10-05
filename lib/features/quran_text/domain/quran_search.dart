import '../../quran_index/domain/index_search.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'ayah_search.dart';

/// Words people type around a reference, such as "سورة" or "آية". Folded.
const Set<String> _fillerWords = {
  'سوره', // سورة
  'ايه', // آية
  'surah',
  'sura',
  'ayah',
  'aya',
  'verse',
};

/// Words that name a page, folded.
const Set<String> _pageWords = {
  '\u0635\u0641\u062D\u0647',
  'page',
  'pg',
  '\u0635',
};

/// Words that name a juz, folded.
const Set<String> _juzWords = {
  '\u062C\u0632\u0621',
  '\u0627\u0644\u062C\u0632\u0621',
  'juz',
  'part',
};

/// Words that name a hizb, folded.
const Set<String> _hizbWords = {
  '\u062D\u0632\u0628',
  '\u0627\u0644\u062D\u0632\u0628',
  'hizb',
};

/// What a page, juz, or hizb query points at.
enum PageHitKind {
  /// A Mushaf page by number.
  page,

  /// A juz by number.
  juz,

  /// A hizb by number.
  hizb,
}

/// A page, juz, or hizb the reader asked for, with the page it starts on.
class PageHit {
  /// Creates a hit.
  const PageHit({required this.kind, required this.number, required this.page});

  /// What was asked for.
  final PageHitKind kind;

  /// Its number: the page, juz, or hizb number.
  final int number;

  /// The Mushaf page to open.
  final int page;
}

/// What a search query asked for.
class QuranSearchOutcome {
  /// Creates an outcome.
  const QuranSearchOutcome({
    required this.direct,
    required this.surahs,
    required this.text,
    this.pages = const [],
  });

  /// No results at all.
  static const QuranSearchOutcome empty = QuranSearchOutcome(
    direct: null,
    surahs: [],
    text: AyahSearchResult.empty,
  );

  /// Pages, juz, or hizb the query names, such as "صفحة 42" or "جزء 3".
  final List<PageHit> pages;

  /// The one ayah the query points at, such as "البقرة 255" or "2:255".
  final AyahMatch? direct;

  /// Surahs whose name fits the query, for jumping straight to a surah.
  final List<Surah> surahs;

  /// Ayahs whose text contains the query.
  final AyahSearchResult text;

  /// Whether nothing matched.
  bool get isEmpty =>
      direct == null && surahs.isEmpty && pages.isEmpty && text.total == 0;
}

/// Searches the Quran by reference (surah and ayah) and by text.
///
/// Accepted references: `2:255`, `2 255`, `٢:٢٥٥`, `البقرة 255`, `سورة البقرة آية 255`,
/// `al baqara 255`, and a bare surah name or number. Everything else is a
/// text search that needs no tashkeel.
class QuranSearch {
  /// Creates a search over [surahs] and [ayahs].
  QuranSearch({required this.surahs, required this.ayahs});

  /// Surah names and numbers.
  final IndexSearcher surahs;

  /// Ayah text.
  final AyahSearchIndex ayahs;

  QuranMetadata get _metadata => surahs.metadata;

  /// Runs [query]. At most [limit] text matches are returned.
  QuranSearchOutcome outcome(String query, {int limit = 100}) {
    final key = normalizeSearchKey(query);
    if (key.isEmpty) return QuranSearchOutcome.empty;
    final tokens = [
      for (final token in key.split(RegExp(r'[\s:،,/\-.]+')))
        if (token.isNotEmpty && !_fillerWords.contains(token)) token,
    ];
    // Only filler words such as "سورة": search them as text.
    if (tokens.isEmpty) {
      return QuranSearchOutcome(
        direct: null,
        surahs: const [],
        text: ayahs.search(query, limit: limit),
      );
    }

    final numbers = [for (final token in tokens) int.tryParse(token)];
    final allNumbers = numbers.every((n) => n != null);

    // "صفحة 42", "ص 42", "page 42", "جزء 3", "الحزب 5", or the number first.
    if (tokens.length == 2) {
      final hit = _pageHit(tokens, numbers);
      if (hit != null) {
        return QuranSearchOutcome(
          direct: null,
          surahs: const [],
          text: AyahSearchResult.empty,
          pages: [hit],
        );
      }
    }

    // "2:255" or "2 255".
    if (allNumbers && tokens.length == 2) {
      final direct = _ayah(numbers[0]!, numbers[1]!);
      if (direct != null) return _referenceOnly(direct);
    }
    // "36": a surah number.
    if (allNumbers && tokens.length == 1) {
      final number = numbers.single!;
      final isSurah = number >= 1 && number <= _metadata.surahs.length;
      final isPage = number >= 1 && number <= _metadata.pageCount;
      if (isSurah || isPage) {
        return QuranSearchOutcome(
          direct: null,
          surahs: [if (isSurah) _metadata.surah(number)],
          text: AyahSearchResult.empty,
          pages: [
            if (isPage)
              PageHit(kind: PageHitKind.page, number: number, page: number),
          ],
        );
      }
    }
    // "البقرة 255".
    if (tokens.length >= 2 && numbers.last != null && !allNumbers) {
      final surah = surahs.resolveSurah(
        tokens.take(tokens.length - 1).join(' '),
      );
      if (surah != null) {
        final direct = _ayah(surah.number, numbers.last!);
        if (direct != null) return _referenceOnly(direct);
        return QuranSearchOutcome(
          direct: null,
          surahs: [surah],
          text: ayahs.search(query, limit: limit),
        );
      }
    }
    return QuranSearchOutcome(
      direct: null,
      surahs: allNumbers
          ? const []
          : surahs.surahs(tokens.join(' ')).take(5).toList(),
      text: allNumbers
          ? AyahSearchResult.empty
          : ayahs.search(query, limit: limit),
    );
  }

  PageHit? _pageHit(List<String> tokens, List<int?> numbers) {
    final word = numbers[0] == null ? tokens[0] : tokens[1];
    final number = numbers[0] ?? numbers[1];
    if (number == null || (numbers[0] != null && numbers[1] != null)) {
      return null;
    }
    if (_pageWords.contains(word) &&
        number >= 1 &&
        number <= _metadata.pageCount) {
      return PageHit(kind: PageHitKind.page, number: number, page: number);
    }
    if (_juzWords.contains(word) &&
        number >= 1 &&
        number <= _metadata.juzs.length) {
      return PageHit(
        kind: PageHitKind.juz,
        number: number,
        page: _metadata.juzs[number - 1].startPage,
      );
    }
    final hizbCount = _metadata.rubStarts.length ~/ 4;
    if (_hizbWords.contains(word) && number >= 1 && number <= hizbCount) {
      final start = _metadata.rubStarts[(number - 1) * 4];
      return PageHit(
        kind: PageHitKind.hizb,
        number: number,
        page: _metadata.pageOf(start.surah, start.ayah),
      );
    }
    return null;
  }

  QuranSearchOutcome _referenceOnly(AyahMatch direct) => QuranSearchOutcome(
    direct: direct,
    surahs: const [],
    text: AyahSearchResult.empty,
  );

  AyahMatch? _ayah(int surah, int ayah) {
    if (surah < 1 || surah > _metadata.surahs.length) return null;
    if (ayah < 1 || ayah > _metadata.surah(surah).ayahCount) return null;
    return AyahMatch(
      ref: AyahRef(surah, ayah),
      page: _metadata.pageOf(surah, ayah),
    );
  }
}
