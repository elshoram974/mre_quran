import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/svg_manifest_parser.dart';
import '../data/svg_page_store.dart';
import '../domain/svg_manifest.dart';
import '../domain/svg_page.dart';

/// The bundled list of page files and their checksums.
final svgManifestProvider = FutureProvider<SvgManifest>(
  (ref) async =>
      SvgManifestParser.parse(await rootBundle.loadString(SvgManifest.asset)),
);

/// Provides the page file store. Tests override it.
final svgPageStoreProvider = Provider<SvgPageStore>(
  (ref) => SvgPageStore(
    root: getApplicationSupportDirectory,
    manifest: () => ref.read(svgManifestProvider.future),
  ),
);

/// A printed page ready to draw, downloaded on first use. Dropped when no
/// page view shows it, since a page's artwork is large.
final svgPageProvider = FutureProvider.autoDispose.family<SvgPage, int>(
  (ref, page) => ref.watch(svgPageStoreProvider).page(page),
);
