import 'quran_metadata.dart';

/// Arabic diacritics, Quranic marks, and tatweel.
final RegExp _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');

/// Folds Arabic text for matching only.
///
/// This produces a derived search key. It never replaces the verbatim source
/// text shown to the reader. Diacritics and tatweel are removed, alef and ya
/// forms are unified, and Arabic-Indic digits become Latin digits.
String normalizeSearchKey(String input) {
  final buffer = StringBuffer();
  for (final rune in input.replaceAll(_marks, '').toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(switch (char) {
      'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
      'ى' || 'ئ' => 'ي',
      'ؤ' => 'و',
      'ة' => 'ه',
      _ when rune >= 0x0660 && rune <= 0x0669 => '${rune - 0x0660}',
      _ when rune >= 0x06F0 && rune <= 0x06F9 => '${rune - 0x06F0}',
      _ => char,
    });
  }
  return buffer.toString().trim();
}

/// Folds a surah name or query: [normalizeSearchKey] plus hyphens and
/// apostrophes as spaces, so "Al-Baqara" and "al baqara" are the same.
String _nameKey(String input) =>
    normalizeSearchKey(input)
        .replaceAll(RegExp(r"[-']+"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

/// Matches index entries against a query using search keys computed once.
///
/// Folding every name on every keystroke allocates heavily; building the keys
/// up front keeps typing smooth.
class IndexSearcher {
  /// Precomputes the search keys for [metadata].
  IndexSearcher(this.metadata)
    : _surahKeys = [
        for (final surah in metadata.surahs)
          [
            _nameKey(surah.arabicName),
            _nameKey(surah.transliteration),
            _nameKey(surah.englishName),
          ],
      ];

  /// The data being searched.
  final QuranMetadata metadata;

  final List<List<String>> _surahKeys;

  /// Names of each surah as folded keys, plus the Arabic name without the
  /// leading "ال", for exact matching.
  late final List<Set<String>> _exactKeys = [
    for (final keys in _surahKeys)
      {
        ...keys,
        if (keys.first.startsWith('ال') && keys.first.length > 2)
          keys.first.substring(2),
      },
  ];

  /// The surah named exactly [name] (Arabic with or without "ال", transliteration,
  /// or English), or null when no surah, or more than one, fits.
  Surah? resolveSurah(String name) {
    final key = _nameKey(name);
    if (key.isEmpty) return null;
    final exact = [
      for (var i = 0; i < _exactKeys.length; i++)
        if (_exactKeys[i].contains(key)) metadata.surahs[i],
    ];
    if (exact.length == 1) return exact.single;
    if (exact.length > 1) return null;
    final partial = surahs(key);
    return partial.length == 1 ? partial.single : null;
  }

  /// Surahs matching [query] by Arabic name, transliteration, English name, or
  /// number. An empty query returns every surah.
  List<Surah> surahs(String query) {
    final key = _nameKey(query);
    if (key.isEmpty) return metadata.surahs;
    return [
      for (var i = 0; i < metadata.surahs.length; i++)
        if ('${metadata.surahs[i].number}' == key ||
            _surahKeys[i].any((name) => name.contains(key)))
          metadata.surahs[i],
    ];
  }

  /// Juz matching [query] by number, or by the name of the surah it starts in.
  List<Juz> juzs(String query) {
    final key = normalizeSearchKey(query);
    if (key.isEmpty) return metadata.juzs;
    return [
      for (final juz in metadata.juzs)
        if ('${juz.number}' == key ||
            _surahKeys[juz.surah - 1].take(2).any((name) => name.contains(key)))
          juz,
    ];
  }
}
