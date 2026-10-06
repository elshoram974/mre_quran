/// Downloadable data for the printed Mushaf other than the page images
/// (those are listed per edition in `MushafEdition`).
///
/// Sources and licences: `docs/QURAN_SOURCES.md`, section 12. Files are
/// downloaded on demand, cached on the device, and never bundled.
abstract final class MushafSources {
  /// Glyph database of the Quran.com Madinah pages (Quran for Android
  /// `ayahinfo_1024`), zipped. Coordinates are for 1024 × 1656 pixels.
  static final Uri ayahInfo = Uri.parse(
    'https://files.quran.app/hafs/madani/width_1024/ayahinfo_1024.zip',
  );

  /// SHA-256 of [ayahInfo], checked before use.
  static const String ayahInfoSha256 =
      'b36fce9dab5275a0324b9cf78f67e6b6167cb68661ee53c64861217135b8eaa1';

  /// Name of the database file inside the zip.
  static const String ayahInfoEntry = 'ayahinfo_1024.db';

  /// SHA-256 of the extracted database, checked before use.
  static const String ayahInfoDbSha256 =
      '30fa152370e19097ad1b4ddac2ea59a05f7ad0a4aa932b427ed87047c75cef69';

  /// Size of the page images the glyph coordinates are measured on.
  static const int ayahInfoWidth = 1024;

  /// See [ayahInfoWidth].
  static const int ayahInfoHeight = 1656;
}
