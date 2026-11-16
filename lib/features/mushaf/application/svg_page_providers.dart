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
      (settings) => settings.value?.mushafEdition ?? MushafEdition.hafs,
    ),
  ),
);

/// The bundled list of an edition's page files and their checksums.
final svgManifestProvider = FutureProvider.family<SvgManifest, MushafEdition>(
  (ref, edition) async => SvgManifestParser.parse(
    await rootBundle.loadString(SvgManifest.assetOf(edition)),
  ),
);

/// Provides the page file store of an edition. Tests override it.
final svgPageStoreProvider = Provider.family<SvgPageStore, MushafEdition>(
  (ref, edition) => SvgPageStore(
    root: getApplicationSupportDirectory,
    manifest: () => ref.read(svgManifestProvider(edition).future),
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
final svgPageProvider = FutureProvider.autoDispose
    .family<SvgPagePicture, SvgPageRequest>((ref, request) async {
      final edition = ref.watch(printedEditionProvider);
      final picture = await ref
          .watch(svgPageStoreProvider(edition))
          .page(request.page, stretch: request.stretch / 1000);
      // Only a page that was prepared is kept; a failure is tried afresh.
      ref.read(recentPagesProvider).hold(request, ref.keepAlive().close);
      return picture;
    });

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
