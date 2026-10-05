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

/// What a search query asked for.
class QuranSearchOutcome {
  /// Creates an outcome.
  const QuranSearchOutcome({
    required this.direct,
    required this.surahs,
    required this.text,
  });

  /// No results at all.
  static const QuranSearchOutcome empty = QuranSearchOutcome(
    direct: null,
    surahs: [],
    text: AyahSearchResult.empty,
  );

  /// The one ayah the query points at, such as "البقرة 255" or "2:255".
  final AyahMatch? direct;

  /// Surahs whose name fits the query, for jumping straight to a surah.
  final List<Surah> surahs;

  /// Ayahs whose text contains the query.
  final AyahSearchResult text;

  /// Whether nothing matched.
  bool get isEmpty => direct == null && surahs.isEmpty && text.total == 0;
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
    if (tokens.isEmpty) return QuranSearchOutcome.empty;

    final numbers = [for (final token in tokens) int.tryParse(token)];
    final allNumbers = numbers.every((n) => n != null);

    // "2:255" or "2 255".
    if (allNumbers && tokens.length == 2) {
      final direct = _ayah(numbers[0]!, numbers[1]!);
      if (direct != null) return _referenceOnly(direct);
    }
    // "36": a surah number.
    if (allNumbers && tokens.length == 1) {
      final number = numbers.single!;
      if (number >= 1 && number <= _metadata.surahs.length) {
        return QuranSearchOutcome(
          direct: null,
          surahs: [_metadata.surah(number)],
          text: AyahSearchResult.empty,
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
