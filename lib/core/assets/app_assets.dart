/// Paths of the bundled files that more than one place names.
///
/// Each path must match an entry under `flutter: assets:` in `pubspec.yaml`.
abstract final class AppAssets {
  /// The licence of the Amiri Quran font.
  static const String amiriQuranLicense = 'assets/fonts/amiri_quran/OFL.txt';

  /// The licence of the adhkar database.
  static const String adhkarLicense = 'assets/adhkar/LICENSE.seen-arabic.txt';

  /// The folder of the other readings' verse texts.
  static const String riwayatFolder = 'assets/quran/riwayat';

  /// The folder of the page manifests, one per Mushaf.
  static const String svgManifestFolder = 'assets/quran/svg';

  /// Verse text of Shu'bah's reading.
  static const String shubahText = '$riwayatFolder/shubah_kfqc.txt';

  /// Verse text of Warsh's reading.
  static const String warshText = '$riwayatFolder/warsh_kfqc.txt';

  /// Verse text of Qalun's reading.
  static const String qalonText = '$riwayatFolder/qalon_kfqc.txt';

  /// Verse text of Al-Duri's reading.
  static const String douriText = '$riwayatFolder/douri_kfqc.txt';

  /// The page manifest of the Mushaf with edition id [id].
  static String svgManifest(String id) =>
      '$svgManifestFolder/${id.replaceAll('-', '_')}_manifest.json';
}
