/// The KFGQPC Hafs rows, one entry per ayah in reading order.
typedef KfgqpcHafsRows = ({
  List<String> text,
  List<String> marks,
  List<String> plain,
});

/// Parses the King Fahd Complex "Tafseer Mouaser" data file (tab-separated,
/// one ayah per row) into the Mushaf-script text, the ayah-number glyph that
/// ends each ayah, and the plain spelling the Complex provides for search.
///
/// Nothing is edited: the ayah text is the source's own, only separated from
/// its trailing number glyph at the no-break space the source puts there.
abstract final class KfgqpcHafsParser {
  static const int _surahColumn = 3;
  static const int _ayahColumn = 8;
  static const int _textColumn = 9;
  static const int _plainColumn = 10;
  static const String _markSeparator = ' ';

  /// Parses [source]. Throws [FormatException] unless it holds exactly the
  /// ayahs of [surahAyahCounts], in order.
  static KfgqpcHafsRows parse(String source, List<int> surahAyahCounts) {
    final text = <String>[];
    final marks = <String>[];
    final plain = <String>[];
    var surah = 1;
    var ayah = 0;
    // The first line names the columns.
    for (final line in source.split('\n').skip(1)) {
      if (line.trim().isEmpty) continue;
      final cells = line.split('\t');
      if (cells.length <= _plainColumn) {
        throw FormatException('Short row after $surah:$ayah');
      }
      ayah++;
      if (surah <= surahAyahCounts.length &&
          ayah > surahAyahCounts[surah - 1]) {
        surah++;
        ayah = 1;
      }
      if (int.tryParse(cells[_surahColumn]) != surah ||
          int.tryParse(cells[_ayahColumn]) != ayah) {
        throw FormatException(
          'Expected $surah:$ayah, found '
          '${cells[_surahColumn]}:${cells[_ayahColumn]}',
        );
      }
      final raw = cells[_textColumn];
      final cut = raw.lastIndexOf(_markSeparator);
      if (cut <= 0 || cut == raw.length - 1) {
        throw FormatException('No ayah mark at $surah:$ayah');
      }
      text.add(raw.substring(0, cut));
      marks.add(raw.substring(cut + 1));
      plain.add(cells[_plainColumn]);
    }
    final total = surahAyahCounts.fold(0, (sum, count) => sum + count);
    if (text.length != total) {
      throw FormatException('Expected $total ayahs, found ${text.length}');
    }
    return (text: text, marks: marks, plain: plain);
  }
}
