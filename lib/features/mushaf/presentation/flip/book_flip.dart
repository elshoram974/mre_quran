import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import 'book_geometry.dart';
import 'page_curl_painter.dart';

/// Builds one page of the book.
typedef BookPageBuilder = Widget Function(BuildContext context, int page);

/// A book that turns its pages like paper.
///
/// The book opens right to left. A drag to the right turns forward. In spread
/// mode the left-hand page lifts from its outer edge, bends as it rises, swings
/// over the spine, and lands on the right with its back showing the next page.
/// In single mode the page bends and swings away around the spine. A drag to
/// the left turns back the same way in reverse. Letting go finishes or undoes
/// the turn with a spring that keeps the speed of the hand. One gesture turns
/// at most one step: one page, or one pair of facing pages.
///
/// The sheet is drawn from snapshots of the pages, so any widget can be a page.
/// The neighbouring pages stay built underneath the visible ones so a snapshot
/// is ready the moment a drag starts.
///
/// [page] is the page the book should rest on. [onPageChanged] reports the
/// right-hand page whenever a turn settles.
class BookFlip extends StatefulWidget {
  /// Creates a book of [pageCount] pages resting on [page].
  const BookFlip({
    super.key,
    required this.pageCount,
    required this.spread,
    required this.page,
    required this.pageBuilder,
    required this.onPageChanged,
    this.paper,
    this.nextLabel,
    this.previousLabel,
  });

  /// Number of pages.
  final int pageCount;

  /// Whether two pages face each other.
  final bool spread;

  /// The page the book rests on, 1-based.
  final int page;

  /// Builds a page.
  final BookPageBuilder pageBuilder;

  /// Called with the right-hand page after a turn settles.
  final ValueChanged<int> onPageChanged;

  /// Colour of the paper behind every page. Defaults to the theme surface.
  final Color? paper;

  /// Screen reader label of the "next page" action.
  final String? nextLabel;

  /// Screen reader label of the "previous page" action.
  final String? previousLabel;

  @override
  State<BookFlip> createState() => _BookFlipState();
}

class _BookFlipState extends State<BookFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onTick);

  final Map<int, GlobalKey> _keys = {};
  late BookGeometry _geometry = _makeGeometry();
  late double _position = _geometry.stepOfPage(widget.page).toDouble();
  bool _dragging = false;
  int _dragStartStep = 0;
  int _reportedStep = 0;

  ui.Image? _front;
  ui.Image? _back;
  int? _textureStep;
  double _pixelRatio = 1;

  BookGeometry _makeGeometry() =>
      BookGeometry(pageCount: widget.pageCount, spread: widget.spread);

  @override
  void initState() {
    super.initState();
    _reportedStep = _position.round();
  }

  @override
  void didUpdateWidget(BookFlip old) {
    super.didUpdateWidget(old);
    final geometry = _makeGeometry();
    final changedMode =
        geometry.spread != _geometry.spread ||
        geometry.pageCount != _geometry.pageCount;
    _geometry = geometry;
    final target = geometry.stepOfPage(widget.page);
    if (changedMode ||
        (!_dragging && !_settle.isAnimating && target != _reportedStep)) {
      _settle.stop();
      _disposeTextures();
      _position = target.toDouble();
      _reportedStep = target;
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    _disposeTextures();
    super.dispose();
  }

  GlobalKey _keyFor(int page) => _keys.putIfAbsent(page, GlobalKey.new);

  void _disposeTextures() {
    _front?.dispose();
    _back?.dispose();
    _front = null;
    _back = null;
    _textureStep = null;
  }

  ui.Image? _snapshot(int? page) {
    if (page == null) return null;
    final render = _keys[page]?.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary || !render.hasSize) return null;
    if (render.debugNeedsPaint) return null;
    return render.toImageSync(pixelRatio: _pixelRatio);
  }

  /// Takes the snapshots a turn between [step] and [step] + 1 needs.
  void _ensureTextures(int step) {
    if (_textureStep == step && _front != null) return;
    _disposeTextures();
    final front = _snapshot(
      _geometry.spread ? _geometry.leftPage(step) : _geometry.rightPage(step),
    );
    if (front == null) return;
    _front = front;
    _back = _geometry.spread ? _snapshot(_geometry.rightPage(step + 1)) : null;
    _textureStep = step;
  }

  void _onTick() {
    final next = _geometry.clampPosition(_settle.value);
    final step = next.floor();
    if (next - step > 0.0005) _ensureTextures(step);
    setState(() => _position = next);
  }

  void _report() {
    final step = _position.round();
    if (step == _reportedStep) return;
    _reportedStep = step;
    widget.onPageChanged(_geometry.pageOfStep(step));
  }

  void _dragStart(DragStartDetails details) {
    _settle.stop();
    _dragging = true;
    _dragStartStep = _position.round();
  }

  void _dragUpdate(DragUpdateDetails details, double width) {
    // A drag to the right turns forward. A full width of travel is a bit less
    // than a full turn so the page feels light under the finger.
    var next = _position + details.delta.dx / (width * 0.7);
    next = next.clamp(_dragStartStep - 1.0, _dragStartStep + 1.0);
    next = _geometry.clampPosition(next);
    final step = next.floor();
    if (next - step > 0.0005) _ensureTextures(step);
    setState(() => _position = next);
  }

  void _dragEnd(DragEndDetails details, double width) {
    _dragging = false;
    final velocity = details.velocity.pixelsPerSecond.dx / (width * 0.7);
    final projected = _position + velocity * 0.18;
    final target = _geometry.clampPosition(
      projected.roundToDouble().clamp(
        _dragStartStep - 1.0,
        _dragStartStep + 1.0,
      ),
    );
    _animateTo(target, velocity);
  }

  void _animateTo(double target, [double velocity = 0]) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _settle.stop();
      setState(() => _position = target);
      _finish();
      return;
    }
    _settle.value = _position;
    final spring = SpringSimulation(
      // Slightly under-damped: the sheet settles with a little life.
      const SpringDescription(mass: 1, stiffness: 190, damping: 24),
      _position,
      target,
      velocity,
    );
    _settle.animateWith(spring).whenComplete(() {
      if (!mounted || _dragging) return;
      setState(() => _position = target);
      _finish();
    });
  }

  void _finish() {
    _disposeTextures();
    _report();
  }

  void _turn(int by) {
    final base = _position.round();
    _dragStartStep = base;
    final target = _geometry.clampPosition((base + by).toDouble());
    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper ?? Theme.of(context).colorScheme.surface;
    _pixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final spread = _geometry.spread;
        final half = width / 2;
        final lastStep = _geometry.stepCount - 1;
        final k = _position.floor().clamp(0, lastStep);
        final f = k >= lastStep ? 0.0 : (_position - k).clamp(0.0, 1.0);
        final turning = f > 0.0005 && _front != null && _textureStep == k;
        final rest = _position.round().clamp(0, lastStep);

        // Pages that must stay built so a snapshot is always ready: the
        // current step and the steps on either side.
        final needed = <int>{
          for (var s = rest - 1; s <= rest + 1; s++) ...[
            ?_geometry.rightPage(s),
            ?_geometry.leftPage(s),
          ],
        };

        // Pages that are visible now. While a sheet turns, the pages under it
        // are the next step's left page and this step's right page (spread),
        // or just the next page (single).
        final visible = <int>{};
        if (turning && spread) {
          visible.addAll([?_geometry.rightPage(k), ?_geometry.leftPage(k + 1)]);
        } else if (turning) {
          visible.addAll([?_geometry.rightPage(k + 1)]);
        } else if (spread) {
          visible.addAll([
            ?_geometry.rightPage(rest),
            ?_geometry.leftPage(rest),
          ]);
        } else {
          visible.addAll([?_geometry.rightPage(rest)]);
        }

        // Each page sits in the slot its number says: odd on the right half,
        // even on the left half in spread mode, the whole area in single mode.
        Widget slot(int pageNumber, {required bool hidden}) {
          final right = pageNumber.isOdd;
          final child = RepaintBoundary(
            key: _keyFor(pageNumber),
            child: ColoredBox(
              color: paper,
              child: KeyedSubtree(
                key: ValueKey<int>(pageNumber),
                child: widget.pageBuilder(context, pageNumber),
              ),
            ),
          );
          final content = IgnorePointer(ignoring: hidden, child: child);
          return spread
              ? PositionedDirectional(
                  key: ValueKey<String>('slot-$pageNumber'),
                  start: right ? 0 : half,
                  width: half,
                  top: 0,
                  bottom: 0,
                  child: content,
                )
              : Positioned.fill(
                  key: ValueKey<String>('slot-$pageNumber'),
                  child: content,
                );
        }

        final ordered = needed.toList()..sort();
        final children = <Widget>[
          for (final n in ordered)
            if (!visible.contains(n)) slot(n, hidden: true),
          for (final n in ordered)
            if (visible.contains(n)) slot(n, hidden: false),
        ];

        if (turning) {
          children.add(
            PositionedDirectional(
              // The turning sheet is the left half in spread mode and the
              // whole area in single mode, hinged on the spine.
              start: spread ? half : 0,
              width: spread ? half : width,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: PageCurlPainter(
                    progress: f,
                    front: _front!,
                    back: _back,
                    vanishX: spread ? half : width / 2,
                    pixelRatio: _pixelRatio,
                    paper: paper,
                  ),
                  size: Size(spread ? half : width, height),
                ),
              ),
            ),
          );
        }

        return Semantics(
          customSemanticsActions: {
            if (widget.nextLabel != null)
              CustomSemanticsAction(label: widget.nextLabel!): () => _turn(1),
            if (widget.previousLabel != null)
              CustomSemanticsAction(label: widget.previousLabel!): () =>
                  _turn(-1),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _dragStart,
            onHorizontalDragUpdate: (d) => _dragUpdate(d, width),
            onHorizontalDragEnd: (d) => _dragEnd(d, width),
            // The book opens right to left in every app language.
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ClipRect(
                child: ColoredBox(
                  color: paper,
                  child: Stack(fit: StackFit.expand, children: children),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
