import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Drawn ornaments for the Mushaf page. Vector shapes only, no image assets,
/// all coloured from the theme so they follow light, sepia, and dark.

/// The frame of a surah opening, after the printed Madinah Mushaf: a long
/// panel with a double border, and at each end a rosette with a pointed leaf
/// in its own compartment. The surah name goes in the middle.
class SurahBannerPainter extends CustomPainter {
  /// Creates the painter.
  const SurahBannerPainter({required this.fill, required this.stroke});

  /// Inside colour.
  final Color fill;

  /// Line and ornament colour.
  final Color stroke;

  /// Width of an end compartment for a banner of [height].
  static double endWidth(double height) => height * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final thin = Paint()
      ..color = stroke.withValues(alpha: stroke.a * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final solid = Paint()..color = stroke;

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.9), const Radius.circular(3)),
        Paint()..color = fill,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.9), const Radius.circular(3)),
        line,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(4.5), const Radius.circular(2)),
        thin,
      );

    final end = endWidth(size.height);
    final inner = rect.deflate(4.5);
    for (final left in [true, false]) {
      // The divider between the end compartment and the name.
      final x = left ? inner.left + end : inner.right - end;
      for (final dx in [0.0, left ? 3.0 : -3.0]) {
        canvas.drawLine(
          Offset(x + dx, inner.top),
          Offset(x + dx, inner.bottom),
          dx == 0 ? line : thin,
        );
      }
      final centre = Offset(
        left ? inner.left + end * 0.58 : inner.right - end * 0.58,
        size.height / 2,
      );
      _rosette(canvas, centre, size.height * 0.2, solid, thin);
      // A leaf pointing out to the end of the banner.
      final tip = Offset(
        left ? inner.left + end * 0.12 : inner.right - end * 0.12,
        size.height / 2,
      );
      final base = Offset(
        left ? centre.dx - size.height * 0.27 : centre.dx + size.height * 0.27,
        size.height / 2,
      );
      final bulge = size.height * 0.12;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..quadraticBezierTo(
            (tip.dx + base.dx) / 2,
            tip.dy - bulge,
            base.dx,
            base.dy,
          )
          ..quadraticBezierTo(
            (tip.dx + base.dx) / 2,
            tip.dy + bulge,
            tip.dx,
            tip.dy,
          ),
        thin,
      );
      // Scrolls curling toward the divider, above and below.
      for (final up in [true, false]) {
        final sign = up ? -1.0 : 1.0;
        final towards = left ? 1.0 : -1.0;
        final start = Offset(centre.dx, centre.dy + sign * size.height * 0.24);
        canvas.drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..cubicTo(
              start.dx + towards * end * 0.2,
              start.dy + sign * size.height * 0.1,
              x - towards * end * 0.15,
              start.dy + sign * size.height * 0.06,
              x - towards * end * 0.08,
              start.dy - sign * size.height * 0.04,
            ),
          thin,
        );
      }
    }
  }

  /// Eight petals around a small disc.
  void _rosette(Canvas canvas, Offset c, double r, Paint solid, Paint thin) {
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.62,
        r * 0.32,
        thin,
      );
    }
    canvas
      ..drawCircle(c, r * 0.3, solid)
      ..drawCircle(c, r * 1.02, thin);
  }

  @override
  bool shouldRepaint(SurahBannerPainter old) =>
      old.fill != fill || old.stroke != stroke;
}
