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
/// alef, ya, ta marbuta, and digits). Each ayah has up to three folded keys:
/// the plain spelling ("العالمين"), the Uthmani spelling, which writes some
/// alefs as dagger alefs ("العلمين"), and the King Fahd Complex's own plain
/// spelling. A query written any of these ways matches. Keys are built once,
/// off the main isolate, with [buildKeys].
class AyahSearchIndex {
  /// Creates an index over [text] using precomputed keys. [plainKeys] is the
  /// optional third spelling.
  AyahSearchIndex({
    required this.text,
    required List<String> keys,
    required List<String> uthmaniKeys,
    List<String>? plainKeys,
  }) : _keys = [keys, uthmaniKeys, ?plainKeys] {
    for (final list in _keys) {
      if (list.length != text.length) {
        throw ArgumentError(
          'Expected ${text.length} keys; got ${list.length}.',
        );
      }
    }
  }

  /// The text being searched.
  final QuranText text;

  /// One list of folded keys per spelling.
  final List<List<String>> _keys;

  static final RegExp _spaces = RegExp(r'\s+');

  /// Folded search keys for [lines] of Quran text, single-spaced.
  static List<String> buildKeys(List<String> lines) => [
    for (final line in lines) normalizeSearchKey(line).replaceAll(_spaces, ' '),
  ];

  /// Finds ayahs containing [query], best matches first:
  ///
  /// 1. the words together, in order, as whole words;
  /// 2. the words together as part of longer words ("من" inside "المؤمنين");
  /// 3. every word somewhere in the ayah.
  ///
  /// Each group keeps Quran order.
  AyahSearchResult search(String query, {int limit = 100}) {
    final phrase = normalizeSearchKey(query).replaceAll(_spaces, ' ');
    if (phrase.isEmpty || limit <= 0) return AyahSearchResult.empty;
    final words = phrase.split(' ');
    // Most verses miss the longest word. Reject them before testing the
    // complete phrase or checking the other words in each spelling.
    final longest = words.reduce((a, b) => a.length >= b.length ? a : b);
    final remaining = words.where((word) => word != longest).toList();
    final singleWord = words.length == 1;
    final padded = ' $phrase ';

    final whole = <int>[];
    final partial = <int>[];
    final loose = <int>[];
    for (var i = 0; i < text.length; i++) {
      var best = _Rank.none;
      for (final keys in _keys) {
        final key = keys[i];
        if (!key.contains(longest)) continue;
        if (singleWord || key.contains(phrase)) {
          // Only check word boundaries on verses that contain the phrase.
          if (' $key '.contains(padded)) {
            best = _Rank.whole;
            break;
          }
          best = _Rank.partial;
        } else if (best == _Rank.none && remaining.every(key.contains)) {
          best = _Rank.loose;
        }
      }
      switch (best) {
        case _Rank.whole:
          whole.add(i);
        case _Rank.partial:
          partial.add(i);
        case _Rank.loose:
          loose.add(i);
        case _Rank.none:
      }
    }
    return AyahSearchResult(
      total: whole.length + partial.length + loose.length,
      matches: [
        for (final index in [...whole, ...partial, ...loose].take(limit))
          _match(index),
      ],
    );
  }

  AyahMatch _match(int index) {
    final ref = text.refAt(index);
    return AyahMatch(ref: ref, page: text.metadata.pageOf(ref.surah, ref.ayah));
  }
}

/// How well an ayah fits a query.
enum _Rank { whole, partial, loose, none }
