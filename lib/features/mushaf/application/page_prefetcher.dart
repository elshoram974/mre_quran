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

  Future<void> _run(
    int generation,
    MushafEdition edition,
    List<int> pages,
    bool dark,
  ) async {
    try {
      if (edition.geometry == PageGeometrySource.glyphDatabase) {
        await _store.ayahInfoDatabase();
      }
      for (final page in pages) {
        if (generation != _generation) return;
        await _store.image(edition, page, dark: dark);
        if (edition.geometry == PageGeometrySource.measured) {
          await _store.layout(page);
          // Ayah positions are measured on the light image.
          if (dark) await _store.image(edition, page, dark: false);
        }
      }
    } on Exception catch (error) {
      // Offline, a bad response, or a full disk: the page tries again when
      // it is opened.
      AppLogger.debug('Prefetch stopped: ${error.runtimeType}');
    }
  }
}
