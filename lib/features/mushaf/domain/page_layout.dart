import 'dart:convert';

import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// Kind of a line on a printed Mushaf page.
enum LayoutLineType {
  /// The decorated surah title.
  surahHeader,

  /// The basmala line under a surah title.
  basmala,

  /// A line of ayah text.
  text,
}

/// One word on a line, in reading order.
@immutable
class LayoutWord {
  /// Creates a word of [ayah] at position [index] (1-based) in that ayah.
  const LayoutWord({
    required this.ayah,
    required this.index,
    required this.text,
  });

  /// The ayah the word belongs to.
  final AyahRef ayah;

  /// Position of the word in its ayah, 1-based.
  final int index;

  /// The word as written, used only to estimate its width.
  final String text;
}

/// One line of a printed page, top to bottom.
@immutable
class LayoutLine {
  /// Creates a line.
  const LayoutLine({required this.type, required this.words});

  /// What the line holds.
  final LayoutLineType type;

  /// Words on the line, right to left. Empty for headers and the basmala.
  final List<LayoutWord> words;
}

/// Which words sit on which line of one printed page.
@immutable
class PageLayout {
  /// Creates a layout.
  const PageLayout({required this.page, required this.lines});

  /// Reads a page layout JSON (`{"page": n, "lines": [...]}`, each line with
  /// a `type` and `words` carrying `location` as `surah:ayah:word`).
  ///
  /// Throws [FormatException] when the JSON does not have that shape.
  factory PageLayout.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException {
      rethrow;
    }
    if (json is! Map<String, Object?>) {
      throw const FormatException('Layout is not an object.');
    }
    final page = json['page'];
    final rawLines = json['lines'];
    if (page is! int || rawLines is! List<Object?>) {
      throw const FormatException('Layout needs "page" and "lines".');
    }
    final lines = <LayoutLine>[];
    for (final raw in rawLines) {
      if (raw is! Map<String, Object?>) {
        throw const FormatException('Line is not an object.');
      }
      final type = switch (raw['type']) {
        'surah-header' => LayoutLineType.surahHeader,
        'basmala' => LayoutLineType.basmala,
        'text' => LayoutLineType.text,
        _ => throw FormatException('Unknown line type ${raw['type']}.'),
      };
      final words = <LayoutWord>[];
      final rawWords = raw['words'];
      if (rawWords is List<Object?>) {
        for (final word in rawWords) {
          if (word is! Map<String, Object?>) {
            throw const FormatException('Word is not an object.');
          }
          final location = word['location'];
          final text = word['word'];
          final parts = location is String
              ? location.split(':')
              : const <String>[];
          final numbers = [for (final p in parts) int.tryParse(p)];
          if (numbers.length != 3 ||
              numbers.contains(null) ||
              text is! String) {
            throw FormatException('Bad word location $location.');
          }
          words.add(
            LayoutWord(
              ayah: AyahRef(numbers[0]!, numbers[1]!),
              index: numbers[2]!,
              text: text,
            ),
          );
        }
      }
      lines.add(LayoutLine(type: type, words: List.unmodifiable(words)));
    }
    return PageLayout(page: page, lines: List.unmodifiable(lines));
  }

  /// Page number.
  final int page;

  /// Lines, top to bottom.
  final List<LayoutLine> lines;
}
