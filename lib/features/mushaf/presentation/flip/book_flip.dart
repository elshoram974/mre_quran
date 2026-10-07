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
///
/// Single mode shows one page of that open book at a time, and moves the way
/// the reader's eyes and hands would. Going from a right-hand (odd) page to the
/// page facing it slides across the open book: nothing turns. Going from a
/// left-hand (even) page to the next one turns the leaf: the even page lifts,
/// swings over the spine onto the page before it, and lands showing the next
/// page on its back while the page after appears underneath. Going back does
/// the same in reverse. A drag to
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
    this.realistic = true,
    this.nextLabel,
    this.previousLabel,
    this.onTurnStart,
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

  /// Whether pages bend and turn like paper. When false, pages slide.
  final bool realistic;

  /// Screen reader label of the "next page" action.
  final String? nextLabel;

  /// Screen reader label of the "previous page" action.
  final String? previousLabel;

  /// Called when a turn begins, by a drag or an action, before anything moves.
  final VoidCallback? onTurnStart;

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

  /// 1 while turning forward, -1 while turning back, eased between so the
  /// bend of the sheet mirrors smoothly when the hand changes direction.
  double _lead = 1;
  double _leadTarget = 1;

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

  /// Whether going from [step] to [step] + 1 turns a leaf. In single mode
  /// only a left-hand (even) page turns; a right-hand page slides to the page
  /// facing it in the same spread.
  bool _turnsLeaf(int step) => _geometry.spread || (step + 1).isEven;

  /// Takes the snapshots a turn between [step] and [step] + 1 needs.
  void _ensureTextures(int step) {
    if (!widget.realistic || !_turnsLeaf(step)) return;
    if (_textureStep == step && _front != null) return;
    _disposeTextures();
    final front = _snapshot(
      _geometry.spread ? _geometry.leftPage(step) : _geometry.rightPage(step),
    );
    if (front == null) return;
    _front = front;
    // The back of the sheet shows the page that follows it.
    _back = _snapshot(_geometry.rightPage(step + 1));
    _textureStep = step;
  }

  /// Points the bend of the sheet the way the turn is going.
  void _steer(double direction) {
    if (direction == 0) return;
    _leadTarget = direction > 0 ? 1 : -1;
  }

  void _easeLead() => _lead += (_leadTarget - _lead) * 0.3;

  void _onTick() {
    final next = _geometry.clampPosition(_settle.value);
    _easeLead();
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
    widget.onTurnStart?.call();
  }

  void _dragUpdate(DragUpdateDetails details, double width) {
    // A drag to the right turns forward. A full width of travel is a bit less
    // than a full turn so the page feels light under the finger.
    var next = _position + details.delta.dx / (width * 0.7);
    next = next.clamp(_dragStartStep - 1.0, _dragStartStep + 1.0);
    next = _geometry.clampPosition(next);
    _steer(details.delta.dx);
    _easeLead();
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
    _steer(target - _position);
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
    widget.onTurnStart?.call();
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
        // Single mode, within one spread: the two facing pages slide.
        final sliding = !spread && f > 0.0005 && !_turnsLeaf(k);

        // Pages that must stay built so a snapshot is always ready: the
        // current step and the steps on either side. Single mode also keeps
        // the page that faces the turning sheet.
        final needed = <int>{
          for (
            var s = rest - (spread ? 1 : 2);
            s <= rest + (spread ? 1 : 2);
            s++
          ) ...[?_geometry.rightPage(s), ?_geometry.leftPage(s)],
        };

        // Pages that are visible now. While a sheet turns, the pages under it
        // are the next step's left page and this step's right page (spread),
        // or just the next page (single).
        final visible = <int>{};
        if (sliding) {
          visible.addAll([
            ?_geometry.rightPage(k),
            ?_geometry.rightPage(k + 1),
          ]);
        } else if (turning && spread) {
          visible.addAll([?_geometry.rightPage(k), ?_geometry.leftPage(k + 1)]);
        } else if (turning) {
          // The sheet's back shows the next page; under it lies the page after.
          visible.addAll([?_geometry.rightPage(k + 2)]);
        } else if (spread) {
          visible.addAll([
            ?_geometry.rightPage(rest),
            ?_geometry.leftPage(rest),
          ]);
        } else {
          visible.addAll([?_geometry.rightPage(rest)]);
        }

        // In single mode the sheet swings past the spine onto the facing page,
        // the one before it, which slides into view with the sheet.
        final facing = turning && !spread ? _geometry.rightPage(k - 1) : null;

        // Each page sits in the slot its number says: odd on the right half,
        // even on the left half in spread mode, the whole area in single mode.
        Widget slot(int pageNumber, {required bool hidden}) {
          final isFacing = pageNumber == facing;
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
          final content = IgnorePointer(
            ignoring: hidden || isFacing,
            child: child,
          );
          if (isFacing) {
            // Beyond the spine: one page width past the reading start.
            return PositionedDirectional(
              key: ValueKey<String>('slot-$pageNumber'),
              start: -width,
              width: width,
              top: 0,
              bottom: 0,
              child: content,
            );
          }
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
                  // Right to left: the facing page comes in from the left as
                  // the current one moves out to the right.
                  child: sliding && !hidden
                      ? Transform.translate(
                          offset: Offset(
                            (pageNumber == k + 1 ? f : f - 1) * width,
                            0,
                          ),
                          child: content,
                        )
                      : content,
                );
        }

        final ordered = needed.toList()..sort();
        final children = !widget.realistic
            ? const <Widget>[]
            : <Widget>[
                for (final n in ordered)
                  if (!visible.contains(n) && n != facing)
                    slot(n, hidden: true),
                ?facing == null ? null : slot(facing, hidden: false),
                for (final n in ordered)
                  if (visible.contains(n)) slot(n, hidden: false),
              ];

        if (turning && widget.realistic) {
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
                    vanishX: half * (spread ? 1 : 2),
                    pixelRatio: _pixelRatio,
                    paper: paper,
                    lead: _lead,
                  ),
                  size: Size(spread ? half : width, height),
                ),
              ),
            ),
          );
        }

        // In single mode the view follows the sheet as it lands, so the page
        // on its back ends up in front of the reader.
        final shift = turning && !spread
            ? width *
                  Curves.easeInOutCubic.transform(
                    ((f - 0.25) / 0.75).clamp(0.0, 1.0),
                  )
            : 0.0;

        final Widget content = widget.realistic
            ? Transform.translate(
                offset: Offset(-shift, 0),
                // The facing page and the landing sheet lie past the edge.
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: children,
                ),
              )
            : _slide(context, paper: paper, k: k, f: f, width: width);

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
                clipper: const _SideClip(),
                child: ColoredBox(color: paper, child: content),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Plain sliding pages, used when realistic turning is off.
  Widget _slide(
    BuildContext context, {
    required Color paper,
    required int k,
    required double f,
    required double width,
  }) {
    Widget page(int? number) => number == null
        ? const SizedBox.shrink()
        : ColoredBox(
            color: paper,
            child: KeyedSubtree(
              key: ValueKey<int>(number),
              child: widget.pageBuilder(context, number),
            ),
          );

    Widget step(int s) => _geometry.spread
        ? Row(
            children: [
              Expanded(child: page(_geometry.rightPage(s))),
              Expanded(child: page(_geometry.leftPage(s))),
            ],
          )
        : page(_geometry.rightPage(s));

    if (f < 0.0005) return step(_position.round());
    // Right to left: the next step comes in from the left as the current one
    // moves out to the right.
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.translate(offset: Offset(f * width, 0), child: step(k)),
        Transform.translate(
          offset: Offset((f - 1) * width, 0),
          child: step(k + 1),
        ),
      ],
    );
  }
}

/// Clips the sides of the book but not its top and bottom, so a sheet that
/// lifts toward the reader and grows a little is not cut off.
class _SideClip extends CustomClipper<Rect> {
  const _SideClip();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -size.height * 0.1, size.width, size.height * 1.1);

  @override
  bool shouldReclip(_SideClip old) => false;
}
