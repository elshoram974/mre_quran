import 'package:meta/meta.dart';

import '../../settings/domain/app_settings.dart';
import 'page_geometry.dart';

/// How a page image draws its script.
enum PageInk {
  /// Dark ink on a transparent sheet; the app tints the ink to the theme.
  transparent,

  /// Ink printed on an opaque paper colour, with a separate dark image.
  onPaper,
}

/// Where the ayah positions on an edition's pages come from.
enum PageGeometrySource {
  /// The edition's own glyph database, exact.
  glyphDatabase,

  /// Measured on the image against a line layout.
  measured,
}

/// One printed Mushaf edition: where its page images live and how to draw
/// and read them. Sources and licences: `docs/QURAN_SOURCES.md`, section 12.
@immutable
class MushafEdition {
  const MushafEdition._({
    required this.style,
    required this.width,
    required this.height,
    required this.ink,
    required this.geometry,
    required this.crop,
    required this.approxBytes,
    required this._path,
    this.darkPaper,
    this.bannerCircles,
  });

  /// The edition shown for [style].
  factory MushafEdition.of(MushafStyle style) => switch (style) {
    MushafStyle.madinah => madinah,
    MushafStyle.tajweed => tajweed,
    MushafStyle.madinahHd => madinahHd,
  };

  static const int _megabyte = 1024 * 1024;

  /// Pages in a printed Mushaf.
  static const int pageCount = 604;

  /// Every edition, in the order they are offered.
  static final List<MushafEdition> all = [madinah, tajweed, madinahHd];

  /// Quran.com's Madinah pages (the Quran for Android data set).
  static final madinah = MushafEdition._(
    style: MushafStyle.madinah,
    width: 1260,
    height: 2038,
    ink: PageInk.transparent,
    geometry: PageGeometrySource.glyphDatabase,
    crop: (left: 0, top: 0, right: 1, bottom: 1),
    approxBytes: 80 * _megabyte,
    // Measured on the banner of page 50: the two empty circles.
    bannerCircles: (start: 0.765, end: 0.231, diameter: 0.064),
    path: (page, _) =>
        'https://files.quran.app/hafs/madani/width_1260/'
        'page${page.toString().padLeft(3, '0')}.png',
  );

  /// SakinaDevGroup's tajweed-coloured pages.
  static final tajweed = MushafEdition._(
    style: MushafStyle.tajweed,
    width: 1080,
    height: 2160,
    ink: PageInk.onPaper,
    geometry: PageGeometrySource.measured,
    crop: _sakinaCrop,
    darkPaper: 0x0D0F12,
    approxBytes: 250 * _megabyte,
    path: (page, dark) =>
        'https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-tajweed-cdn@main/'
        '${dark ? 'dark' : 'light'}/p$page.png',
  );

  /// SakinaDevGroup's plain pages rendered from the KFGQPC V4 fonts.
  static final madinahHd = MushafEdition._(
    style: MushafStyle.madinahHd,
    width: 1080,
    height: 2160,
    ink: PageInk.onPaper,
    geometry: PageGeometrySource.measured,
    crop: _sakinaCrop,
    darkPaper: 0x0D0F12,
    approxBytes: 250 * _megabyte,
    path: (page, dark) =>
        'https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-madani-cdn@main/'
        '${dark ? 'dark' : 'light'}/p$page.png',
  );

  /// The Sakina pages' ink always lies inside this; their side margins are
  /// the same on every page.
  static const FractionRect _sakinaCrop = (
    left: 0.035,
    top: 0.04,
    right: 0.97,
    bottom: 0.97,
  );

  /// The style setting this edition answers to.
  final MushafStyle style;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// How the script is drawn.
  final PageInk ink;

  /// Where ayah positions come from.
  final PageGeometrySource geometry;

  /// Widest part of the image that can hold ink. Its sides are kept on every
  /// page so the script keeps one size.
  final FractionRect crop;

  /// Paper colour (0xRRGGBB) of the dark images, for [PageInk.onPaper].
  final int? darkPaper;

  /// Where the two empty circles of a surah banner lie, as fractions of the
  /// image width: the centre of the circle at the reading start (right), the
  /// centre of the one at the end (left), and their inner diameter. Null when
  /// the edition's banners have no such circles, or they have not been
  /// measured.
  final ({double start, double end, double diameter})? bannerCircles;

  /// Size of every image of the edition, light and dark, in bytes, measured
  /// on sample pages. For telling the reader what a download costs.
  final int approxBytes;

  final String Function(int page, bool dark) _path;

  /// Whether the edition has its own dark images.
  bool get hasDarkImages => ink == PageInk.onPaper;

  /// Address of the image of [page].
  Uri image(int page, {required bool dark}) =>
      Uri.parse(_path(page, dark && hasDarkImages));

  /// Where the image of [page] is kept, under the Mushaf folder of the app
  /// support directory. The file type follows the source, so a WebP source
  /// is kept as WebP.
  String imagePath(int page, {required bool dark}) {
    final url = image(page, dark: dark);
    final name = url.pathSegments.last;
    final extension = name.contains('.') ? name.split('.').last : 'img';
    final variant = dark && hasDarkImages ? 'dark' : 'light';
    return 'images/${style.name}/$variant/p$page.$extension';
  }

  /// The image files that make the edition work without a connection:
  /// every page, light and dark when the edition has both.
  List<({Uri url, String path})> get packFiles => [
    for (final dark in [false, if (hasDarkImages) true])
      for (var page = 1; page <= pageCount; page++)
        (url: image(page, dark: dark), path: imagePath(page, dark: dark)),
  ];
}
