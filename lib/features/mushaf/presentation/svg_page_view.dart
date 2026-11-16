import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/haptics/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../quran_index/domain/quran_metadata.dart';
import '../../settings/application/digits_provider.dart';
import '../application/svg_page_providers.dart';
import '../domain/svg_page.dart';
import 'mushaf_page_frame.dart';

/// One page of the printed Mushaf, drawn from its vector artwork inside the
/// page frame.
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
    this.bookmarked = const {},
    this.selected,
    this.fillWidth = false,
    this.spread = false,
    this.digits,
    this.fallbackBuilder,
    this.fallbackAfter = const Duration(seconds: 30),
  });

  /// How many decoded pictures the SVG cache should keep: two per page, for
  /// the pages the prefetcher holds around the reader.
  static const int cachedPictures = 24;

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

  /// Ayahs the reader bookmarked, tinted lightly.
  final Set<AyahRef> bookmarked;

  /// The ayah to highlight.
  final AyahRef? selected;

  /// Whether this is the single-page reader: it uses the available width and
  /// lets a tall page scroll vertically instead of shrinking it.
  final bool fillWidth;

  /// Whether this page faces another, which keeps only its outer arrow.
  final bool spread;

  /// Formats the page number using the saved digit preference.
  final String Function(int)? digits;

  @override
  Widget build(BuildContext context) => MushafPageFrame(
    metadata: metadata,
    page: page,
    onTap: onTap,
    spread: spread,
    gutter: AppTokens.readerGutterPrinted,
    child: _SlowGate(
      key: ValueKey<int>(page),
      after: fallbackAfter,
      builder: (context, slow, restart) => _SvgBody(
        page: page,
        label: context.l10n.printedPageLabel(
          (digits ?? (value) => formatDigits(value, arabic: true))(page),
        ),
        onTap: onTap,
        onAyahLongPress: onAyahLongPress,
        bookmarked: bookmarked,
        selected: selected,
        fillWidth: fillWidth,
        fallbackBuilder: fallbackBuilder,
        slow: slow,
        onRetry: restart,
      ),
    ),
  );
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
    required this.page,
    required this.label,
    required this.onTap,
    required this.onAyahLongPress,
    required this.bookmarked,
    required this.selected,
    required this.fillWidth,
    required this.fallbackBuilder,
    required this.slow,
    required this.onRetry,
  });

  final int page;
  final String label;
  final VoidCallback onTap;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final Set<AyahRef> bookmarked;
  final AyahRef? selected;
  final bool fillWidth;
  final WidgetBuilder? fallbackBuilder;
  final bool slow;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final artwork = ref.watch(svgPageProvider(page));
    void retry() {
      ref.invalidate(svgPageProvider(page));
      onRetry();
    }

    final Widget child = switch (artwork) {
      AsyncValue(:final value?) => _SvgArtwork(
        key: const ValueKey('artwork'),
        page: value,
        label: label,
        onTap: onTap,
        onAyahLongPress: onAyahLongPress,
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
      AsyncValue(hasError: true) => EmptyState(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_outlined,
        title: l10n.readerLoadError,
        message: l10n.printedPageError,
        actionLabel: l10n.retry,
        onAction: retry,
      ),
      _ => const _PageSkeleton(key: ValueKey('loading')),
    };
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTokens.motionMedium,
      child: child,
    );
  }
}

/// The artwork of a page, fitted to the space, with highlights under the
/// ink and gestures mapped back to the page's ayah regions.
class _SvgArtwork extends StatelessWidget {
  const _SvgArtwork({
    super.key,
    required this.page,
    required this.label,
    required this.onTap,
    required this.onAyahLongPress,
    required this.bookmarked,
    required this.selected,
    required this.fillWidth,
  });

  final SvgPage page;
  final String label;
  final VoidCallback onTap;
  final ValueChanged<AyahRef>? onAyahLongPress;
  final Set<AyahRef> bookmarked;
  final AyahRef? selected;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final area = constraints.biggest;
      final content = page.layout.content;
      final aspect = pageBoxWidth(content) / pageBoxHeight(content);
      final size = fillWidth
          ? Size(area.width, area.width / aspect)
          : applyBoxFit(BoxFit.contain, Size(aspect, 1), area).destination;
      final sheet = SizedBox.fromSize(
        size: size,
        child: _sheet(context, size.width / pageBoxWidth(content)),
      );
      // The single-page reader fills the width; a page taller than the
      // screen scrolls.
      return fillWidth
          ? SingleChildScrollView(child: sheet)
          : Center(child: sheet);
    },
  );

  /// The page at [scale] screen pixels per page unit.
  Widget _sheet(BuildContext context, double scale) {
    final colors = QuranColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final layout = page.layout;
    final content = layout.content;
    AyahRef? ayahAt(Offset position) => layout.ayahAt(
      content.left + position.dx / scale,
      content.top + position.dy / scale,
    );
    // Each layer's view box is the visible part of the page, so it simply
    // fills the sheet.
    Widget layer(String svg, Color color) => Positioned.fill(
      child: SvgPicture.string(
        svg,
        fit: BoxFit.fill,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        excludeFromSemantics: true,
      ),
    );
    final longPress = onAyahLongPress;
    return Semantics(
      container: true,
      image: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: longPress == null
            ? null
            : (details) {
                final ayah = ayahAt(details.localPosition);
                if (ayah == null) return;
                Haptics.select();
                longPress(ayah);
              },
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RegionPainter(
                    scale: scale,
                    origin: (x: content.left, y: content.top),
                    washes: [
                      for (final ayah in bookmarked)
                        if (layout.regionOf(ayah) case final region?)
                          (
                            region: region,
                            color: scheme.tertiary.withValues(alpha: 0.16),
                          ),
                      if (selected case final ayah?)
                        if (layout.regionOf(ayah) case final region?)
                          (region: region, color: colors.highlight),
                    ],
                  ),
                ),
              ),
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
    required this.origin,
    required this.washes,
  });

  /// Screen pixels per page unit.
  final double scale;

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
            Offset((point.x - origin.x) * scale, (point.y - origin.y) * scale),
        ], true);
      }
      canvas.drawPath(path, Paint()..color = wash.color);
    }
  }

  @override
  bool shouldRepaint(_RegionPainter old) {
    if (old.scale != scale ||
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
  const _PageSkeleton({super.key});

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
