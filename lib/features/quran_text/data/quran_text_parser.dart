/// Thrown when a Tanzil text file is not what the app expects.
class QuranTextFormatException implements Exception {
  /// Creates the exception with a short [message].
  const QuranTextFormatException(this.message);

  /// What was wrong.
  final String message;

  @override
  String toString() => 'QuranTextFormatException: $message';
}

/// Parses a Tanzil `txt-2` file (`surah|ayah|text` per line). Pure Dart.
abstract final class QuranTextParser {
  static final RegExp _line = RegExp(r'^(\d+)\|(\d+)\|(.+)$');

  /// Returns the text of every ayah in reading order.
  ///
  /// Checks that surahs run 1 to 114 and that ayahs count up from 1 inside each
  /// surah, without gaps. Comment lines (starting with `#`) and blank lines are
  /// skipped. [surahAyahCounts] holds the expected ayah count of each surah.
  static List<String> parse(String source, List<int> surahAyahCounts) {
    final texts = <String>[];
    var surah = 1;
    var ayah = 0;
    for (final raw in source.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty || line.startsWith('#')) continue;
      final match = _line.firstMatch(line);
      if (match == null) {
        throw QuranTextFormatException('Unreadable line: "$line"');
      }
      final lineSurah = int.parse(match[1]!);
      final lineAyah = int.parse(match[2]!);
      if (lineSurah == surah && lineAyah == ayah + 1) {
        ayah = lineAyah;
      } else if (lineSurah == surah + 1 && lineAyah == 1) {
        if (ayah != surahAyahCounts[surah - 1]) {
          throw QuranTextFormatException(
            'Surah $surah has $ayah ayahs; expected ${surahAyahCounts[surah - 1]}.',
          );
        }
        surah = lineSurah;
        ayah = 1;
      } else {
        throw QuranTextFormatException(
          'Unexpected ayah $lineSurah:$lineAyah after $surah:$ayah.',
        );
      }
      texts.add(match[3]!);
    }
    if (surah != surahAyahCounts.length ||
        ayah != surahAyahCounts.last ||
        texts.length != surahAyahCounts.fold(0, (a, b) => a + b)) {
      throw QuranTextFormatException(
        'Expected ${surahAyahCounts.fold(0, (a, b) => a + b)} ayahs; found ${texts.length}.',
      );
    }
    return texts;
  }
}
