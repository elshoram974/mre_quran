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
import '../application/page_image_providers.dart';
import '../domain/page_geometry.dart';
import 'mushaf_page_frame.dart';

/// Width-to-height ratio of a full page image (1080 × 2160).
const double _imageAspect = 0.5;

/// Horizontal part of the page image shown: the same on every page, so the
/// script keeps one size from page to page.
const double _cropLeft = 0.035;
const double _cropRight = 0.97;

/// Part of the page image shown while its ink extent is unknown. Every
/// page's ink, the busy last page included, lies inside it.
const FractionRect printedPageCrop = (
  left: _cropLeft,
  top: 0.04,
  right: _cropRight,
  bottom: 0.97,
);

/// Part of a page image to show in [area], given where its ink starts and
/// ends (fractions of the image height).
///
/// The page images leave different blank margins above and below the text.
/// The crop fills the width when the ink fits at that scale, centred on the
/// ink; a taller page is shown whole and scaled down to fit.
@visibleForTesting
FractionRect printedCropFor({
  required double inkTop,
  required double inkBottom,
  required Size area,
}) {
  const width = _cropRight - _cropLeft;
  // Fraction of the image height that fits when the crop fills the width.
  final fits = area.height / (area.width / width / _imageAspect);
  if (fits >= 1) {
    return (left: _cropLeft, top: 0, right: _cropRight, bottom: 1);
  }
  const margin = 0.008;
  final top = math.max(0.0, inkTop - margin);
  final bottom = math.min(1.0, inkBottom + margin);
  if (bottom - top > fits) {
    return (left: _cropLeft, top: top, right: _cropRight, bottom: bottom);
  }
  final start = ((top + bottom - fits) / 2).clamp(0.0, 1 - fits);
  return (left: _cropLeft, top: start, right: _cropRight, bottom: start + fits);
}

/// One page of the printed Madinah Mushaf, as an image inside the page frame.
///
/// The image is tinted onto the page colour, so it follows the light, sepia,
/// and dark themes. The selected ayah is highlighted under the ink, and a
/// long press finds the ayah under the finger from the measured word
/// positions.
class PrintedPageView extends StatelessWidget {
  /// Creates printed page [page].
  const PrintedPageView({
    super.key,
    required this.metadata,
    required this.page,
    required this.onTap,
    this.onAyahLongPress,
    this.bookmarked = const {},
    this.selected,
  });

  /// Quran structure, for the frame labels.
  final QuranMetadata metadata;

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
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Decode only as many pixels as the screen shows, in steps so a small
        // resize reuses the decoded image.
        final pixels =
            constraints.maxWidth /
            (_cropRight - _cropLeft) *
            MediaQuery.devicePixelRatioOf(context);
        return _PrintedBody(
          page: page,
          area: constraints.biggest,
          width: ((pixels / 180).ceil() * 180).clamp(360, 1080),
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
    required this.page,
    required this.area,
    required this.width,
    required this.onAyahLongPress,
    required this.bookmarked,
    required this.selected,
  });

  final int page;
  final Size area;
  final int width;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final Set<AyahRef> bookmarked;
  final AyahRef? selected;

  void _retry(WidgetRef ref, bool dark) {
    ref
      ..invalidate(pageImageFileProvider((page: page, dark: dark)))
      ..invalidate(pageLayoutProvider(page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final image = ref.watch(
      pageDisplayImageProvider((page: page, dark: dark, width: width)),
    );
    // Word positions also give the ink extent that sets the crop, so the
    // page waits for them. Without them (layout unavailable) it still shows,
    // with a safe crop and no ayah selection.
    final measured = ref.watch(pageGeometryProvider((page: page, dark: false)));
    final geometry = measured.value;
    final still = MediaQuery.disableAnimationsOf(context);
    final l10n = context.l10n;

    final Widget child = switch (image) {
      AsyncValue(:final value?) when geometry != null || measured.hasError =>
        _placed(
          _PrintedImage(
            key: const ValueKey('image'),
            image: value,
            crop: geometry == null
                ? printedPageCrop
                : printedCropFor(
                    inkTop: geometry.inkTop,
                    inkBottom: geometry.inkBottom,
                    area: area,
                  ),
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
        (crop.right - crop.left) * _imageAspect / (crop.bottom - crop.top);
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
    required this.image,
    required this.crop,
    required this.dark,
    required this.geometry,
    required this.bookmarked,
    required this.selected,
    required this.onAyahLongPress,
    required this.label,
  });

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
              // White paper multiplied onto the page colour; the dark image's
              // black paper screened onto it.
              blend: dark ? BlendMode.screen : BlendMode.multiply,
              marks: marks,
            ),
          ),
        ),
      ),
    );
  }
}

/// Stretches the dark images' paper colour (13, 15, 18) down to black, so
/// screening the page onto the theme colour leaves no visible sheet.
const _darkPaperToBlack = ColorFilter.matrix([
  255 / 242, 0, 0, 0, -13 * 255 / 242, //
  0, 255 / 240, 0, 0, -15 * 255 / 240, //
  0, 0, 255 / 237, 0, -18 * 255 / 237, //
  0, 0, 0, 1, 0, //
]);

class _PrintedPagePainter extends CustomPainter {
  _PrintedPagePainter({
    required this.image,
    required this.crop,
    required this.paper,
    required this.blend,
    required this.marks,
  });

  final ui.Image image;
  final FractionRect crop;
  final Color paper;
  final BlendMode blend;
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
            (rect.left - crop.left) / cropWidth * size.width - 2,
            (rect.top - crop.top) / cropHeight * size.height,
            (rect.right - crop.left) / cropWidth * size.width + 2,
            (rect.bottom - crop.top) / cropHeight * size.height,
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
        Paint()
          ..blendMode = blend
          ..colorFilter = blend == BlendMode.screen ? _darkPaperToBlack : null
          ..filterQuality = FilterQuality.medium,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_PrintedPagePainter old) =>
      old.image != image ||
      old.crop != crop ||
      old.paper != paper ||
      old.blend != blend ||
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
