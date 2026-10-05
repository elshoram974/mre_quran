import '../../quran_index/domain/index_search.dart';

/// The text with the basmala separated from the first ayah of each surah.
class BasmalaSplit {
  /// Creates a split.
  const BasmalaSplit({
    required this.basmala,
    required this.uthmani,
    required this.clean,
    required this.prefixed,
  });

  /// The basmala as written in ayah 1:1 of the source (display spelling).
  final String basmala;

  /// Display text, one entry per ayah, without the basmala prefix.
  final List<String> uthmani;

  /// Plain text, one entry per ayah, without the basmala prefix.
  final List<String> clean;

  /// For each surah (index 0 is surah 1): whether the source put the basmala
  /// in front of its first ayah.
  final List<bool> prefixed;
}

/// Separates the basmala that the Tanzil files put in front of the first ayah
/// of most surahs.
///
/// Tanzil writes ayah 1:1 as the basmala itself and prefixes the basmala to the
/// first ayah of every other surah except At-Tawba. The prefix is not part of
/// those ayahs, so showing or searching it would be wrong. Nothing is typed or
/// edited here: the basmala is read from 1:1, the prefix is recognised by
/// folding the first words of each first ayah, and what remains is a verbatim
/// tail of the source line.
///
/// Throws [FormatException] if a first ayah starts with something that looks
/// like the basmala in one file but not the other, or if its text is too short.
BasmalaSplit splitBasmala({
  required List<int> surahAyahCounts,
  required List<String> uthmani,
  required List<String> clean,
}) {
  final basmala = uthmani.first;
  final key = normalizeSearchKey(clean.first);
  final wordCount = clean.first.split(' ').length;

  String tail(String line, int surah) {
    final words = line.split(' ');
    if (words.length <= wordCount) {
      throw FormatException('Surah $surah first ayah is only the basmala.');
    }
    return words.sublist(wordCount).join(' ');
  }

  bool startsWithBasmala(String line) {
    final words = line.split(' ');
    return words.length > wordCount &&
        normalizeSearchKey(words.take(wordCount).join(' ')) == key;
  }

  final newUthmani = List<String>.of(uthmani);
  final newClean = List<String>.of(clean);
  final prefixed = <bool>[];
  var index = 0;
  for (var surah = 1; surah <= surahAyahCounts.length; surah++) {
    final cleanHas = startsWithBasmala(clean[index]);
    final uthmaniHas = startsWithBasmala(uthmani[index]);
    if (surah == 1) {
      prefixed.add(false);
    } else if (cleanHas && uthmaniHas) {
      newUthmani[index] = tail(uthmani[index], surah);
      newClean[index] = tail(clean[index], surah);
      prefixed.add(true);
    } else if (!cleanHas && !uthmaniHas) {
      prefixed.add(false);
    } else {
      throw FormatException(
        'Surah $surah: the two texts disagree about a basmala prefix.',
      );
    }
    index += surahAyahCounts[surah - 1];
  }
  return BasmalaSplit(
    basmala: basmala,
    uthmani: newUthmani,
    clean: newClean,
    prefixed: prefixed,
  );
}
