import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/haptics/haptics.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/page_scrub_scale.dart';

/// A card for moving through the Mushaf by dragging along a track.
///
/// The track first stands for the whole Mushaf, which gets the reader near
/// a page. Holding the thumb still switches it to a fine scale of a few
/// pages with a tick for each, which picks the exact page. The page is
/// reported once, when the finger lifts.
///
/// The track runs right to left in every language, like the Mushaf: the
/// first page is at the right end.
class PageScrubber extends StatefulWidget {
  /// Creates a scrubber showing [page] of [pageCount].
  const PageScrubber({
    super.key,
    required this.page,
    required this.pageCount,
    required this.titleOf,
    required this.subtitleOf,
    required this.digits,
    required this.fineLabel,
    required this.numberTooltip,
    required this.onChanged,
    required this.onEnterNumber,
    this.holdToRefine = const Duration(milliseconds: 500),
  });

  /// The page the reader is on.
  final int page;

  /// Pages in the Mushaf.
  final int pageCount;

  /// The headline for a page, such as "Page 213".
  final String Function(int page) titleOf;

  /// The line under the headline: the page's surah and juz.
  final String Function(int page) subtitleOf;

  /// Formats a page number for the tick labels.
  final String Function(int page) digits;

  /// Shown while the fine scale is on.
  final String fineLabel;

  /// Tooltip of the button that asks for a page number.
  final String numberTooltip;

  /// Called with the page picked, when the finger lifts.
  final ValueChanged<int> onChanged;

  /// Called when the reader asks to type a page number.
  final VoidCallback onEnterNumber;

  /// How long the thumb must rest on one page before the fine scale opens.
  final Duration holdToRefine;

  @override
  State<PageScrubber> createState() => _PageScrubberState();
}

class _PageScrubberState extends State<PageScrubber> {
  late PageScrubScale _scale = PageScrubScale.whole(widget.pageCount);
  Timer? _hold;

  /// The page under the thumb while dragging; null at rest.
  int? _preview;

  /// The finger's last place on the track, 0–1 from the first page's end.
  double _fraction = 0;

  /// Where the finger was when the hold timer last started.
  double _anchor = 0;

  /// The finger may drift this far and still count as resting. On the whole
  /// scale one page is narrower than a finger's tremor.
  static const double _restSlop = 8;

  int get _shown => _preview ?? widget.page;

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  /// Track fraction of a touch at [dx] on a track [width] wide. The first
  /// page is at the right end, so the fraction grows leftwards.
  double _fractionAt(double dx, double width) =>
      width <= 0 ? 0 : (1 - dx / width).clamp(0.0, 1.0);

  void _drag(double dx, double width) {
    _fraction = _fractionAt(dx, width);
    final page = _scale.pageAt(_fraction);
    final started = _preview == null;
    if (page != _preview) {
      if (_scale.fine) Haptics.tick();
      setState(() => _preview = page);
    }
    if (started || (dx - _anchor).abs() > _restSlop) _armHold(dx);
  }

  void _armHold(double dx) {
    _anchor = dx;
    _hold?.cancel();
    if (_scale.fine) return;
    _hold = Timer(widget.holdToRefine, _refine);
  }

  void _refine() {
    final page = _preview;
    if (!mounted || page == null) return;
    Haptics.step();
    setState(
      () => _scale = PageScrubScale.fineAt(
        page,
        fraction: _fraction,
        pageCount: widget.pageCount,
      ),
    );
  }

  void _release({required bool commit}) {
    _hold?.cancel();
    final page = _preview;
    setState(() {
      _preview = null;
      _scale = PageScrubScale.whole(widget.pageCount);
    });
    if (commit && page != null && page != widget.page) widget.onChanged(page);
  }

  int _neighbour(int by) => (widget.page + by).clamp(1, widget.pageCount);

  void _step(int by) {
    final page = _neighbour(by);
    if (page != widget.page) widget.onChanged(page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final page = _shown;
    return Material(
      color: scheme.surfaceContainerLowest,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTokens.spaceMedium + 4,
          AppTokens.spaceSmall,
          AppTokens.spaceSmall,
          AppTokens.spaceSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titleOf(page),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.subtitleOf(page),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_scale.fine)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppTokens.spaceSmall,
                    ),
                    child: Text(
                      widget.fineLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.tag_rounded),
                  tooltip: widget.numberTooltip,
                  onPressed: widget.onEnterNumber,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: AppTokens.spaceSmall + 4,
              ),
              child: Semantics(
                slider: true,
                value: widget.titleOf(page),
                increasedValue: widget.titleOf(_neighbour(1)),
                decreasedValue: widget.titleOf(_neighbour(-1)),
                onIncrease: () => _step(1),
                onDecrease: () => _step(-1),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (details) =>
                          _drag(details.localPosition.dx, width),
                      onHorizontalDragUpdate: (details) =>
                          _drag(details.localPosition.dx, width),
                      onHorizontalDragEnd: (_) => _release(commit: true),
                      onHorizontalDragCancel: () => _release(commit: false),
                      onTapUp: (details) {
                        final picked = _scale.pageAt(
                          _fractionAt(details.localPosition.dx, width),
                        );
                        if (picked != widget.page) widget.onChanged(picked);
                      },
                      child: CustomPaint(
                        size: Size(width, _trackExtent),
                        painter: _TrackPainter(
                          scale: _scale,
                          page: page,
                          digits: widget.digits,
                          active: scheme.primary,
                          rail: scheme.outlineVariant,
                          thumbRing: scheme.surfaceContainerLowest,
                          label:
                              theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ) ??
                              const TextStyle(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Height of the track: a full touch target for the thumb.
  static const double _trackExtent = AppTokens.minTarget;
}

/// Paints the track, its ticks on a fine scale, and the thumb.
///
/// Mushaf geometry: x is physical, with the first page at the right end in
/// every language.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.scale,
    required this.page,
    required this.digits,
    required this.active,
    required this.rail,
    required this.thumbRing,
    required this.label,
  });

  final PageScrubScale scale;
  final int page;
  final String Function(int page) digits;
  final Color active;
  final Color rail;
  final Color thumbRing;
  final TextStyle label;

  static const double _railWidth = 4;
  static const double _thumbRadius = 9;
  static const double _railY = 14;

  @override
  void paint(Canvas canvas, Size size) {
    double xOf(int page) => size.width * (1 - scale.fractionOf(page));
    final thumb = Offset(xOf(page), _railY);
    final line = Paint()
      ..strokeWidth = _railWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(0, _railY),
      Offset(size.width, _railY),
      line..color = rail,
    );
    // The part already read: from the first page's end to the thumb.
    canvas.drawLine(Offset(size.width, _railY), thumb, line..color = active);

    if (scale.fine) {
      final tick = Paint()..strokeWidth = 1.5;
      for (var p = scale.first; p <= scale.last; p++) {
        final major = scale.isMajor(p);
        final x = xOf(p);
        canvas.drawLine(
          Offset(x, _railY + 8),
          Offset(x, _railY + (major ? 16 : 12)),
          tick..color = p == page ? active : rail,
        );
        if (!major) continue;
        final text = TextPainter(
          text: TextSpan(text: digits(p), style: label),
          textDirection: TextDirection.ltr,
        )..layout();
        final dx = (x - text.width / 2).clamp(0.0, size.width - text.width);
        text.paint(canvas, Offset(dx, _railY + 18));
        text.dispose();
      }
    }

    canvas.drawCircle(thumb, _thumbRadius + 2, Paint()..color = thumbRing);
    canvas.drawCircle(thumb, _thumbRadius, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.scale != scale ||
      old.page != page ||
      old.active != active ||
      old.rail != rail ||
      old.thumbRing != thumbRing ||
      old.label != label;
}
