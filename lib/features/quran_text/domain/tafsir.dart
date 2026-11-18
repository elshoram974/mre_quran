import 'package:meta/meta.dart';

/// One run of an ayah's explanation: plain words, or the words of the
/// Quran it quotes, which are set in the Mushaf's script.
typedef TafsirPart = ({String text, bool quran});

/// The explanation of one ayah from Al-Tafsir Al-Muyassar, split into the
/// tafsir's own words and the Quran it quotes. The words are the source's,
/// unchanged; only the markup that marks the quotes is taken out.
@immutable
class Tafsir {
  /// Creates the tafsir of [parts], in reading order.
  const Tafsir(this.parts);

  /// Splits [source], whose quotes from the Quran are wrapped in
  /// `<span class='aya'>…</span>`, into its parts.
  factory Tafsir.parse(String source) {
    final parts = <TafsirPart>[];
    var at = 0;
    for (final match in _quote.allMatches(source)) {
      if (match.start > at) {
        parts.add((text: source.substring(at, match.start), quran: false));
      }
      parts.add((text: match.group(1)!, quran: true));
      at = match.end;
    }
    if (at < source.length) {
      parts.add((text: source.substring(at), quran: false));
    }
    return Tafsir(List.unmodifiable(parts));
  }

  static final RegExp _quote = RegExp(
    r'''<span class=['"]aya['"]>(.*?)</span>''',
  );

  /// The runs, in reading order.
  final List<TafsirPart> parts;

  /// The explanation as plain text, to copy: the quoted Quran inline.
  String get plain => parts.map((part) => part.text).join();
}
