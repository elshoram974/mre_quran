/// Reads Al-Tafsir Al-Muyassar from the King Fahd Complex's "Tafseer
/// Mouaser" data, the same file the Mushaf script comes from: one row per
/// ayah, in Quran order, the tafsir in its `aya_tafseer` column (see the
/// file's `read.me`).
abstract final class KfgqpcTafsirParser {
  static const int _tafsirColumn = 11;

  /// The tafsir of every ayah of [source], in Quran order. Throws a
  /// [FormatException] when a row has no tafsir or the count is not
  /// [ayahCount].
  static List<String> parse(String source, {required int ayahCount}) {
    final tafsir = <String>[];
    for (final line in source.split('\n').skip(1)) {
      if (line.trim().isEmpty) continue;
      final cells = line.split('\t');
      if (cells.length <= _tafsirColumn || cells[_tafsirColumn].isEmpty) {
        throw FormatException('No tafsir in row ${tafsir.length + 1}');
      }
      tafsir.add(cells[_tafsirColumn].trimRight());
    }
    if (tafsir.length != ayahCount) {
      throw FormatException('Tafsir rows: ${tafsir.length} of $ayahCount');
    }
    return List.unmodifiable(tafsir);
  }
}
