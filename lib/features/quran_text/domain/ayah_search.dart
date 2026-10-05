import '../../quran_index/domain/index_search.dart';
import '../../quran_index/domain/quran_metadata.dart';
import 'quran_text.dart';

/// One ayah that matched a search.
class AyahMatch {
  /// Creates a match.
  const AyahMatch({required this.ref, required this.page});

  /// The matching ayah.
  final AyahRef ref;

  /// Mushaf page the ayah begins on.
  final int page;
}

/// Matches for a query, capped at the requested limit.
class AyahSearchResult {
  /// Creates a result.
  const AyahSearchResult({required this.matches, required this.total});

  /// No matches.
  static const AyahSearchResult empty = AyahSearchResult(matches: [], total: 0);

  /// The first matches, phrase matches before word matches.
  final List<AyahMatch> matches;

  /// How many ayahs matched in all.
  final int total;
}

/// Searches the Quran text without needing tashkeel.
///
/// The query and every ayah are folded with [normalizeSearchKey] (diacritics,
/// alef, ya, ta marbuta, and digits). Each ayah has two folded keys: one from
/// the plain spelling ("العالمين") and one from the Uthmani spelling, which
/// writes some alefs as dagger alefs ("العلمين"). A query written either way
/// matches. Keys are built once, off the main isolate, with [buildKeys].
class AyahSearchIndex {
  /// Creates an index over [text] using precomputed [keys].
  AyahSearchIndex({
    required this.text,
    required List<String> keys,
    required List<String> uthmaniKeys,
  }) : _keys = keys,
       _uthmaniKeys = uthmaniKeys {
    if (keys.length != text.length || uthmaniKeys.length != text.length) {
      throw ArgumentError(
        'Expected ${text.length} keys; got ${keys.length} and '
        '${uthmaniKeys.length}.',
      );
    }
  }

  /// The text being searched.
  final QuranText text;

  final List<String> _keys;
  final List<String> _uthmaniKeys;

  /// Folded search keys for [lines] of Quran text.
  static List<String> buildKeys(List<String> lines) => [
    for (final line in lines) normalizeSearchKey(line),
  ];

  /// Finds ayahs containing [query].
  ///
  /// Ayahs that contain the words together, in order, come first. Ayahs that
  /// contain every word anywhere come next. Both groups keep Quran order.
  AyahSearchResult search(String query, {int limit = 100}) {
    final phrase = normalizeSearchKey(query);
    if (phrase.isEmpty || limit <= 0) return AyahSearchResult.empty;
    final words = phrase.split(RegExp(r'\s+'));

    final exact = <int>[];
    final loose = <int>[];
    for (var i = 0; i < _keys.length; i++) {
      final plain = _keys[i];
      final uthmani = _uthmaniKeys[i];
      if (plain.contains(phrase) || uthmani.contains(phrase)) {
        exact.add(i);
      } else if (words.length > 1 &&
          (words.every(plain.contains) || words.every(uthmani.contains))) {
        loose.add(i);
      }
    }
    final total = exact.length + loose.length;
    return AyahSearchResult(
      total: total,
      matches: [
        for (final index in [...exact, ...loose].take(limit)) _match(index),
      ],
    );
  }

  AyahMatch _match(int index) {
    final ref = text.refAt(index);
    return AyahMatch(ref: ref, page: text.metadata.pageOf(ref.surah, ref.ayah));
  }
}
