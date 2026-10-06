import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../quran_index/application/quran_metadata_provider.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../settings/domain/app_settings.dart';
import '../data/ayah_info_database.dart';
import '../data/mushaf_sources.dart';
import '../data/page_asset_store.dart';
import '../domain/mushaf_edition.dart';
import '../domain/page_geometry.dart';
import '../domain/sakina_pages.dart';

/// Which rendering of a page: its edition, number, and light or dark.
typedef PageImageKey = ({MushafStyle style, int page, bool dark});

/// Which page's ayah positions.
typedef PageGeometryKey = ({MushafStyle style, int page});

/// Provides the page file store. Tests override it.
final pageAssetStoreProvider = Provider<PageAssetStore>(
  (ref) => PageAssetStore(root: getApplicationSupportDirectory),
);

/// The image file of a page, downloaded on first use.
final pageImageFileProvider = FutureProvider.autoDispose
    .family<File, PageImageKey>(
      (ref, key) => ref
          .watch(pageAssetStoreProvider)
          .image(MushafEdition.of(key.style), key.page, dark: key.dark),
    );

/// The Quran.com glyph database, opened once and kept.
final ayahInfoDatabaseProvider = FutureProvider<AyahInfoDatabase>((ref) async {
  final file = await ref.watch(pageAssetStoreProvider).ayahInfoDatabase();
  final database = AyahInfoDatabase.open(file);
  ref.onDispose(database.close);
  return database;
});

/// Where each word sits on a page image.
///
/// From the glyph database when the edition has one; otherwise measured on
/// the light image off the main isolate. A page whose ayah markers cannot be
/// told apart has no positions, so it shows without ayah selection.
final pageGeometryProvider = FutureProvider.autoDispose
    .family<PageGeometry, PageGeometryKey>((ref, key) async {
      final edition = MushafEdition.of(key.style);
      switch (edition.geometry) {
        case PageGeometrySource.glyphDatabase:
          final database = await ref.watch(ayahInfoDatabaseProvider.future);
          return glyphGeometry(
            database.page(key.page),
            width: MushafSources.ayahInfoWidth,
            height: MushafSources.ayahInfoHeight,
            lines: printedLinesOnPage(key.page),
          );
        case PageGeometrySource.measured:
          final metadata = await ref.watch(quranMetadataProvider.future);
          final file = await ref.watch(
            pageImageFileProvider((
              style: key.style,
              page: key.page,
              dark: false,
            )).future,
          );
          final image = await _decodeRgba(await file.readAsBytes(), width: 540);
          return compute(_measure, (
            ayahs: sakinaAyahsOnPage(metadata, key.page),
            lines: printedLinesOnPage(key.page),
            image: image,
          ));
      }
    });

PageGeometry _measure(
  ({List<AyahRef> ayahs, int lines, InkImage image}) input,
) => measurePageGeometry(input.ayahs, input.image, lines: input.lines);

Future<InkImage> _decodeRgba(Uint8List bytes, {required int width}) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: width);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = InkImage(
    width: image.width,
    height: image.height,
    rgba: data!.buffer.asUint8List(),
  );
  image.dispose();
  codec.dispose();
  return result;
}

/// A page image decoded for display at a pixel width.
typedef PageDisplayKey = ({MushafStyle style, int page, bool dark, int width});

/// The decoded page image to paint, sized for the screen.
final pageDisplayImageProvider = FutureProvider.autoDispose
    .family<ui.Image, PageDisplayKey>((ref, key) async {
      final file = await ref.watch(
        pageImageFileProvider((
          style: key.style,
          page: key.page,
          dark: key.dark,
        )).future,
      );
      final codec = await ui.instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: key.width,
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      ref.onDispose(image.dispose);
      return image;
    });
