import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import 'book_geometry.dart';

/// Builds one page of the book.
typedef BookPageBuilder = Widget Function(BuildContext context, int page);

/// A book that turns its pages like paper.
///
/// The book opens right to left. A drag to the right turns forward: in spread
/// mode the left-hand page lifts from its outer edge, swings over the spine,
/// and lands on the right with its back showing the next page; in single mode
/// the page swings away around the spine on its right edge. A drag to the left
/// turns back the same way in reverse. Letting go finishes or undoes the turn
/// with a spring, so the page keeps the speed of the hand.
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

  /// Colour of the back of a sheet and of shadows' base. Defaults to the theme
  /// surface.
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

  late BookGeometry _geometry = _makeGeometry();
  late double _position = _geometry.stepOfPage(widget.page).toDouble();
  bool _dragging = false;
  int _dragStartStep = 0;
  int _reportedStep = -1;

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
      _position = target.toDouble();
      _reportedStep = target;
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onTick() {
    setState(() => _position = _geometry.clampPosition(_settle.value));
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
    // One gesture turns at most one step.
    setState(() {
      _position = _position + details.delta.dx / (width * 0.7);
      _position = _geometry.clampPosition(
        _position.clamp(_dragStartStep - 1.0, _dragStartStep + 1.0),
      );
    });
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
      _report();
      return;
    }
    _settle.value = _position;
    final spring = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 180, damping: 22),
      _position,
      target,
      velocity,
    );
    _settle.animateWith(spring).whenComplete(() {
      if (!mounted || _dragging) return;
      setState(() => _position = target);
      _report();
    });
  }

  void _turn(int by) {
    final base = _position.round();
    _animateTo(_geometry.clampPosition((base + by).toDouble()));
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper ?? Theme.of(context).colorScheme.surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final lastStep = _geometry.stepCount - 1;
        final a = _position.floor().clamp(0, lastStep);
        final f = a >= lastStep ? 0.0 : (_position - a).clamp(0.0, 1.0);

        Widget page(int? number) => number == null
            ? const SizedBox.shrink()
            : RepaintBoundary(
                child: KeyedSubtree(
                  key: ValueKey<int>(number),
                  child: widget.pageBuilder(context, number),
                ),
              );

        final Widget body;
        if (f < 0.0005) {
          body = _geometry.spread
              ? Row(
                  children: [
                    Expanded(child: page(_geometry.rightPage(a))),
                    Expanded(child: page(_geometry.leftPage(a))),
                  ],
                )
              : page(_geometry.rightPage(a));
        } else if (_geometry.spread) {
          body = _SpreadTurn(
            progress: f,
            paper: paper,
            baseRight: page(_geometry.rightPage(a)),
            baseLeft: page(_geometry.leftPage(a + 1)),
            front: page(_geometry.leftPage(a)),
            back: page(_geometry.rightPage(a + 1)),
          );
        } else {
          body = _SingleTurn(
            progress: f,
            paper: paper,
            base: page(_geometry.rightPage(a + 1)),
            sheet: page(_geometry.rightPage(a)),
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
              child: ColoredBox(color: paper, child: body),
            ),
          ),
        );
      },
    );
  }
}

const double _perspective = 0.00035;

Matrix4 _rotation(double angle) => Matrix4.identity()
  ..setEntry(3, 2, _perspective)
  ..rotateY(angle);

/// Two facing pages with the left one turning over the spine onto the right.
class _SpreadTurn extends StatelessWidget {
  const _SpreadTurn({
    required this.progress,
    required this.paper,
    required this.baseRight,
    required this.baseLeft,
    required this.front,
    required this.back,
  });

  final double progress;
  final Color paper;
  final Widget baseRight;
  final Widget baseLeft;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi;
    final showBack = angle > math.pi / 2;
    final lift = math.sin(angle);
    return Stack(
      fit: StackFit.expand,
      children: [
        Row(
          children: [
            Expanded(child: baseRight),
            Expanded(child: baseLeft),
          ],
        ),
        // Shadow the sheet casts on the right-hand page below it, darkest at
        // the spine.
        Row(
          children: [
            Expanded(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerEnd,
                      end: AlignmentDirectional.centerStart,
                      colors: [
                        Colors.black.withValues(alpha: 0.22 * lift),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        // The turning sheet occupies the left half and pivots on the spine.
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: Transform(
                alignment: AlignmentDirectional.centerStart,
                transform: _rotation(-angle),
                child: _Face(
                  paper: paper,
                  shade: showBack ? 0.18 * (1 - lift) : 0.2 * lift,
                  child: showBack
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: back,
                        )
                      : front,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One page swinging away around the spine on its right edge.
class _SingleTurn extends StatelessWidget {
  const _SingleTurn({
    required this.progress,
    required this.paper,
    required this.base,
    required this.sheet,
  });

  final double progress;
  final Color paper;
  final Widget base;
  final Widget sheet;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi / 2;
    final lift = math.sin(angle);
    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18 * lift),
                ],
              ),
            ),
          ),
        ),
        Transform(
          alignment: AlignmentDirectional.centerStart,
          transform: _rotation(-angle),
          child: _Face(paper: paper, shade: 0.22 * lift, child: sheet),
        ),
      ],
    );
  }
}

/// A sheet face: paper under the page, with a shading overlay for depth.
class _Face extends StatelessWidget {
  const _Face({required this.paper, required this.shade, required this.child});

  final Color paper;
  final double shade;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: paper, child: child),
      IgnorePointer(
        child: ColoredBox(color: Colors.black.withValues(alpha: shade)),
      ),
    ],
  );
}
