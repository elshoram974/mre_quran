import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
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
    this.fillWidth = false,
    this.fallbackBuilder,
    this.fallbackAfter = const Duration(seconds: 30),
  });

  /// Builds the page as typeset text, shown in place of the image when the
  /// image cannot be had: offline, a failed download, or one that takes longer
  /// than [fallbackAfter]. The image replaces it as soon as it arrives.
  final WidgetBuilder? fallbackBuilder;

  /// How long the image may take before the text stands in for it.
  final Duration fallbackAfter;

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

  /// Whether this is the single-page reader: it uses the available width and
  /// lets a tall printed page scroll vertically instead of shrinking it.
  final bool fillWidth;

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
        return _SlowGate(
          key: ValueKey<(MushafStyle, int)>((style, page)),
          after: fallbackAfter,
          builder: (context, slow, restart) => _PrintedBody(
            metadata: metadata,
            edition: edition,
            page: page,
            area: constraints.biggest,
            width: ((pixels / 180).ceil() * 180).clamp(360, edition.width),
            onTap: onTap,
            onAyahLongPress: onAyahLongPress,
            bookmarked: bookmarked,
            selected: selected,
            fallbackBuilder: fallbackBuilder,
            fillWidth: fillWidth,
            slow: slow,
            onRetry: restart,
          ),
        );
      },
    ),
  );
}

/// Tells its builder when [after] has passed since it began (or since it was
/// restarted): how long the page's image has been awaited.
class _SlowGate extends StatefulWidget {
  const _SlowGate({super.key, required this.after, required this.builder});

  final Duration after;
  final Widget Function(BuildContext context, bool slow, VoidCallback restart)
  builder;

  @override
  State<_SlowGate> createState() => _SlowGateState();
}

class _SlowGateState extends State<_SlowGate> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer(widget.after, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  void _restart() {
    setState(() => _slow = false);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _slow, _restart);
}

class _PrintedBody extends ConsumerWidget {
  const _PrintedBody({
    required this.fallbackBuilder,
    required this.fillWidth,
    required this.slow,
    required this.onRetry,
    required this.metadata,
    required this.edition,
    required this.page,
    required this.area,
    required this.width,
    required this.onTap,
    required this.onAyahLongPress,
    required this.bookmarked,
    required this.selected,
  });

  final WidgetBuilder? fallbackBuilder;
  final bool fillWidth;
  final bool slow;
  final VoidCallback onRetry;
  final QuranMetadata metadata;
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
    onRetry();
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

    final spread = fillWidth || geometry == null
        ? null
        : LineSpread.fit(
            cuts: geometry.lineCuts,
            crop: edition.crop,
            aspect: edition.width / edition.height,
            area: area,
          );
    final crop = !fillWidth && edition.ink == PageInk.onPaper && geometry != null
        ? printedCropFor(
            edition,
            inkTop: geometry.inkTop,
            inkBottom: geometry.inkBottom,
            area: area,
          )
        : edition.crop;
    // The empty circles of each surah banner hold the surah's details.
    final circles = edition.bannerCircles;
    final banners = geometry == null || circles == null
        ? const <BannerDetails>[]
        : [
            for (final banner in geometry.banners)
              BannerDetails(
                top: banner.top,
                bottom: banner.bottom,
                startMain: formatDigits(
                  metadata.surah(banner.surah).ayahCount,
                  arabic: true,
                ),
                startCaption: l10n.surahAyahsCaption,
                endMain:
                    metadata.surah(banner.surah).revelation == Revelation.meccan
                    ? l10n.revelationMeccan
                    : l10n.revelationMedinan,
                endCaption: l10n.surahOrderLabel(
                  formatDigits(banner.surah, arabic: true),
                ),
              ),
          ];
    final Widget child = switch (image) {
      AsyncValue(:final value?) when ready => _placed(
        _PrintedImage(
          key: const ValueKey('image'),
          edition: edition,
          image: value,
          crop: spread == null ? crop : edition.crop,
          fillWidth: fillWidth,
          spread: spread,
          dark: dark,
          geometry: geometry,
          banners: banners,
          bookmarked: bookmarked,
          selected: selected,
          onTap: onTap,
          onAyahLongPress: onAyahLongPress,
          label: l10n.printedPageLabel(formatDigits(page, arabic: true)),
        ),
      ),
      // The image cannot be had, or is taking too long: show the page as
      // text, with a way to try the image again.
      _ when fallbackBuilder != null && (slow || image.hasError) =>
        _TextStandIn(
          key: const ValueKey('fallback'),
          notice: l10n.printedFallbackNotice,
          retryLabel: l10n.retry,
          onRetry: () => _retry(ref, dark),
          child: fallbackBuilder!(context),
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
    if (image.fillWidth) {
      final height = area.width / aspect;
      return SingleChildScrollView(
        child: SizedBox(
          key: image.key,
          width: area.width,
          height: height,
          child: image,
        ),
      );
    }
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
    required this.fillWidth,
    required this.spread,
    required this.dark,
    required this.geometry,
    required this.banners,
    required this.bookmarked,
    required this.selected,
    required this.onTap,
    required this.onAyahLongPress,
    required this.label,
  });

  final List<BannerDetails> banners;
  final MushafEdition edition;
  final ui.Image image;
  final FractionRect crop;

  final bool fillWidth;

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
    Haptics.select();
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
              banners: widget.banners,
              circles: widget.edition.bannerCircles,
              bannerInk: scheme.onSurface.withValues(alpha: 0.85),
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
    required this.banners,
    required this.circles,
    required this.bannerInk,
    required this.splash,
    required this.splashRects,
    required this.splashColor,
  }) : super(repaint: splash);

  /// Details to write in the empty circles of the surah banners.
  final List<BannerDetails> banners;

  /// Where the circles are, or null when the edition has none.
  final ({double start, double end, double diameter})? circles;

  /// Colour of the text in the circles.
  final Color bannerInk;

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
    _paintBanners(canvas, size);
    canvas.restore();
  }

  /// Writes each banner's details in its two circles, following the image
  /// wherever the page has been cropped or spread.
  void _paintBanners(Canvas canvas, Size size) {
    final circles = this.circles;
    if (circles == null) return;
    final cropWidth = crop.right - crop.left;
    final cropHeight = crop.bottom - crop.top;
    double screenX(double fraction) =>
        (fraction - crop.left) / cropWidth * size.width;
    final diameter = circles.diameter / cropWidth * size.width;
    for (final banner in banners) {
      final top = spread == null
          ? (banner.top - crop.top) / cropHeight * size.height
          : spread!.toScreen(banner.top);
      final bottom = spread == null
          ? (banner.bottom - crop.top) / cropHeight * size.height
          : spread!.toScreen(banner.bottom, bottom: true);
      final y = (top + bottom) / 2;
      _circleText(
        canvas,
        Offset(screenX(circles.start), y),
        diameter,
        banner.startMain,
        banner.startCaption,
      );
      _circleText(
        canvas,
        Offset(screenX(circles.end), y),
        diameter,
        banner.endMain,
        banner.endCaption,
      );
    }
  }

  /// [main] over a smaller [caption], scaled down to fit a circle.
  void _circleText(
    Canvas canvas,
    Offset centre,
    double diameter,
    String main,
    String? caption,
  ) {
    TextStyle style(double size, double alpha) => TextStyle(
      fontFamily: AppTokens.quranFontFamily,
      fontSize: size,
      height: 1.05,
      color: bannerInk.withValues(alpha: bannerInk.a * alpha),
    );
    final painter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: main,
        style: style(100, 1),
        children: [
          if (caption != null) ...[
            const TextSpan(text: '\n'),
            TextSpan(text: caption, style: style(58, 0.8)),
          ],
        ],
      ),
    )..layout();
    // Fit inside the circle's inscribed square, with a little air.
    final room = diameter * 0.84;
    final scale = math.min(room / painter.width, room / painter.height);
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(scale);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
    painter.dispose();
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
      old.bannerInk != bannerInk ||
      !listEquals(old.banners, banners) ||
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

/// A page of text standing in for its image, under a one-line notice with a
/// button to try the image again.
class _TextStandIn extends StatelessWidget {
  const _TextStandIn({
    super.key,
    required this.notice,
    required this.retryLabel,
    required this.onRetry,
    required this.child,
  });

  final String notice;
  final String retryLabel;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                notice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(retryLabel),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// What is written in the two empty circles of one surah banner.
@immutable
class BannerDetails {
  /// Creates the details of the banner spanning [top]–[bottom] (fractions of
  /// the image height).
  const BannerDetails({
    required this.top,
    required this.bottom,
    required this.startMain,
    required this.startCaption,
    required this.endMain,
    required this.endCaption,
  });

  /// Top of the banner.
  final double top;

  /// Bottom of the banner.
  final double bottom;

  /// Text in the circle at the reading start: the number of ayahs...
  final String startMain;

  /// ... with its caption under it.
  final String startCaption;

  /// Text in the circle at the reading end: where the surah was revealed...
  final String endMain;

  /// ... with its place in the Mushaf under it.
  final String endCaption;

  @override
  bool operator ==(Object other) =>
      other is BannerDetails &&
      other.top == top &&
      other.bottom == bottom &&
      other.startMain == startMain &&
      other.startCaption == startCaption &&
      other.endMain == endMain &&
      other.endCaption == endCaption;

  @override
  int get hashCode =>
      Object.hash(top, bottom, startMain, startCaption, endMain, endCaption);
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
