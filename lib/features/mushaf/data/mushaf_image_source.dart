/// Where printed-Mushaf page images and their line layouts come from.
///
/// Images: Madinah Mushaf pages rendered from the KFGQPC V4 fonts by the
/// SakinaDevGroup `mushaf-madani-cdn` repository (PNG, 1080×2160, light and
/// dark). Layout: which words sit on which line, from the `zonetecde/mushaf-layout`
/// repository. Neither repository declares a licence; the project owner has
/// taken on the permission question (`docs/QURAN_SOURCES.md`, section 12).
/// Files are downloaded on demand, cached on the device, and never bundled.
abstract final class MushafImageSource {
  /// Image of [page] in the light or dark rendering.
  static Uri pageImage(int page, {required bool dark}) => Uri.parse(
    'https://cdn.jsdelivr.net/gh/SakinaDevGroup/mushaf-madani-cdn@main/'
    '${dark ? 'dark' : 'light'}/p$page.png',
  );

  /// Line layout of [page].
  static Uri pageLayout(int page) => Uri.parse(
    'https://raw.githubusercontent.com/zonetecde/mushaf-layout/refs/heads/main/'
    'mushaf/page-${page.toString().padLeft(3, '0')}.json',
  );
}
