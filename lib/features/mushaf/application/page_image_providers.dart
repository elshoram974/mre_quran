import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/page_asset_store.dart';
import '../domain/page_geometry.dart';
import '../domain/page_layout.dart';

/// Which rendering of a page: its number and light or dark.
typedef PageImageKey = ({int page, bool dark});

/// Provides the page file store. Tests override it.
final pageAssetStoreProvider = Provider<PageAssetStore>(
  (ref) => PageAssetStore(root: getApplicationSupportDirectory),
);

/// The image file of a page, downloaded on first use.
final pageImageFileProvider = FutureProvider.autoDispose
    .family<File, PageImageKey>(
      (ref, key) =>
          ref.watch(pageAssetStoreProvider).image(key.page, dark: key.dark),
    );

/// The line layout of a page, downloaded on first use.
final pageLayoutProvider = FutureProvider.autoDispose.family<PageLayout, int>((
  ref,
  page,
) async {
  final source = await ref.watch(pageAssetStoreProvider).layout(page);
  return PageLayout.parse(source);
});

/// Where each word sits on a page image. Measured off the main isolate.
final pageGeometryProvider = FutureProvider.autoDispose
    .family<PageGeometry, PageImageKey>((ref, key) async {
      final layout = await ref.watch(pageLayoutProvider(key.page).future);
      final file = await ref.watch(pageImageFileProvider(key).future);
      final image = await _decode(await file.readAsBytes(), width: 540);
      return compute(_measure, (layout: layout, image: image));
    });

PageGeometry _measure(({PageLayout layout, InkImage image}) input) =>
    measurePageGeometry(input.layout, input.image);

Future<InkImage> _decode(Uint8List bytes, {required int width}) async {
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
typedef PageDisplayKey = ({int page, bool dark, int width});

/// The decoded page image to paint, sized for the screen.
final pageDisplayImageProvider = FutureProvider.autoDispose
    .family<ui.Image, PageDisplayKey>((ref, key) async {
      final file = await ref.watch(
        pageImageFileProvider((page: key.page, dark: key.dark)).future,
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
