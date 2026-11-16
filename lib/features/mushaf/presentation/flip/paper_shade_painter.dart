import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Shades a page as the side of an open book it is.
///
/// A page falls away into the spine, so it darkens toward its inner edge. At
/// its outer edge the edges of the pages lying under it show as fine lines:
/// few when that side of the book is thin, more as it fills.
///
/// Mushaf geometry: the book opens right to left in every app language, so
/// a right-hand page has its spine on its left edge and a left-hand page on
/// its right. The sides are physical and never mirror with the app.
class PaperShadePainter extends CustomPainter {
  /// Creates the shading of one page.
  const PaperShadePainter({
    required this.rightHand,
    required this.shade,
    required this.stack,
  });

  /// Whether this is a right-hand page: its spine is on its left.
  final bool rightHand;

  /// The colour of shadow, from the theme.
  final Color shade;

  /// How much of the book lies under this page, 0–1.
  final double stack;

  /// How far the spine's shadow reaches into the page, as a share of its
  /// width.
  static const double _gutterReach = 0.07;

  /// Darkness of the shadow at the spine itself.
  static const double _gutterDepth = 0.2;

  /// The most page edges drawn at the outer edge, and the gap between two.
  static const int _maxEdges = 5;
  static const double _edgeGap = 1.5;

  /// How many page edges show for [stack].
  static int edgesFor(double stack) =>
      1 + (stack.clamp(0.0, 1.0) * (_maxEdges - 1)).round();

  @override
  void paint(Canvas canvas, Size size) {
    final spine = rightHand ? 0.0 : size.width;
    final inward = rightHand ? 1.0 : -1.0;
    final reach = size.width * _gutterReach;
    canvas.drawRect(
      Rect.fromLTRB(
        rightHand ? 0 : size.width - reach,
        0,
        rightHand ? reach : size.width,
        size.height,
      ),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(spine, 0),
          Offset(spine + inward * reach, 0),
          [
            shade.withValues(alpha: _gutterDepth),
            shade.withValues(alpha: _gutterDepth * 0.35),
            shade.withValues(alpha: 0),
          ],
          const [0, 0.35, 1],
        ),
    );

    // The pages under this one, at the edge away from the spine.
    final outer = rightHand ? size.width : 0.0;
    final line = Paint()..strokeWidth = 1;
    for (var i = 0; i < edgesFor(stack); i++) {
      final x = outer - inward * (0.5 + i * _edgeGap);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        // Each edge further in is fainter.
        line..color = shade.withValues(alpha: 0.16 - i * 0.025),
      );
    }
  }

  @override
  bool shouldRepaint(PaperShadePainter old) =>
      old.rightHand != rightHand || old.shade != shade || old.stack != stack;
}
