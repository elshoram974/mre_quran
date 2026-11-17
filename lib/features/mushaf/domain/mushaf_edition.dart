import 'package:meta/meta.dart';

/// How an edition's pages are drawn.
enum MushafPageKind {
  /// Vector pages from quran-ws/quran-svg: an SVG of the page and a JSON
  /// list of where each ayah lies. See `docs/QURAN_SOURCES.md`, section 14.
  svg,
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
  });

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
  String get manifestAsset =>
      'assets/quran/svg/${id.replaceAll('-', '_')}_manifest.json';

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
    manifestSha256:
        '59ad875d1ab8f84c45c68adf22e2c252f7221b51f68f299dafbfb9714977ffa9',
  );

  /// Warsh from Nafi'.
  static const warsh = MushafEdition(
    id: 'warsh-kfqc',
    names: {'ar': 'ورش عن نافع', 'en': "Warsh from Nafi'"},
    manifestSha256:
        'df541939a31ce75511ce73eabe02fdd9974157828566d5d16d747e529bf02ff3',
  );

  /// Qalun from Nafi'.
  static const qalon = MushafEdition(
    id: 'qalon-kfqc',
    names: {'ar': 'قالون عن نافع', 'en': "Qalun from Nafi'"},
    manifestSha256:
        'da6f77792cc2047a3d28af22ef2b9f6564337c4c1724a30e3259236bd2369084',
  );

  /// Al-Duri from Abu Amr.
  static const douri = MushafEdition(
    id: 'douri-kfqc',
    names: {'ar': 'الدوري عن أبي عمرو', 'en': 'Al-Duri from Abu Amr'},
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
