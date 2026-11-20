import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart'
    show RenderingStrategy;

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pinch_zoom.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../quran_text/domain/ayah_range.dart';
import '../../settings/application/digits_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../../startup/application/startup_providers.dart';
import '../../startup/presentation/reader_painted_mark.dart';
import '../application/svg_page_providers.dart';
import '../domain/svg_page.dart';
import 'mushaf_page_frame.dart';
import 'surah_banner.dart';

/// One page of the printed Mushaf, drawn from its vector artwork from edge
/// to edge, with nothing over it: where the reader is shows in the bars a
/// tap brings up.
///
/// The script takes the theme's ink colour and the ayah-number ornaments its
/// accent, so the page follows every paper and accent. The selected ayah is
/// highlighted under the ink, and a long press selects the ayah under the
/// finger, from the page's own ayah regions.
class SvgPageView extends StatelessWidget {
  /// Creates printed page [page].
  const SvgPageView({
    super.key,
    required this.metadata,
    required this.page,
    required this.onTap,
    this.onAyahLongPress,
    this.onAyahTap,
    this.bookmarked = const {},
    this.selected,
    this.fillWidth = false,
    this.spread = false,
    this.digits,
    this.fallbackBuilder,
    this.onPinchOut,
    this.fallbackAfter = const Duration(seconds: 30),
  });

  /// Called when two fingers spread apart on the page. A printed page is
  /// artwork and does not enlarge; the owner suggests reading it bigger
  /// another way. Null leaves the gesture alone.
  final VoidCallback? onPinchOut;

  /// Builds the page as typeset text, shown in place of the artwork when it
  /// cannot be had: offline, a failed download, or one that takes longer
  /// than [fallbackAfter]. The artwork replaces it as soon as it arrives.
  final WidgetBuilder? fallbackBuilder;

  /// How long the artwork may take before the text stands in for it.
  final Duration fallbackAfter;

  /// Quran structure, for the frame labels.
  final QuranMetadata metadata;

  /// Page number, 1–604.
  final int page;

  /// Called when the page is tapped.
  final VoidCallback onTap;

  /// Called with the ayah that was pressed and held.
  final ValueChanged<AyahRef>? onAyahLongPress;

  /// Called with the ayah that was tapped, in place of [onTap], when given.
  /// A tap outside every ayah still calls [onTap].
  final ValueChanged<AyahRef>? onAyahTap;

  /// Ayahs the reader bookmarked, tinted lightly.
  final Set<AyahRef> bookmarked;

  /// The ayahs to highlight.
  final AyahRange? selected;

  /// Whether this is the single-page reader: it uses the available width and
  /// lets a tall page scroll vertically instead of shrinking it.
  final bool fillWidth;

  /// Whether this page faces another, which keeps only its outer arrow.
  final bool spread;

  /// Formats the page number using the saved digit preference.
  final String Function(int)? digits;

  @override
  Widget build(BuildContext context) {
    final frame = MushafPageFrame(
      metadata: metadata,
      page: page,
      onTap: onTap,
      spread: spread,
      gutter: AppTokens.readerGutterPrinted,
      labels: false,
      child: _SlowGate(
        key: ValueKey<int>(page),
        after: fallbackAfter,
        // The room decides how far the lines are spread, and so which
        // picture of the page to ask for.
        builder: (context, slow, restart) => LayoutBuilder(
          builder: (context, constraints) => _SvgBody(
            metadata: metadata,
            number: digits ?? (value) => formatDigits(value, arabic: true),
            request: (
              page: page,
              stretch: _stretchFor(constraints.biggest, fillWidth: fillWidth),
            ),
            label: context.l10n.printedPageLabel(
              (digits ?? (value) => formatDigits(value, arabic: true))(page),
            ),
            onTap: onTap,
            onAyahLongPress: onAyahLongPress,
            onAyahTap: onAyahTap,
            bookmarked: bookmarked,
            selected: selected,
            fillWidth: fillWidth,
            fallbackBuilder: fallbackBuilder,
            slow: slow,
            onRetry: restart,
          ),
        ),
      ),
    );
    final onPinchOut = this.onPinchOut;
    if (onPinchOut == null) return frame;
    return PinchOut(onPinchOut: onPinchOut, child: frame);
  }

  /// What a page view of [page] in a slot of [slot] asks for: the same
  /// request as the view itself makes, so a page made ready ahead of time is
  /// the one the view shows.
  static SvgPageRequest requestIn(
    Size slot, {
    required int page,
    required bool fillWidth,
  }) => (
    page: page,
    stretch: _stretchFor(
      // The frame's margins (see MushafPageFrame, without labels).
      Size(
        slot.width - 2 * AppTokens.readerGutterPrinted,
        slot.height - 2 * AppTokens.readerEdgePrinted,
      ),
      fillWidth: fillWidth,
    ),
  );

  /// How far to spread a full page's lines in [area], in thousandths of its
  /// printed height. The single-page reader fills the width; on a screen
  /// taller than the page the lines move apart to fill the height too, up
  /// to [AppTokens.readerMaxLineSpread].
  static int _stretchFor(Size area, {required bool fillWidth}) {
    if (!fillWidth || area.isEmpty || !area.isFinite) return _printed;
    final natural = area.width / SvgPageLayout.fullPageAspect;
    final stretch = math.min(
      area.height / natural,
      AppTokens.readerMaxLineSpread,
    );
    return stretch <= 1 ? _printed : (stretch * _printed).round();
  }

  /// A page at its printed height, in thousandths.
  static const int _printed = 1000;
}

/// Tells its builder when [after] has passed since it began (or since it was
/// restarted): how long the page's artwork has been awaited.
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

/// The page in one of its four states: artwork, text standing in, error,
/// or loading.
class _SvgBody extends ConsumerWidget {
  const _SvgBody({
    required this.metadata,
    required this.number,
    required this.request,
    required this.label,
    required this.onTap,
    required this.onAyahLongPress,
    required this.onAyahTap,
    required this.bookmarked,
    required this.selected,
    required this.fillWidth,
    required this.fallbackBuilder,
    required this.slow,
    required this.onRetry,
  });

  final QuranMetadata metadata;
  final String Function(int) number;
  final SvgPageRequest request;
  final String label;
  final VoidCallback onTap;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final ValueChanged<AyahRef>? onAyahTap;
  final Set<AyahRef> bookmarked;
  final AyahRange? selected;
  final bool fillWidth;
  final WidgetBuilder? fallbackBuilder;
  final bool slow;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final artwork = ref.watch(svgPageProvider(request));
    final frame = ref.watch(
      settingsProvider.select(
        (settings) => settings.value?.surahFrame ?? SurahFrameStyle.cartouche,
      ),
    );
    void retry() {
      ref.invalidate(svgPageProvider(request));
      onRetry();
    }

    final Widget child = switch (artwork) {
      AsyncValue(:final value?) => _SvgArtwork(
        key: const ValueKey('artwork'),
        metadata: metadata,
        number: number,
        page: value,
        frame: frame,
        label: label,
        onTap: onTap,
        onAyahLongPress: onAyahLongPress,
        onAyahTap: onAyahTap,
        bookmarked: bookmarked,
        selected: selected,
        fillWidth: fillWidth,
      ),
      // The artwork cannot be had, or is taking too long: show the page as
      // text, with a way to try again.
      _ when fallbackBuilder != null && (slow || artwork.hasError) =>
        _TextStandIn(
          key: const ValueKey('fallback'),
          notice: l10n.printedFallbackNotice,
          retryLabel: l10n.retry,
          onRetry: retry,
          child: fallbackBuilder!(context),
        ),
      // No text can stand in (another reading): say why, and how to read
      // it without a connection next time.
      AsyncValue(:final error?) => Column(
        key: const ValueKey('error'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: l10n.readerLoadError,
            message: error is SocketException || error is HttpException
                ? l10n.printedPageOffline
                : l10n.printedPageError,
            actionLabel: l10n.retry,
            onAction: retry,
          ),
          TextButton.icon(
            onPressed: () => context.go(AppRoute.settings.path),
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(l10n.printedPageDownload),
          ),
        ],
      ),
      // A page on the device is ready in a moment; the placeholder only
      // comes if it is not, so a quick turn never flashes one.
      _ => const _Late(
        key: ValueKey('loading'),
        after: _placeholderAfter,
        child: _PageSkeleton(),
      ),
    };
    return AnimatedSwitcher(
      // The first page at start-up appears at once, under the splash, so the
      // splash can go the moment it is drawn; later pages fade in.
      duration:
          MediaQuery.disableAnimationsOf(context) ||
              !ref.watch(readerPaintedProvider)
          ? Duration.zero
          : AppTokens.motionMedium,
      // Anything but the placeholder lets the start-up splash give way.
      child: child.key == const ValueKey('loading')
          ? child
          : ReaderPaintedMark(key: child.key, child: child),
    );
  }
}

/// How long a page may take before its placeholder shows.
const Duration _placeholderAfter = Duration(milliseconds: 250);

/// Shows [child] only once [after] has passed; plain paper until then.
class _Late extends StatefulWidget {
  const _Late({super.key, required this.after, required this.child});

  final Duration after;
  final Widget child;

  @override
  State<_Late> createState() => _LateState();
}

class _LateState extends State<_Late> {
  late final Timer _timer;
  bool _due = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.after, () {
      if (mounted) setState(() => _due = true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _due ? widget.child : const SizedBox.expand();
}

/// One compiled layer of a page, handed to the renderer as it is.
class _CompiledLayer extends BytesLoader {
  const _CompiledLayer(this.bytes);

  final Uint8List bytes;

  @override
  Future<ByteData> loadBytes(BuildContext? context) =>
      SynchronousFuture(ByteData.sublistView(bytes));

  // A layer is its own bytes: the same page gives the same picture.
  @override
  bool operator ==(Object other) =>
      other is _CompiledLayer && identical(other.bytes, bytes);

  @override
  int get hashCode => identityHashCode(bytes);
}

/// The artwork of a page, fitted to the space, with highlights under the
/// ink and gestures mapped back to the page's ayah regions.
class _SvgArtwork extends StatelessWidget {
  const _SvgArtwork({
    super.key,
    required this.metadata,
    required this.number,
    required this.page,
    required this.frame,
    required this.label,
    required this.onTap,
    required this.onAyahLongPress,
    required this.onAyahTap,
    required this.bookmarked,
    required this.selected,
    required this.fillWidth,
  });

  final QuranMetadata metadata;
  final String Function(int) number;
  final SvgPagePicture page;
  final SurahFrameStyle frame;
  final String label;
  final VoidCallback onTap;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final ValueChanged<AyahRef>? onAyahTap;
  final Set<AyahRef> bookmarked;
  final AyahRange? selected;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final area = constraints.biggest;
      final content = page.layout.content;
      final aspect = pageBoxWidth(content) / pageBoxHeight(content);
      if (!fillWidth) {
        final size = applyBoxFit(
          BoxFit.contain,
          Size(aspect, 1),
          area,
        ).destination;
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: _sheet(context, size.width / pageBoxWidth(content), 1),
          ),
        );
      }
      // The single-page reader fills the width. The picture was made for
      // this room, with its lines spread to fill the height; a page taller
      // than the screen scrolls.
      final natural = area.width / aspect;
      final stretch = page.stretch;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: area.height),
          child: Center(
            child: SizedBox(
              width: area.width,
              height: natural * stretch,
              child: _sheet(
                context,
                area.width / pageBoxWidth(content),
                stretch,
              ),
            ),
          ),
        ),
      );
    },
  );

  /// The line of the basmala that opens the surah of [region], when it is
  /// the surah's first ayah: a surah's basmala belongs to no ayah region,
  /// yet it is chosen, highlighted and tapped with its first ayah. Al-Fatiha
  /// (whose basmala is its first ayah) and At-Tawbah (which has none) have
  /// none, nor a reading that counts the basmala into the first ayah's
  /// region already (its name then lies inside that region).
  AyahRegion? _basmalaOf(AyahRegion region) {
    final ref = region.ref;
    if (ref.ayah != 1 || ref.surah == 1 || ref.surah == 9) return null;
    final layout = page.layout;
    final top = region.bounds.top;
    for (final title in page.titles) {
      if (title.surah == ref.surah && title.box.top >= top) return null;
    }
    final width = pageBoxWidth(layout.viewBox);
    final pitch = pageBoxHeight(layout.viewBox) / SvgPageLayout.printedLines;
    final middle = layout.viewBox.left + width / 2;
    final half = width * _basmalaHalfWidth;
    return AyahRegion(
      ref: ref,
      rings: [
        [
          (x: middle - half, y: top - pitch),
          (x: middle + half, y: top - pitch),
          (x: middle + half, y: top),
          (x: middle - half, y: top),
        ],
      ],
    );
  }

  /// Half the width a basmala's line takes, as a share of the page's width.
  static const double _basmalaHalfWidth = 0.37;

  /// The frame of [title], around the name the page prints: as tall as the
  /// name with a margin, across the page, and moved with the name's line
  /// as far as spreading moves it.
  Widget _titleFrame(
    BuildContext context,
    SvgSurahTitle title, {
    required double scale,
    required double stretch,
  }) {
    final colors = QuranColors.of(context);
    final content = page.layout.content;
    final width = pageBoxWidth(content);
    final pitch =
        pageBoxHeight(page.layout.viewBox) / SvgPageLayout.printedLines;
    final box = title.box;
    final ink = box.bottom - box.top;
    // Spreading opens a gap of (stretch - 1) lines above and below the
    // name's line; the frame takes most of it, so it stands as a band of
    // its own rather than a thin rule around the letters.
    final height =
        (ink + pitch * _titleMargin * 2).clamp(
          pitch * _titleLeast,
          pitch * _titleMost,
        ) +
        pitch * (stretch - 1) * _titleGrowth;
    // Spreading moves each line as a whole, by as much as stretching the
    // page would move its middle.
    final moved = (title.line - content.top) * (stretch - 1);
    final middle = (box.top + box.bottom) / 2 - content.top + moved;
    // The same margin on both sides, so the frame sits alike whichever way
    // the app reads.
    final side = width * _titleSide;
    return PositionedDirectional(
      start: side * scale,
      end: side * scale,
      top: (middle - height / 2) * scale,
      height: height * scale,
      child: SurahBanner(
        surah: metadata.surah(title.surah),
        number: number,
        style: frame,
        showTitle: false,
        // The plaque is centred; the name may sit a little off the page's
        // middle, so the plaque reaches to its farther side on both.
        nameWidth:
            2 *
            math.max(
              (content.left + width / 2) - box.left,
              box.right - (content.left + width / 2),
            ) *
            scale,
        paper: colors.paper,
        band: colors.ayahNumber.withValues(alpha: 0.12),
        stroke: colors.ayahNumber.withValues(alpha: 0.85),
      ),
    );
  }

  /// A surah frame's margin above and below the name, and its least and
  /// most height before spreading, in printed lines; and its margin at each
  /// side, as a share of the page's width.
  static const double _titleMargin = 0.2;
  static const double _titleLeast = 1;
  static const double _titleMost = 1.18;

  /// How much of the gap spreading opens around the name's line the frame
  /// takes.
  static const double _titleGrowth = 0.8;
  static const double _titleSide = 0.015;

  /// The page at [scale] screen pixels per page unit, its lines spread for
  /// a page [stretch] times as tall.
  Widget _sheet(BuildContext context, double scale, double stretch) {
    final colors = QuranColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final layout = page.layout;
    final content = layout.content;
    AyahRef? ayahAt(Offset position) {
      final x = content.left + position.dx / scale;
      // Spreading moves a line as far as stretching the page would.
      final y = content.top + position.dy / scale / stretch;
      if (layout.ayahAt(x, y) case final ayah?) return ayah;
      // A basmala belongs to the ayah it opens.
      for (final region in layout.regions) {
        if (_basmalaOf(region)?.contains(x, y) ?? false) return region.ref;
      }
      return null;
    }

    // Each layer's view box is the visible part of the page, so it simply
    // fills the sheet.
    Widget layer(Uint8List compiled, Color color) => Positioned.fill(
      child: SvgPicture(
        _CompiledLayer(compiled),
        fit: BoxFit.fill,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        // A page is some 1,400 outlines. Drawn as a picture, they are
        // tessellated again on every frame of a turn, inside an offscreen
        // layer for the colour. Drawn once into an image at the screen's
        // own resolution, a frame only blits it, tinted as it goes.
        renderingStrategy: RenderingStrategy.raster,
        excludeFromSemantics: true,
      ),
    );
    final longPress = onAyahLongPress;
    final ayahTap = onAyahTap;
    return Semantics(
      container: true,
      image: true,
      label: label,
      child: GestureDetector(
        onTap: ayahTap == null ? onTap : null,
        onTapUp: ayahTap == null
            ? null
            : (details) => switch (ayahAt(details.localPosition)) {
                final ayah? => ayahTap(ayah),
                null => onTap(),
              },
        onLongPressStart: longPress == null
            ? null
            : (details) {
                final ayah = ayahAt(details.localPosition);
                if (ayah == null) return;
                longPress(ayah);
              },
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RegionPainter(
                    scale: scale,
                    stretch: stretch,
                    origin: (x: content.left, y: content.top),
                    washes: [
                      for (final ayah in bookmarked)
                        if (layout.regionOf(ayah) case final region?)
                          (
                            region: region,
                            color: scheme.tertiary.withValues(alpha: 0.16),
                          ),
                      if (selected case final range?)
                        for (final region in layout.regions)
                          if (range.contains(region.ref)) ...[
                            (region: region, color: colors.highlight),
                            if (_basmalaOf(region) case final basmala?)
                              (region: basmala, color: colors.highlight),
                          ],
                    ],
                  ),
                ),
              ),
              // A frame under each surah's name, as printed Mushafs set
              // it. The name itself is the page's own calligraphy, drawn
              // over the frame.
              for (final title in page.titles)
                _titleFrame(context, title, scale: scale, stretch: stretch),
              layer(page.ink, colors.ink),
              layer(page.marks, colors.ayahNumber),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a colour wash over ayah regions, under the ink.
class _RegionPainter extends CustomPainter {
  const _RegionPainter({
    required this.scale,
    required this.stretch,
    required this.origin,
    required this.washes,
  });

  /// Screen pixels per page unit.
  final double scale;

  /// How many times taller than printed the page is drawn.
  final double stretch;

  /// The page point at the top-left corner of the canvas.
  final PagePoint origin;

  /// Regions to wash, each in its colour, painted in order.
  final List<({AyahRegion region, Color color})> washes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final wash in washes) {
      final path = Path();
      for (final ring in wash.region.rings) {
        path.addPolygon([
          for (final point in ring)
            Offset(
              (point.x - origin.x) * scale,
              (point.y - origin.y) * scale * stretch,
            ),
        ], true);
      }
      canvas.drawPath(path, Paint()..color = wash.color);
    }
  }

  @override
  bool shouldRepaint(_RegionPainter old) {
    if (old.scale != scale ||
        old.stretch != stretch ||
        old.origin != origin ||
        old.washes.length != washes.length) {
      return true;
    }
    for (var i = 0; i < washes.length; i++) {
      if (old.washes[i].region != washes[i].region ||
          old.washes[i].color != washes[i].color) {
        return true;
      }
    }
    return false;
  }
}

/// A page of text standing in for its artwork, under a one-line notice with
/// a button to try the artwork again.
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
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 16, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                notice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppTokens.spaceSmall,
                ),
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

/// Fifteen line placeholders spread like the printed page.
class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  static const int _lines = 15;

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final pitch = constraints.maxHeight / _lines;
        return Column(
          children: [
            for (var line = 0; line < _lines; line++)
              SizedBox(
                height: pitch,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    vertical: pitch * 0.28,
                  ),
                  child: const SkeletonBox(height: double.infinity),
                ),
              ),
          ],
        );
      },
    ),
  );
}
