import 'package:meta/meta.dart';
import 'package:mre_quran/core/assets/app_assets.dart';

/// How an edition's pages are drawn.
enum MushafPageKind {
  /// Vector pages from quran-ws/quran-svg: an SVG of the page and a JSON
  /// list of where each ayah lies. See `docs/QURAN_SOURCES.md`, section 14.
  svg,
}

/// A reading's own text, bundled with the app: copied and shared from its
/// pages. See `docs/QURAN_SOURCES.md`, section 15.
@immutable
class EditionText {
  /// Describes the text in [asset], drawn in [fontFamily].
  const EditionText({
    required this.asset,
    required this.sha256,
    required this.fontFamily,
    this.unmatchedSurahs = const {},
  });

  /// The bundled text file.
  final String asset;

  /// SHA-256 of the file's bytes, checked before it is used.
  final String sha256;

  /// The King Fahd Complex font of the reading.
  final String fontFamily;

  /// Surahs whose ayahs the text and the printed pages count differently.
  /// Their ayahs give no text, so none is ever tied to the wrong words.
  final Set<int> unmatchedSurahs;
}

/// One printed Mushaf the reader can show.
///
/// Every edition is a single entry in [MushafEditions.all]. Adding one takes
/// that entry and its manifest; nothing else in the app changes. How:
/// `docs/QURAN_SOURCES.md`, section 14, "Adding a Mushaf".
@immutable
class MushafEdition {
  /// Creates an edition.
  const MushafEdition({
    required this.id,
    required this.names,
    required this.manifestSha256,
    this.kind = MushafPageKind.svg,
    this.matchesAppText = false,
    this.spreadsLines = false,
    this.downloadGroupName,
    this.text,
  });

  /// The reading's own text, when the edition is not the app's text and
  /// its text is bundled.
  final EditionText? text;

  /// The edition's name in its source, its folder on the device, and the
  /// value saved in the settings. Never change it once released.
  final String id;

  /// What readers call it, by language code. A language without a name
  /// falls back to Arabic. These are the edition's own titles, like a
  /// surah's name, so they live with it and not in the app's strings.
  final Map<String, String> names;

  /// How its pages are drawn.
  final MushafPageKind kind;

  /// SHA-256 of its manifest's content, compactly re-encoded
  /// (`jsonEncode(jsonDecode(file))`), checked by a test.
  final String manifestSha256;

  /// Whether the app's own text matches these pages word for word and ayah
  /// for ayah. Only then may a page's ayah be copied, explained, bookmarked
  /// or highlighted from the app's text, and the text stand in for a page.
  final bool matchesAppText;

  /// Whether its lines are spread to fill a tall screen. Only for an edition
  /// whose files draw the script line by line on nearly every page, as
  /// `tool/check_svg_lines.dart` reports; the others keep their printed
  /// height throughout, so neighbouring pages never differ.
  final bool spreadsLines;

  /// Name of its offline download, when it is not the usual one.
  final String? downloadGroupName;

  /// Name of its offline download with the system downloader.
  String get downloadGroup => downloadGroupName ?? 'mushaf-svg-$id';

  /// Bundled asset holding its manifest.
  String get manifestAsset => AppAssets.svgManifest(id);

  /// Its name in [languageCode], or in Arabic.
  String name(String languageCode) => names[languageCode] ?? names['ar']!;

  @override
  bool operator ==(Object other) => other is MushafEdition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Every printed Mushaf the app offers, in the order it lists them.
abstract final class MushafEditions {
  /// Hafs from Asim: the reading of the app's text, search and tafsir.
  static const hafs = MushafEdition(
    id: 'hafs-kfqc',
    names: {'ar': 'حفص عن عاصم', 'en': 'Hafs from Asim'},
    manifestSha256:
        '198cd724391c97dd1c93d8bf5db5961403a1dce31d901293baa46442b7f24cc4',
    matchesAppText: true,
    spreadsLines: true,
    // The name it had when it was the only edition, so a download begun
    // then is still found.
    downloadGroupName: 'mushaf-svg',
  );

  /// Shu'bah from Asim.
  static const shubah = MushafEdition(
    id: 'shubah-kfqc',
    names: {'ar': 'شعبة عن عاصم', 'en': "Shu'bah from Asim"},
    text: EditionText(
      asset: AppAssets.shubahText,
      sha256:
          '5cd0a2e1ce5ed51e2e5638455a3b0d666acfc9d58cc1eb514f45dcac464ed00e',
      fontFamily: 'KfgqpcShubah',
    ),
    manifestSha256:
        '59ad875d1ab8f84c45c68adf22e2c252f7221b51f68f299dafbfb9714977ffa9',
  );

  /// Warsh from Nafi'.
  static const warsh = MushafEdition(
    id: 'warsh-kfqc',
    names: {'ar': 'ورش عن نافع', 'en': "Warsh from Nafi'"},
    // 469 of its 604 pages draw their script line by line; the others keep
    // their printed height.
    spreadsLines: true,
    text: EditionText(
      asset: AppAssets.warshText,
      sha256:
          'cbeedd60925ef4a88bee92480a197aa8c22026d433ceaaf79005a37d1d2c5890',
      fontFamily: 'KfgqpcWarsh',
    ),
    manifestSha256:
        'df541939a31ce75511ce73eabe02fdd9974157828566d5d16d747e529bf02ff3',
  );

  /// Qalun from Nafi'.
  static const qalon = MushafEdition(
    id: 'qalon-kfqc',
    names: {'ar': 'قالون عن نافع', 'en': "Qalun from Nafi'"},
    text: EditionText(
      asset: AppAssets.qalonText,
      sha256:
          '86aba2d384f5e2f0927c81a70c8062af8765924243c9ae304e5c5642388d8fcd',
      fontFamily: 'KfgqpcQalon',
    ),
    manifestSha256:
        'da6f77792cc2047a3d28af22ef2b9f6564337c4c1724a30e3259236bd2369084',
  );

  /// Al-Duri from Abu Amr.
  static const douri = MushafEdition(
    id: 'douri-kfqc',
    names: {'ar': 'الدوري عن أبي عمرو', 'en': 'Al-Duri from Abu Amr'},
    text: EditionText(
      asset: AppAssets.douriText,
      sha256:
          '9b5e13f4ee7a952f886baf6e1810ad32d4adb13138848da7a02ff9ea7bc08083',
      fontFamily: 'KfgqpcDouri',
      // Al-Mulk: 30 ayahs in the text, 31 on the pages (a known difference
      // in counting; see the quran-svg repository's qiraat_map notes).
      unmatchedSurahs: {67},
    ),
    manifestSha256:
        '14e2a34164c3ccd8507cdda714629d9a5e3870f3ede4cbefe3efea22fce7a90e',
  );

  /// All of them. The first is the default.
  static const List<MushafEdition> all = [hafs, shubah, warsh, qalon, douri];

  /// The edition saved as [id], or null when there is none such.
  static MushafEdition? byId(String? id) {
    for (final edition in all) {
      if (edition.id == id) return edition;
    }
    return null;
  }
}
