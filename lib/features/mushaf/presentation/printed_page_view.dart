import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../application/page_image_providers.dart';
import '../domain/mushaf_edition.dart';
import '../domain/page_geometry.dart';
import 'mushaf_page_frame.dart';

/// Part of a page image of [edition] to show in [area], given where the
/// page's ink starts and ends (fractions of the image height).
///
/// The sides always come from the edition, so the script keeps one size from
/// page to page. Vertically the crop fills the area at that scale, centred on
/// the ink; a page whose ink is taller is shown whole and scaled down.
@visibleForTesting
FractionRect printedCropFor(
  MushafEdition edition, {
  required double inkTop,
  required double inkBottom,
  required Size area,
}) {
  final side = edition.crop;
  final width = side.right - side.left;
  final aspect = edition.width / edition.height;
  // Fraction of the image height that fits when the crop fills the width.
  final fits = area.height / (area.width / width / aspect);
  if (fits >= 1) {
    return (left: side.left, top: 0, right: side.right, bottom: 1);
  }
  const margin = 0.008;
  final top = math.max(0.0, inkTop - margin);
  final bottom = math.min(1.0, inkBottom + margin);
  if (bottom - top > fits) {
    return (left: side.left, top: top, right: side.right, bottom: bottom);
  }
  final start = ((top + bottom - fits) / 2).clamp(0.0, 1 - fits);
  return (left: side.left, top: start, right: side.right, bottom: start + fits);
}

/// One page of a printed Mushaf edition, as an image inside the page frame.
///
/// The script follows the light, sepia, and dark themes: transparent pages
/// are tinted to the text colour, paper pages are blended onto the page
/// colour. The selected ayah is highlighted under the ink, and a long press
/// selects the ayah under the finger.
class PrintedPageView extends StatelessWidget {
  /// Creates printed page [page] of [style].
  const PrintedPageView({
    super.key,
    required this.metadata,
    required this.style,
    required this.page,
    required this.onTap,
    this.onAyahLongPress,
    this.bookmarked = const {},
    this.selected,
  });

  /// Quran structure, for the frame labels.
  final QuranMetadata metadata;

  /// Which edition.
  final MushafStyle style;

  /// Page number, 1–604.
  final int page;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// Called with the ayah that was pressed and held.
  final ValueChanged<AyahRef>? onAyahLongPress;

  /// Ayahs the reader bookmarked, tinted lightly.
  final Set<AyahRef> bookmarked;

  /// The ayah to highlight.
  final AyahRef? selected;

  @override
  Widget build(BuildContext context) => MushafPageFrame(
    metadata: metadata,
    page: page,
    onTap: onTap,
    decorated: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final edition = MushafEdition.of(style);
        // Decode only as many pixels as the screen shows, in steps so a small
        // resize reuses the decoded image.
        final pixels =
            constraints.maxWidth /
            (edition.crop.right - edition.crop.left) *
            MediaQuery.devicePixelRatioOf(context);
        return _PrintedBody(
          edition: edition,
          page: page,
          area: constraints.biggest,
          width: ((pixels / 180).ceil() * 180).clamp(360, edition.width),
          onAyahLongPress: onAyahLongPress,
          bookmarked: bookmarked,
          selected: selected,
        );
      },
    ),
  );
}

class _PrintedBody extends ConsumerWidget {
  const _PrintedBody({
    required this.edition,
    required this.page,
    required this.area,
    required this.width,
    required this.onAyahLongPress,
    required this.bookmarked,
    required this.selected,
  });

  final MushafEdition edition;
  final int page;
  final Size area;
  final int width;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final Set<AyahRef> bookmarked;
  final AyahRef? selected;

  void _retry(WidgetRef ref, bool dark) {
    ref
      ..invalidate(
        pageImageFileProvider((style: edition.style, page: page, dark: dark)),
      )
      ..invalidate(
        pageImageFileProvider((style: edition.style, page: page, dark: false)),
      )
      ..invalidate(pageLayoutProvider(page))
      ..invalidate(ayahInfoDatabaseProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final image = ref.watch(
      pageDisplayImageProvider((
        style: edition.style,
        page: page,
        dark: dark,
        width: width,
      )),
    );
    final measured = ref.watch(
      pageGeometryProvider((style: edition.style, page: page)),
    );
    final geometry = measured.value;
    // Paper pages are cropped to their ink, so they wait for the positions.
    // Without them (layout unavailable) a page still shows, with a safe crop
    // and no ayah selection.
    final ready =
        edition.ink == PageInk.transparent ||
        geometry != null ||
        measured.hasError;
    final still = MediaQuery.disableAnimationsOf(context);
    final l10n = context.l10n;

    final Widget child = switch (image) {
      AsyncValue(:final value?) when ready => _placed(
        _PrintedImage(
          key: const ValueKey('image'),
          edition: edition,
          image: value,
          crop: edition.ink == PageInk.onPaper && geometry != null
              ? printedCropFor(
                  edition,
                  inkTop: geometry.inkTop,
                  inkBottom: geometry.inkBottom,
                  area: area,
                )
              : edition.crop,
          dark: dark,
          geometry: geometry,
          bookmarked: bookmarked,
          selected: selected,
          onAyahLongPress: onAyahLongPress,
          label: l10n.printedPageLabel(formatDigits(page, arabic: true)),
        ),
      ),
      AsyncValue(hasError: true) => EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: l10n.readerLoadError,
        message: l10n.printedPageError,
        actionLabel: l10n.retry,
        onAction: () => _retry(ref, dark),
      ),
      _ => const _PrintedSkeleton(key: ValueKey('loading')),
    };
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 180),
      child: child,
    );
  }

  /// Centres [image] at the size its crop takes in the area.
  Widget _placed(_PrintedImage image) {
    final crop = image.crop;
    final aspect =
        (crop.right - crop.left) *
        edition.width /
        ((crop.bottom - crop.top) * edition.height);
    final size = applyBoxFit(BoxFit.contain, Size(aspect, 1), area).destination;
    return Center(
      key: image.key,
      child: SizedBox.fromSize(size: size, child: image),
    );
  }
}

class _PrintedImage extends StatelessWidget {
  const _PrintedImage({
    super.key,
    required this.edition,
    required this.image,
    required this.crop,
    required this.dark,
    required this.geometry,
    required this.bookmarked,
    required this.selected,
    required this.onAyahLongPress,
    required this.label,
  });

  final MushafEdition edition;
  final ui.Image image;
  final FractionRect crop;
  final bool dark;
  final PageGeometry? geometry;
  final Set<AyahRef> bookmarked;
  final AyahRef? selected;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final String label;

  void _longPress(Offset local, Size size) {
    final geometry = this.geometry;
    final callback = onAyahLongPress;
    if (geometry == null || callback == null) return;
    final ayah = geometry.ayahAt(
      crop.left + local.dx / size.width * (crop.right - crop.left),
      crop.top + local.dy / size.height * (crop.bottom - crop.top),
    );
    if (ayah == null) return;
    HapticFeedback.selectionClick();
    callback(ayah);
  }

  /// How the image is laid onto the page colour.
  Paint _imagePaint(ColorScheme scheme) {
    final paint = Paint()..filterQuality = FilterQuality.medium;
    switch (edition.ink) {
      case PageInk.transparent:
        // Ink takes the text colour; its strength follows how dark it was,
        // so grey ornaments stay light.
        final ink = scheme.onSurface;
        paint.colorFilter = ColorFilter.matrix([
          0, 0, 0, 0, ink.r * 255, //
          0, 0, 0, 0, ink.g * 255, //
          0, 0, 0, 0, ink.b * 255, //
          -0.299, -0.587, -0.114, 1, 0, //
        ]);
      case PageInk.onPaper when dark:
        // The dark images' paper is stretched to black, then screened onto
        // the page colour, leaving no visible sheet.
        final paper = edition.darkPaper ?? 0;
        final r = (paper >> 16) & 0xFF;
        final g = (paper >> 8) & 0xFF;
        final b = paper & 0xFF;
        paint
          ..blendMode = BlendMode.screen
          ..colorFilter = ColorFilter.matrix([
            255 / (255 - r), 0, 0, 0, -r * 255 / (255 - r), //
            0, 255 / (255 - g), 0, 0, -g * 255 / (255 - g), //
            0, 0, 255 / (255 - b), 0, -b * 255 / (255 - b), //
            0, 0, 0, 1, 0, //
          ]);
      case PageInk.onPaper:
        // White paper multiplied onto the page colour.
        paint.blendMode = BlendMode.multiply;
    }
    return paint;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final geometry = this.geometry;
    final selected = this.selected;
    final marks = <({List<FractionRect> rects, Color color})>[
      if (geometry != null)
        for (final ayah in bookmarked)
          (
            rects: geometry.rectsOf(ayah),
            color: scheme.tertiary.withValues(alpha: dark ? 0.22 : 0.12),
          ),
      if (geometry != null && selected != null)
        (
          rects: geometry.rectsOf(selected),
          color: scheme.primary.withValues(alpha: dark ? 0.4 : 0.22),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        container: true,
        image: true,
        label: label,
        child: GestureDetector(
          onLongPressStart: (details) =>
              _longPress(details.localPosition, constraints.biggest),
          child: CustomPaint(
            size: constraints.biggest,
            isComplex: true,
            painter: _PrintedPagePainter(
              image: image,
              crop: crop,
              paper: scheme.surface,
              imagePaint: _imagePaint(scheme),
              marks: marks,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrintedPagePainter extends CustomPainter {
  _PrintedPagePainter({
    required this.image,
    required this.crop,
    required this.paper,
    required this.imagePaint,
    required this.marks,
  });

  final ui.Image image;
  final FractionRect crop;
  final Color paper;
  final Paint imagePaint;
  final List<({List<FractionRect> rects, Color color})> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final cropWidth = crop.right - crop.left;
    final cropHeight = crop.bottom - crop.top;
    final bounds = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(bounds)
      ..drawRect(bounds, Paint()..color = paper);
    // Highlights go under the ink so the script stays crisp on top of them.
    for (final mark in marks) {
      final paint = Paint()..color = Color.alphaBlend(mark.color, paper);
      for (final rect in mark.rects) {
        canvas.drawRRect(
          RRect.fromLTRBR(
            (rect.left - crop.left) / cropWidth * size.width - 3,
            (rect.top - crop.top) / cropHeight * size.height - 2,
            (rect.right - crop.left) / cropWidth * size.width + 3,
            (rect.bottom - crop.top) / cropHeight * size.height + 2,
            const Radius.circular(6),
          ),
          paint,
        );
      }
    }
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    canvas
      ..drawImageRect(
        image,
        Rect.fromLTRB(
          crop.left * iw,
          crop.top * ih,
          crop.right * iw,
          crop.bottom * ih,
        ),
        bounds,
        imagePaint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_PrintedPagePainter old) =>
      old.image != image ||
      old.crop != crop ||
      old.paper != paper ||
      old.imagePaint.colorFilter != imagePaint.colorFilter ||
      old.imagePaint.blendMode != imagePaint.blendMode ||
      !_sameMarks(old.marks, marks);

  static bool _sameMarks(
    List<({List<FractionRect> rects, Color color})> a,
    List<({List<FractionRect> rects, Color color})> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].color != b[i].color) return false;
      if (a[i].rects.length != b[i].rects.length) return false;
      for (var j = 0; j < a[i].rects.length; j++) {
        if (a[i].rects[j] != b[i].rects[j]) return false;
      }
    }
    return true;
  }
}

/// Fifteen line placeholders spread like the printed page.
class _PrintedSkeleton extends StatelessWidget {
  const _PrintedSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final pitch = constraints.maxHeight / 15;
        return Column(
          children: [
            for (var line = 0; line < 15; line++)
              SizedBox(
                height: pitch,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: pitch * 0.28),
                  child: const SkeletonBox(height: double.infinity),
                ),
              ),
          ],
        );
      },
    ),
  );
}
