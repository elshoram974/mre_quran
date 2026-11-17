import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Drawn ornaments for the Mushaf page. Vector shapes only, no image assets,
/// all coloured from the theme so they follow light, sepia, and dark.

/// The frame of a surah's name: a long panel, and in its middle a cartouche
/// with pointed ends that holds the name. Between the cartouche and the
/// panel's ends runs a band of small stars on a tint, and each end carries a
/// rosette. The design is the app's own, after the way printed Mushafs frame
/// their surah titles.
///
/// It is symmetric, so it reads the same in either direction. The name is
/// written over it by the caller, inside [SurahFrameGeometry.cartouche].
class SurahFramePainter extends CustomPainter {
  /// Creates the painter.
  const SurahFramePainter({
    required this.paper,
    required this.band,
    required this.stroke,
  });

  /// Inside of the cartouche, under the name.
  final Color paper;

  /// Tint of the panel around the cartouche.
  final Color band;

  /// Lines and ornaments.
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, h * 0.032);
    final thin = Paint()
      ..color = stroke.withValues(alpha: stroke.a * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, h * 0.016);
    final solid = Paint()..color = stroke;

    // The panel, with a second rule inside it.
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(line.strokeWidth / 2),
      Radius.circular(h * 0.2),
    );
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(h * 0.11),
      Radius.circular(h * 0.13),
    );
    canvas
      ..drawRRect(outer, Paint()..color = band)
      ..drawRRect(outer, line)
      ..drawRRect(inner, thin);

    final cartouche = SurahFrameGeometry.cartouche(size);
    final rosetteRadius = SurahFrameGeometry.rosetteRadius(size);

    // A rosette at each end.
    for (final x in [inner.left + h * 0.36, inner.right - h * 0.36]) {
      _rosette(canvas, Offset(x, h / 2), rosetteRadius, solid, thin);
    }

    // Small four-pointed stars between the rosettes and the cartouche.
    final step = h * 0.42;
    for (final side in [-1, 1]) {
      final from = side < 0
          ? inner.left + h * 0.36 + rosetteRadius * 1.6
          : cartouche.right + h * 0.32;
      final to = side < 0
          ? cartouche.left - h * 0.32
          : inner.right - h * 0.36 - rosetteRadius * 1.6;
      final count = ((to - from) / step).floor();
      if (count < 1) continue;
      final gap = (to - from) / count;
      for (var i = 0; i <= count; i++) {
        _star(canvas, Offset(from + gap * i, h / 2), h * 0.1, solid);
      }
    }

    // The cartouche: pointed ends, a double outline, paper inside.
    final shape = _cartouche(cartouche);
    canvas
      ..drawPath(shape, Paint()..color = paper)
      ..drawPath(shape, line)
      ..drawPath(_cartouche(cartouche.deflate(h * 0.07)), thin);
    // A bead at each point.
    for (final x in [cartouche.left, cartouche.right]) {
      canvas.drawCircle(Offset(x, h / 2), h * 0.045, solid);
    }
  }

  /// A long shape whose ends come to a point in curves, like a cartouche.
  Path _cartouche(Rect r) {
    final end = r.height * 0.62;
    final mid = r.center.dy;
    return Path()
      ..moveTo(r.left + end, r.top)
      ..lineTo(r.right - end, r.top)
      ..cubicTo(
        r.right - end * 0.35,
        r.top,
        r.right - end * 0.2,
        mid - r.height * 0.18,
        r.right,
        mid,
      )
      ..cubicTo(
        r.right - end * 0.2,
        mid + r.height * 0.18,
        r.right - end * 0.35,
        r.bottom,
        r.right - end,
        r.bottom,
      )
      ..lineTo(r.left + end, r.bottom)
      ..cubicTo(
        r.left + end * 0.35,
        r.bottom,
        r.left + end * 0.2,
        mid + r.height * 0.18,
        r.left,
        mid,
      )
      ..cubicTo(
        r.left + end * 0.2,
        mid - r.height * 0.18,
        r.left + end * 0.35,
        r.top,
        r.left + end,
        r.top,
      )
      ..close();
  }

  /// A four-pointed star.
  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// Eight petals around a small disc, on a disc of paper.
  void _rosette(Canvas canvas, Offset c, double r, Paint solid, Paint thin) {
    canvas.drawCircle(c, r * 1.05, Paint()..color = paper);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.62,
        r * 0.32,
        thin,
      );
    }
    canvas
      ..drawCircle(c, r * 0.28, solid)
      ..drawCircle(c, r * 1.02, thin);
  }

  @override
  bool shouldRepaint(SurahFramePainter old) =>
      old.paper != paper || old.band != band || old.stroke != stroke;
}

/// Where the parts of a surah frame of a given size lie, shared by the
/// painter and the widgets that write the name in it.
abstract final class SurahFrameGeometry {
  /// The cartouche that holds the name: half the frame's width, or less on a
  /// narrow frame so the rosettes keep their room.
  static Rect cartouche(Size size) {
    final h = size.height;
    final room = size.width - 2 * (h * 0.11 + h * 0.72 + h * 0.3);
    final width = math.max(h * 2.2, math.min(size.width * 0.5, room));
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: h * 0.74,
    );
  }

  /// Radius of the rosette at each end.
  static double rosetteRadius(Size size) => size.height * 0.26;
}
