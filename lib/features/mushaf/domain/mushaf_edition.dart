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
    this.hafsMap,
    this.hafsMapSha256,
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

  /// Which Hafs ayah(s) each ayah is, where its number does not say
  /// (`surah|ayah|hafs,hafs` lines from `tool/build_riwaya_tafsir_map.py`),
  /// so its tafsir is the right one. Null for a reading that counts as Hafs.
  final String? hafsMap;

  /// SHA-256 of [hafsMap], checked before it is used.
  final String? hafsMapSha256;
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
    this.linesInDrawingOrder = true,
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

  /// Whether its files draw the script line by line, so the drawing order
  /// tells the lines apart (`tool/check_svg_lines.dart` reports it). When
  /// it does not, each outline is placed on a line by where it lies, which
  /// is wrong for about three outlines in ten thousand. Every edition's
  /// lines are spread to fill a tall screen either way.
  final bool linesInDrawingOrder;

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
        'df84c7faa1dfe9bf541af46d35c2e55a1815c59a2dd6f900343fdcfacb413a6e',
    matchesAppText: true,
    // The name it had when it was the only edition, so a download begun
    // then is still found.
    downloadGroupName: 'mushaf-svg',
  );

  /// Shu'bah from Asim.
  static const shubah = MushafEdition(
    id: 'shubah-kfqc',
    // Its outlines are drawn grouped by shape, not line by line.
    linesInDrawingOrder: false,
    names: {'ar': 'شعبة عن عاصم', 'en': "Shu'bah from Asim"},
    text: EditionText(
      asset: AppAssets.shubahText,
      sha256:
          '5cd0a2e1ce5ed51e2e5638455a3b0d666acfc9d58cc1eb514f45dcac464ed00e',
      fontFamily: 'KfgqpcShubah',
    ),
    manifestSha256:
        'b3735975b5b713f07649e2319553c45d266dbdaca9485825d6b086582be014aa',
  );

  /// Warsh from Nafi'.
  static const warsh = MushafEdition(
    id: 'warsh-kfqc',
    names: {'ar': 'ورش عن نافع', 'en': "Warsh from Nafi'"},
    text: EditionText(
      asset: AppAssets.warshText,
      hafsMap: 'assets/quran/riwayat/warsh_hafs.txt',
      hafsMapSha256:
          '75976296adf358e8171bbc7aeb4909b2a66f50cd4c2178ac58fd08fa96de33ea',
      sha256:
          'cbeedd60925ef4a88bee92480a197aa8c22026d433ceaaf79005a37d1d2c5890',
      fontFamily: 'KfgqpcWarsh',
    ),
    manifestSha256:
        'd4a1708419ba22755f0626127e5932f3d65b5a626499c7928cd0f1131091bfce',
  );

  /// Qalun from Nafi'.
  static const qalon = MushafEdition(
    id: 'qalon-kfqc',
    // Its outlines are drawn grouped by shape, not line by line.
    linesInDrawingOrder: false,
    names: {'ar': 'قالون عن نافع', 'en': "Qalun from Nafi'"},
    text: EditionText(
      asset: AppAssets.qalonText,
      hafsMap: 'assets/quran/riwayat/qalon_hafs.txt',
      hafsMapSha256:
          '75976296adf358e8171bbc7aeb4909b2a66f50cd4c2178ac58fd08fa96de33ea',
      sha256:
          '86aba2d384f5e2f0927c81a70c8062af8765924243c9ae304e5c5642388d8fcd',
      fontFamily: 'KfgqpcQalon',
    ),
    manifestSha256:
        '5021c66e156cf2e1403336b5be532d0dcab7fca5ddb1aab9f594fd3d97a8aa42',
  );

  /// Al-Duri from Abu Amr.
  static const douri = MushafEdition(
    id: 'douri-kfqc',
    // Its outlines are drawn grouped by shape, not line by line.
    linesInDrawingOrder: false,
    names: {'ar': 'الدوري عن أبي عمرو', 'en': 'Al-Duri from Abu Amr'},
    text: EditionText(
      asset: AppAssets.douriText,
      hafsMap: 'assets/quran/riwayat/douri_hafs.txt',
      hafsMapSha256:
          'edab3a6bf280b9347580353480ea931e2edb99ac263abade53996716ea812997',
      sha256:
          '9b5e13f4ee7a952f886baf6e1810ad32d4adb13138848da7a02ff9ea7bc08083',
      fontFamily: 'KfgqpcDouri',
      // Al-Mulk: 30 ayahs in the text, 31 on the pages (a known difference
      // in counting; see the quran-svg repository's qiraat_map notes).
      unmatchedSurahs: {67},
    ),
    manifestSha256:
        '849a890f5790f086cfe65da5dcba16db2e9669785a7ab603cb94b4ce5ae9dbf8',
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
