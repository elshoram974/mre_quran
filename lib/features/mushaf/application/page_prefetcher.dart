import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../../settings/domain/app_settings.dart';
import '../data/page_asset_store.dart';
import '../domain/mushaf_edition.dart';
import 'page_image_providers.dart';

/// Downloads the printed pages around the reader ahead of time.
final pagePrefetcherProvider = Provider<PagePrefetcher>(
  (ref) => PagePrefetcher(ref.watch(pageAssetStoreProvider)),
);

/// Fetches the pages after the current one, then a few before it, one at a
/// time, so turning pages never waits on the network. A newer request
/// replaces an older one.
class PagePrefetcher {
  /// Creates a prefetcher over [store].
  PagePrefetcher(this._store);

  final PageAssetStore _store;
  int _generation = 0;

  /// Pages fetched ahead of the current one.
  static const int ahead = 8;

  /// Pages fetched behind the current one.
  static const int behind = 2;

  /// Fetches the pages around [page] of [style].
  void around({
    required MushafStyle style,
    required int page,
    required bool dark,
    required int pageCount,
  }) {
    final generation = ++_generation;
    final edition = MushafEdition.of(style);
    final pages = [
      for (var p = page + 1; p <= page + ahead && p <= pageCount; p++) p,
      for (var p = page - 1; p >= page - behind && p >= 1; p--) p,
    ];
    unawaited(_run(generation, edition, pages, dark));
  }

  /// Pages fetched at the same time. The page being read never waits for
  /// them: it is requested on its own, outside this pool.
  static const int parallel = 3;

  /// Failed fetches in a row after which prefetching gives up (offline).
  static const int giveUpAfter = 3;

  Future<void> _run(
    int generation,
    MushafEdition edition,
    List<int> pages,
    bool dark,
  ) async {
    if (edition.geometry == PageGeometrySource.glyphDatabase) {
      // Not awaited: it runs beside the images, and the page on screen needs
      // it as much as they do.
      unawaited(
        _store.ayahInfoDatabase().then<void>(
          (_) {},
          onError: (Object error) =>
              AppLogger.debug('Glyph database failed: ${error.runtimeType}'),
        ),
      );
    }
    final queue = pages.iterator;
    var failures = 0;
    Future<void> worker() async {
      while (generation == _generation && failures < giveUpAfter) {
        if (!queue.moveNext()) return;
        final page = queue.current;
        try {
          await _store.image(edition, page, dark: dark);
          // Ayah positions are measured on the light image.
          if (edition.geometry == PageGeometrySource.measured && dark) {
            await _store.image(edition, page, dark: false);
          }
          failures = 0;
        } on Exception catch (error) {
          // Offline, a bad response, or a full disk: the page tries again
          // when it is opened.
          failures++;
          AppLogger.debug('Prefetch failed: ${error.runtimeType}');
        }
      }
    }

    await Future.wait([for (var i = 0; i < parallel; i++) worker()]);
  }
}
