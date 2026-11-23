import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../data/svg_manifest_parser.dart';
import '../data/svg_page_store.dart';
import '../domain/svg_manifest.dart';
import '../domain/svg_page.dart';

/// The reading whose printed pages the reader shows.
final printedEditionProvider = Provider<MushafEdition>(
  (ref) => ref.watch(
    settingsProvider.select(
      (settings) => settings.value?.mushafEdition ?? MushafEditions.hafs,
    ),
  ),
);

/// The bundled list of an edition's page files and their checksums.
final svgManifestProvider = FutureProvider.family<SvgManifest, MushafEdition>(
  (ref, edition) async => SvgManifestParser.parse(
    await rootBundle.loadString(edition.manifestAsset),
  ),
);

/// Provides the page file store of an edition. Tests override it.
final svgPageStoreProvider = Provider.family<SvgPageStore, MushafEdition>(
  (ref, edition) => SvgPageStore(
    root: getApplicationSupportDirectory,
    manifest: () => ref.read(svgManifestProvider(edition).future),
    ordered: edition.linesInDrawingOrder,
  ),
);

/// Which page to prepare, and how far to spread its lines: [stretch] is the
/// page's height in thousandths of its printed height, so 1000 is as
/// printed.
typedef SvgPageRequest = ({int page, int stretch});

/// A printed page ready to paint, downloaded on first use.
///
/// The pages used last stay ready after their views are gone (see
/// [RecentPages]), so turning back, or on to a page made ready ahead of the
/// reader, shows it at once.
///
/// A page that fails is not tried again by itself: Riverpod's own retry
/// would download it over and over while offline, and show the old failure
/// while it does. The page view's retry button, and the reader's offline
/// fallback, try it again when there is reason to.
final svgPageProvider = FutureProvider.autoDispose
    .family<SvgPagePicture, SvgPageRequest>((ref, request) async {
      final edition = ref.watch(printedEditionProvider);
      // Taken before the wait: the provider may be rebuilt (a retry) or gone
      // by the time the page is ready, and its ref with it.
      final recent = ref.read(recentPagesProvider);
      final picture = await ref
          .watch(svgPageStoreProvider(edition))
          .page(request.page, stretch: request.stretch / 1000);
      // Only a page that was prepared, by a build still current, is kept; a
      // failure is tried afresh.
      if (ref.mounted) recent.hold(request, ref.keepAlive().close);
      return picture;
    }, retry: (_, _) => null);

/// Provides the list of pages kept ready.
final recentPagesProvider = Provider<RecentPages>((ref) => RecentPages());

/// Keeps the pages used last ready to paint, and lets the oldest go once
/// there are more than [capacity]. A prepared page is about half a
/// megabyte.
class RecentPages {
  /// Creates the list, keeping up to [capacity] pages.
  RecentPages({this.capacity = 16});

  /// How many pages stay ready.
  final int capacity;

  final Map<SvgPageRequest, void Function()> _held = {};

  /// Keeps [request] ready, as the page used last, until [release] is
  /// called: that lets the page go once nothing shows it.
  void hold(SvgPageRequest request, void Function() release) {
    _held.remove(request)?.call();
    _held[request] = release;
    while (_held.length > capacity) {
      _held.remove(_held.keys.first)!();
    }
  }
}
