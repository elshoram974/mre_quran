import 'package:meta/meta.dart';

import 'adhkar_collection.dart';
import 'dhikr.dart';

/// A result of an adhkar search.
@immutable
sealed class AdhkarSearchHit {
  const AdhkarSearchHit(this.collection);

  /// The list the result belongs to.
  final AdhkarCollection collection;
}

/// A list whose name matches.
final class CollectionHit extends AdhkarSearchHit {
  /// Creates a hit on [collection] itself.
  const CollectionHit(super.collection);
}

/// A dhikr whose words match.
final class DhikrHit extends AdhkarSearchHit {
  /// Creates a hit on [dhikr] of [collection], showing [snippet].
  const DhikrHit(super.collection, this.dhikr, this.snippet);

  /// The dhikr that matched.
  final Dhikr dhikr;

  /// The words around the match, with tashkeel.
  final String snippet;
}

/// Folds Arabic for matching: no tashkeel or tatweel, one form of alef, ya,
/// and ta marbuta, anything that is not a letter or a digit read as a space.
String foldForSearch(String text) => _fold(text).text;

({String text, List<int> origin}) _fold(String text) {
  final out = StringBuffer();
  final origin = <int>[];
  var lastSpace = true;
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    // Tashkeel, Quranic marks, and tatweel are skipped.
    if ((code >= 0x0610 && code <= 0x061a) ||
        (code >= 0x064b && code <= 0x065f) ||
        code == 0x0670 ||
        (code >= 0x06d6 && code <= 0x06ed) ||
        code == 0x0640) {
      continue;
    }
    final isLetter =
        (code >= 0x0621 && code <= 0x064a) ||
        (code >= 0x30 && code <= 0x39) ||
        (code >= 0x61 && code <= 0x7a) ||
        (code >= 0x41 && code <= 0x5a) ||
        (code >= 0x0660 && code <= 0x0669);
    if (!isLetter) {
      if (!lastSpace) {
        out.write(' ');
        origin.add(i);
        lastSpace = true;
      }
      continue;
    }
    final folded = switch (code) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 'ا',
      0x0649 => 'ي',
      0x0629 => 'ه',
      _ when code >= 0x41 && code <= 0x5a => String.fromCharCode(code + 32),
      _ => String.fromCharCode(code),
    };
    out.write(folded);
    origin.add(i);
    lastSpace = false;
  }
  return (text: out.toString().trimRight(), origin: origin);
}

/// Searches list names and the words of every dhikr.
///
/// Names come first, ranked by how early the match is; then the adhkar whose
/// words hold every word typed.
class AdhkarSearchIndex {
  /// Builds the index. [quranWords] gives the words of a Quran dhikr (its
  /// ayahs without tashkeel), or null when the Quran text is not available.
  AdhkarSearchIndex(
    AdhkarCatalog catalog, {
    String? Function(Dhikr dhikr) quranWords = _noWords,
  }) : _collections = [
         for (final collection in catalog.collections)
           _Entry(
             collection,
             titles: [
               for (final title in collection.titles.values)
                 foldForSearch(title),
             ],
             dhikr: [
               for (final dhikr in collection.entries)
                 if (_words(dhikr, quranWords) case final words?)
                   (dhikr: dhikr, folded: _fold(words), source: words),
             ],
           ),
       ];

  final List<_Entry> _collections;

  static String? _noWords(Dhikr dhikr) => null;

  static String? _words(Dhikr dhikr, String? Function(Dhikr) quranWords) {
    if (dhikr.quran == null) return dhikr.text;
    return quranWords(dhikr);
  }

  /// Results for [query], at most [limit] adhkar after the matching lists.
  List<AdhkarSearchHit> search(String query, {int limit = 60}) {
    final tokens = foldForSearch(query).split(' ')
      ..removeWhere((t) => t.isEmpty);
    if (tokens.isEmpty) return const [];
    final phrase = tokens.join(' ');

    final named = <(int, int, _Entry)>[];
    for (var i = 0; i < _collections.length; i++) {
      final entry = _collections[i];
      var best = -1;
      for (final title in entry.titles) {
        final score = title.startsWith(phrase)
            ? 0
            : title.split(' ').any((word) => word.startsWith(tokens.first)) &&
                  tokens.every(title.contains)
            ? 1
            : tokens.every(title.contains)
            ? 2
            : -1;
        if (score >= 0 && (best < 0 || score < best)) best = score;
      }
      if (best >= 0) named.add((best, i, entry));
    }
    named.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);

    final hits = <AdhkarSearchHit>[
      for (final (_, _, entry) in named) CollectionHit(entry.collection),
    ];
    final words = <(int, DhikrHit)>[];
    for (final entry in _collections) {
      for (final item in entry.dhikr) {
        final folded = item.folded.text;
        if (!tokens.every(folded.contains)) continue;
        final at = folded.indexOf(tokens.first);
        words.add((
          folded.startsWith(phrase) ? 0 : 1,
          DhikrHit(entry.collection, item.dhikr, _snippet(item, at)),
        ));
        if (words.length >= limit * 3) break;
      }
    }
    words.sort((a, b) => a.$1 - b.$1);
    hits.addAll([for (final (_, hit) in words.take(limit)) hit]);
    return hits;
  }

  /// About 120 characters of the original words around folded position [at].
  static String _snippet(
    ({Dhikr dhikr, ({String text, List<int> origin}) folded, String source})
    item,
    int at,
  ) {
    final source = item.source;
    final start = at <= 24 ? 0 : item.folded.origin[at - 24];
    var from = start;
    while (from > 0 && source[from] != ' ') {
      from--;
    }
    final end = (from + 120).clamp(0, source.length);
    var to = end;
    while (to < source.length && source[to] != ' ') {
      to++;
    }
    return '${from > 0 ? '… ' : ''}${source.substring(from, to).trim()}'
        '${to < source.length ? ' …' : ''}';
  }
}

class _Entry {
  const _Entry(this.collection, {required this.titles, required this.dhikr});

  final AdhkarCollection collection;
  final List<String> titles;
  final List<
    ({Dhikr dhikr, ({String text, List<int> origin}) folded, String source})
  >
  dhikr;
}
