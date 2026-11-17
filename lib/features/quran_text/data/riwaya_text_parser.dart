import '../../quran_index/domain/quran_metadata.dart';
import '../domain/ayah_texts.dart';

/// Reads a reading's text file: one ayah per line, `surah|ayah|page|text|mark`,
/// as `tool/build_riwaya_text.py` writes it (see `docs/QURAN_SOURCES.md`,
/// section 15).
abstract final class RiwayaTextParser {
  /// The ayahs of [source]. Throws [FormatException] on a broken line.
  static Map<AyahRef, RiwayaAyah> parse(String source) {
    final ayahs = <AyahRef, RiwayaAyah>{};
    for (final line in source.split('\n')) {
      if (line.isEmpty) continue;
      final parts = line.split('|');
      if (parts.length != 5) {
        throw FormatException('Broken ayah line', line);
      }
      final surah = int.tryParse(parts[0]);
      final ayah = int.tryParse(parts[1]);
      final page = int.tryParse(parts[2]);
      if (surah == null || ayah == null || page == null || parts[3].isEmpty) {
        throw FormatException('Broken ayah line', line);
      }
      ayahs[AyahRef(surah, ayah)] = (
        text: parts[3],
        mark: parts[4],
        page: page,
      );
    }
    if (ayahs.isEmpty) throw const FormatException('No ayahs');
    return ayahs;
  }
}
