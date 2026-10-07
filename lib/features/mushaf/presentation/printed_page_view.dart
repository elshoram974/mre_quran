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
import 'line_spread.dart';
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
          onTap: onTap,
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
    required this.onTap,
    required this.onAyahLongPress,
    required this.bookmarked,
    required this.selected,
  });

  final MushafEdition edition;
  final int page;
  final Size area;
  final int width;
  final VoidCallback onTap;
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
    // Pages are cropped and spread by their ink and rows, so they wait for the
    // positions. Without them (database unavailable) a page still shows, with
    // a safe crop and no ayah selection.
    final ready = geometry != null || measured.hasError;
    final still = MediaQuery.disableAnimationsOf(context);
    final l10n = context.l10n;

    final spread = geometry == null
        ? null
        : LineSpread.fit(
            cuts: geometry.lineCuts,
            crop: edition.crop,
            aspect: edition.width / edition.height,
            area: area,
          );
    final crop = edition.ink == PageInk.onPaper && geometry != null
        ? printedCropFor(
            edition,
            inkTop: geometry.inkTop,
            inkBottom: geometry.inkBottom,
            area: area,
          )
        : edition.crop;
    final Widget child = switch (image) {
      AsyncValue(:final value?) when ready => _placed(
        _PrintedImage(
          key: const ValueKey('image'),
          edition: edition,
          image: value,
          crop: spread == null ? crop : edition.crop,
          spread: spread,
          dark: dark,
          geometry: geometry,
          bookmarked: bookmarked,
          selected: selected,
          onTap: onTap,
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
    // A spread page fills the area.
    if (image.spread != null) {
      return SizedBox.fromSize(key: image.key, size: area, child: image);
    }
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

class _PrintedImage extends StatefulWidget {
  const _PrintedImage({
    super.key,
    required this.edition,
    required this.image,
    required this.crop,
    required this.spread,
    required this.dark,
    required this.geometry,
    required this.bookmarked,
    required this.selected,
    required this.onTap,
    required this.onAyahLongPress,
    required this.label,
  });

  final MushafEdition edition;
  final ui.Image image;
  final FractionRect crop;

  /// How the page's rows are laid apart, or null when the page is drawn whole.
  final LineSpread? spread;
  final bool dark;
  final PageGeometry? geometry;
  final Set<AyahRef> bookmarked;
  final AyahRef? selected;
  final VoidCallback onTap;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final String label;

  @override
  State<_PrintedImage> createState() => _PrintedImageState();
}

class _PrintedImageState extends State<_PrintedImage>
    with SingleTickerProviderStateMixin {
  /// How long the splash of a tapped ayah lasts.
  static const Duration _splash = Duration(milliseconds: 650);

  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _splash,
  );
  List<FractionRect> _flashRects = const [];

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  /// The ayah under [local], for a page area of [size].
  AyahRef? _ayahAt(Offset local, Size size) {
    final geometry = widget.geometry;
    if (geometry == null) return null;
    final crop = widget.crop;
    final spread = widget.spread;
    return geometry.ayahAt(
      crop.left + local.dx / size.width * (crop.right - crop.left),
      spread == null
          ? crop.top + local.dy / size.height * (crop.bottom - crop.top)
          : spread.toImage(local.dy),
    );
  }

  void _longPress(Offset local, Size size) {
    final callback = widget.onAyahLongPress;
    final ayah = _ayahAt(local, size);
    if (callback == null || ayah == null) return;
    HapticFeedback.selectionClick();
    callback(ayah);
  }

  /// A tap toggles the bars and splashes the ayah under the finger, which
  /// fades away at once: it is not a selection.
  void _tap(Offset local, Size size) {
    widget.onTap();
    final ayah = _ayahAt(local, size);
    if (ayah == null || MediaQuery.disableAnimationsOf(context)) return;
    setState(() => _flashRects = widget.geometry!.rectsOf(ayah));
    _flash.forward(from: 0);
  }

  /// How the image is laid onto the page colour.
  Paint _imagePaint(ColorScheme scheme) {
    final paint = Paint()..filterQuality = FilterQuality.medium;
    switch (widget.edition.ink) {
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
      case PageInk.onPaper when widget.dark:
        // The dark images' paper is stretched to black, then screened onto
        // the page colour, leaving no visible sheet.
        final paper = widget.edition.darkPaper ?? 0;
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
    final geometry = widget.geometry;
    final selected = widget.selected;
    final dark = widget.dark;
    final marks = <({List<FractionRect> rects, Color color})>[
      if (geometry != null)
        for (final ayah in widget.bookmarked)
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
        label: widget.label,
        child: GestureDetector(
          onTapUp: (details) =>
              _tap(details.localPosition, constraints.biggest),
          onLongPressStart: (details) =>
              _longPress(details.localPosition, constraints.biggest),
          child: CustomPaint(
            size: constraints.biggest,
            isComplex: true,
            painter: _PrintedPagePainter(
              image: widget.image,
              crop: widget.crop,
              spread: widget.spread,
              paper: scheme.surface,
              imagePaint: _imagePaint(scheme),
              marks: marks,
              splash: _flash,
              splashRects: _flashRects,
              splashColor: scheme.primary.withValues(alpha: dark ? 0.45 : 0.3),
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
    required this.spread,
    required this.paper,
    required this.imagePaint,
    required this.marks,
    required this.splash,
    required this.splashRects,
    required this.splashColor,
  }) : super(repaint: splash);

  final ui.Image image;
  final FractionRect crop;
  final LineSpread? spread;
  final Color paper;
  final Paint imagePaint;
  final List<({List<FractionRect> rects, Color color})> marks;

  /// Runs 0–1 while a tapped ayah's splash fades out.
  final Animation<double> splash;

  /// The tapped ayah's area.
  final List<FractionRect> splashRects;

  /// The splash at full strength.
  final Color splashColor;

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
    void highlight(List<FractionRect> rects, Color color) {
      final paint = Paint()..color = color;
      for (final rect in rects) {
        final top = spread == null
            ? (rect.top - crop.top) / cropHeight * size.height
            : spread!.toScreen(rect.top);
        final bottom = spread == null
            ? (rect.bottom - crop.top) / cropHeight * size.height
            : spread!.toScreen(rect.bottom, bottom: true);
        canvas.drawRRect(
          RRect.fromLTRBR(
            (rect.left - crop.left) / cropWidth * size.width - 3,
            top - 0.5,
            (rect.right - crop.left) / cropWidth * size.width + 3,
            bottom + 0.5,
            const Radius.circular(6),
          ),
          paint,
        );
      }
    }

    for (final mark in marks) {
      highlight(mark.rects, Color.alphaBlend(mark.color, paper));
    }
    // Quick rise, slow fade.
    final t = splash.value;
    if (splash.isAnimating && t < 1) {
      final strength = t < 0.15 ? t / 0.15 : 1 - (t - 0.15) / 0.85;
      highlight(
        splashRects,
        Color.alphaBlend(
          splashColor.withValues(alpha: splashColor.a * strength),
          paper,
        ),
      );
    }
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    if (spread case final spread?) {
      for (final row in spread.rows) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(
            crop.left * iw,
            row.srcTop * ih,
            crop.right * iw,
            row.srcBottom * ih,
          ),
          Rect.fromLTWH(0, row.destTop, size.width, row.destHeight),
          imagePaint,
        );
      }
    } else {
      canvas.drawImageRect(
        image,
        Rect.fromLTRB(
          crop.left * iw,
          crop.top * ih,
          crop.right * iw,
          crop.bottom * ih,
        ),
        bounds,
        imagePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PrintedPagePainter old) =>
      old.image != image ||
      old.crop != crop ||
      old.spread != spread ||
      old.paper != paper ||
      old.imagePaint.colorFilter != imagePaint.colorFilter ||
      old.imagePaint.blendMode != imagePaint.blendMode ||
      old.splashRects != splashRects ||
      old.splashColor != splashColor ||
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
