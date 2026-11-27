import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../domain/page_scrub_scale.dart';

/// A card for moving through the Mushaf by dragging along a ruled track.
///
/// The track first stands for the whole Mushaf, which gets the reader near
/// a page. Holding the thumb still zooms it to a fine scale of a few pages
/// with a tick for each, which picks the exact page; holding the thumb at
/// either end of the fine scale rolls it onward. The page is reported once,
/// when the finger lifts; lifting it above the track reports nothing, so a
/// slip of the finger never loses the reader's place.
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
    required this.cancelHint,
    required this.cancelNow,
    this.onClose,
    this.closeTooltip,
    this.holdToRefine = const Duration(milliseconds: 500),
  });

  /// The page the reader is on.
  final int page;

  /// Pages in the Mushaf.
  final int pageCount;

  /// The headline for a page, such as "Page 213".
  final String Function(int page) titleOf;

  /// The line under the headline: the page's surah, juz and hizb.
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

  /// Shown while dragging: how to back out without changing page.
  final String cancelHint;

  /// Shown once the finger is where lifting it changes nothing.
  final String cancelNow;

  /// Puts the scrubber away. Without it there is no close button.
  final VoidCallback? onClose;

  /// Tooltip of the close button.
  final String? closeTooltip;

  /// How long the thumb must rest before the fine scale opens.
  final Duration holdToRefine;

  @override
  State<PageScrubber> createState() => _PageScrubberState();
}

class _PageScrubberState extends State<PageScrubber>
    with SingleTickerProviderStateMixin {
  late PageScrubScale _scale = PageScrubScale.whole(widget.pageCount);

  /// Moves the track from the scale it showed to [_scale].
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    value: 1,
  );
  Curve _zoomCurve = Curves.easeOutCubic;
  late double _fromFirst = _scale.first.toDouble();
  late double _fromLast = _scale.last.toDouble();

  Timer? _hold;
  Timer? _roll;

  /// The page under the thumb while dragging; null at rest.
  int? _preview;

  /// Whether the finger has left the track upwards: lifting it now keeps
  /// the reader's page.
  bool _cancelling = false;

  /// The finger backs out by rising this far above the track.
  static const double _cancelRise = 28;

  /// The finger's last place on the track, 0–1 from the first page's end.
  double _fraction = 0;

  /// Where the finger was when the hold timer last started.
  double _anchor = 0;

  /// The finger may drift this far and still count as resting. On the whole
  /// scale one page is narrower than a finger's tremor.
  static const double _restSlop = 8;

  /// Holding the thumb within this share of the track from an end of the
  /// fine scale rolls the scale onward.
  static const double _rollZone = 0.06;

  /// How often a rolling scale moves on by a page.
  static const Duration _rollEvery = Duration(milliseconds: 110);

  /// Room kept at each end of the track, so the thumb is whole at the ends.
  static const double _inset = 14;

  /// Height of the track: the rail, the ticks and their labels.
  static const double _trackExtent = 52;

  int get _shown => _cancelling ? widget.page : _preview ?? widget.page;

  /// The first and last page the track shows at this instant.
  ({double first, double last}) get _visible {
    final t = _zoomCurve.transform(_zoom.value);
    return (
      first: lerpDouble(_fromFirst, _scale.first, t)!,
      last: lerpDouble(_fromLast, _scale.last, t)!,
    );
  }

  @override
  void dispose() {
    _hold?.cancel();
    _roll?.cancel();
    _zoom.dispose();
    super.dispose();
  }

  void _show(
    PageScrubScale scale, {
    Duration duration = AppTokens.motionMedium,
    Curve curve = Curves.easeOutCubic,
  }) {
    if (scale == _scale) return;
    final now = _visible;
    _fromFirst = now.first;
    _fromLast = now.last;
    _zoomCurve = curve;
    _scale = scale;
    if (MediaQuery.disableAnimationsOf(context)) {
      _zoom.value = 1;
    } else {
      _zoom
        ..duration = duration
        ..forward(from: 0);
    }
  }

  /// Track fraction of a touch at [dx] on a track [width] wide. The first
  /// page is at the right end, so the fraction grows leftwards.
  double _fractionAt(double dx, double width) {
    final usable = width - 2 * _inset;
    return usable <= 0 ? 0 : (1 - (dx - _inset) / usable).clamp(0.0, 1.0);
  }

  void _drag(Offset at, double width) {
    final dx = at.dx;
    final started = _preview == null;
    final cancelling = at.dy < -_cancelRise;
    setState(() {
      _cancelling = cancelling;
      _fraction = _fractionAt(dx, width);
      _point();
    });
    if (cancelling) {
      _hold?.cancel();
      _roll?.cancel();
      _roll = null;
      return;
    }
    if (started || (dx - _anchor).abs() > _restSlop) _armHold(dx);
    _armRoll();
  }

  /// Puts the preview on the page under the finger.
  void _point() {
    final page = _scale.pageAt(_fraction);
    if (page == _preview) return;
    _preview = page;
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
    setState(
      () => _show(
        PageScrubScale.fineAt(
          page,
          fraction: _fraction,
          pageCount: widget.pageCount,
        ),
      ),
    );
  }

  /// Starts or stops rolling the fine scale, by where the finger rests.
  void _armRoll() {
    final by = !_scale.fine
        ? 0
        : _fraction >= 1 - _rollZone
        ? 1
        : _fraction <= _rollZone
        ? -1
        : 0;
    if (by == 0) {
      _roll?.cancel();
      _roll = null;
      return;
    }
    _roll ??= Timer.periodic(_rollEvery, (_) => _rollBy(by));
  }

  void _rollBy(int by) {
    final moved = _scale.shifted(by, pageCount: widget.pageCount);
    if (!mounted || moved == _scale) return;
    setState(() {
      // A steady glide: each step lasts until the next one starts.
      _show(moved, duration: _rollEvery, curve: Curves.linear);
      _point();
    });
  }

  void _release({required bool commit}) {
    _hold?.cancel();
    _roll?.cancel();
    _roll = null;
    final page = _cancelling ? null : _preview;
    setState(() {
      _preview = null;
      _cancelling = false;
      _show(PageScrubScale.whole(widget.pageCount));
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
    final dragging = _preview != null && !_cancelling;
    // While the finger is down, the corner says how to back out.
    final status = _cancelling
        ? widget.cancelNow
        : _preview == null
        ? null
        : _scale.fine
        ? widget.fineLabel
        : widget.cancelHint;
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
          AppTokens.spaceSmall,
          AppTokens.spaceSmall,
          AppTokens.spaceSmall,
          AppTokens.spaceSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppTokens.spaceSmall,
              ),
              child: Row(
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
                  if (status != null)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppTokens.spaceSmall,
                        ),
                        child: Text(
                          status,
                          maxLines: 2,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _cancelling ? scheme.error : scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.tag_rounded),
                    tooltip: widget.numberTooltip,
                    onPressed: widget.onEnterNumber,
                  ),
                  if (widget.onClose case final close?)
                    IconButton(
                      icon: const Icon(Icons.expand_more_rounded),
                      tooltip: widget.closeTooltip,
                      onPressed: close,
                    ),
                ],
              ),
            ),
            Semantics(
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
                        _drag(details.localPosition, width),
                    onHorizontalDragUpdate: (details) =>
                        _drag(details.localPosition, width),
                    onHorizontalDragEnd: (_) => _release(commit: true),
                    onHorizontalDragCancel: () => _release(commit: false),
                    onTapUp: (details) {
                      final picked = _scale.pageAt(
                        _fractionAt(details.localPosition.dx, width),
                      );
                      if (picked != widget.page) widget.onChanged(picked);
                    },
                    child: AnimatedBuilder(
                      animation: _zoom,
                      builder: (context, _) {
                        final visible = _visible;
                        return CustomPaint(
                          size: Size(width, _trackExtent),
                          painter: _TrackPainter(
                            first: visible.first,
                            last: visible.last,
                            // The thumb stays under the finger; at rest it
                            // sits on the reader's page.
                            thumbPage: dragging ? null : page.toDouble(),
                            thumbFraction: _fraction,
                            page: page,
                            raised: dragging,
                            inset: _inset,
                            digits: widget.digits,
                            active: scheme.primary,
                            rail: scheme.outlineVariant,
                            tick: scheme.outline,
                            thumbRing: scheme.surfaceContainerLowest,
                            label:
                                theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the rail, the ruler under it, and the thumb.
///
/// Mushaf geometry: x is physical, with the first page at the right end in
/// every language.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.first,
    required this.last,
    required this.thumbPage,
    required this.thumbFraction,
    required this.page,
    required this.raised,
    required this.inset,
    required this.digits,
    required this.active,
    required this.rail,
    required this.tick,
    required this.thumbRing,
    required this.label,
  });

  /// The pages at the two ends of the track; fractional while it zooms.
  final double first;
  final double last;

  /// The page the thumb sits on, or null while it follows the finger.
  final double? thumbPage;

  /// Where the finger is, 0–1 from the first page's end.
  final double thumbFraction;

  /// The page whose tick is lit.
  final int page;

  /// Whether the thumb is held: it is drawn larger.
  final bool raised;

  final double inset;
  final String Function(int page) digits;
  final Color active;
  final Color rail;
  final Color tick;
  final Color thumbRing;
  final TextStyle label;

  static const double _railWidth = 4;
  static const double _thumbRadius = 9;
  static const double _railY = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final usable = size.width - 2 * inset;
    final range = last - first;
    double xAt(double fraction) => size.width - inset - usable * fraction;
    double xOf(double page) => xAt(range <= 0 ? 0 : (page - first) / range);

    final line = Paint()
      ..strokeWidth = _railWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(inset, _railY),
      Offset(size.width - inset, _railY),
      line..color = rail,
    );
    final thumbX = switch (thumbPage) {
      final double at => xOf(at).clamp(inset, size.width - inset),
      null => xAt(thumbFraction),
    };
    final thumb = Offset(thumbX, _railY);
    // The part already read: from the first page's end to the thumb.
    canvas.drawLine(
      Offset(size.width - inset, _railY),
      thumb,
      line..color = active,
    );

    // The ruler: every step a short tick, every few a long one with its
    // page number.
    final steps = PageScrubScale.ticksFor(range);
    final stroke = Paint()..strokeWidth = 1.5;
    final from = (first / steps.minor).ceil() * steps.minor;
    for (var p = from; p <= last; p += steps.minor) {
      if (p < 1) continue;
      final major = p % steps.major == 0;
      final x = xOf(p.toDouble());
      canvas.drawLine(
        Offset(x, _railY + 9),
        Offset(x, _railY + (major ? 18 : 14)),
        stroke..color = p == page ? active : tick.withValues(alpha: 0.55),
      );
      if (!major) continue;
      final text = TextPainter(
        text: TextSpan(text: digits(p), style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x - text.width / 2).clamp(0.0, size.width - text.width);
      text.paint(canvas, Offset(dx, _railY + 21));
      text.dispose();
    }

    final radius = _thumbRadius + (raised ? 3 : 0);
    canvas.drawCircle(thumb, radius + 2, Paint()..color = thumbRing);
    canvas.drawCircle(thumb, radius, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.first != first ||
      old.last != last ||
      old.thumbPage != thumbPage ||
      old.thumbFraction != thumbFraction ||
      old.page != page ||
      old.raised != raised ||
      old.active != active ||
      old.rail != rail ||
      old.tick != tick ||
      old.thumbRing != thumbRing ||
      old.label != label;
}
