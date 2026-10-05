import 'package:flutter/material.dart';

/// Drawn ornaments for the Mushaf page. Vector shapes only, no image assets,
/// all coloured from the theme so they follow light, sepia, and dark.

/// Double rule around the page text, with small diamonds at the corners.
class PageFramePainter extends CustomPainter {
  /// Creates the painter.
  const PageFramePainter({required this.color});

  /// Line colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final inner = Paint()
      ..color = color.withValues(alpha: color.a * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final rect = Offset.zero & size;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(14)),
        outer,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(10)),
        inner,
      );
    final fill = Paint()..color = color;
    for (final corner in [
      rect.topLeft + const Offset(6, 6),
      rect.topRight + const Offset(-6, 6),
      rect.bottomLeft + const Offset(6, -6),
      rect.bottomRight + const Offset(-6, -6),
    ]) {
      canvas.drawPath(_diamond(corner, 4), fill);
    }
  }

  @override
  bool shouldRepaint(PageFramePainter old) => old.color != color;
}

Path _diamond(Offset center, double r) => Path()
  ..moveTo(center.dx, center.dy - r)
  ..lineTo(center.dx + r, center.dy)
  ..lineTo(center.dx, center.dy + r)
  ..lineTo(center.dx - r, center.dy)
  ..close();

/// Cartouche with pointed ends, used for surah openings.
class SurahBannerPainter extends CustomPainter {
  /// Creates the painter.
  const SurahBannerPainter({required this.fill, required this.stroke});

  /// Inside colour.
  final Color fill;

  /// Outline colour.
  final Color stroke;

  Path _shape(Size size, double inset) {
    final h = size.height - inset * 2;
    final w = size.width - inset * 2;
    final tip = h / 2;
    return Path()
      ..moveTo(inset, inset + h / 2)
      ..lineTo(inset + tip, inset)
      ..lineTo(inset + w - tip, inset)
      ..lineTo(inset + w, inset + h / 2)
      ..lineTo(inset + w - tip, inset + h)
      ..lineTo(inset + tip, inset + h)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawPath(_shape(size, 0), Paint()..color = fill)
      ..drawPath(
        _shape(size, 0.8),
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      )
      ..drawPath(
        _shape(size, 5),
        Paint()
          ..color = stroke.withValues(alpha: stroke.a * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    final dot = Paint()..color = stroke;
    canvas
      ..drawPath(
        _diamond(Offset(size.height * 0.5 + 6, size.height / 2), 3),
        dot,
      )
      ..drawPath(
        _diamond(
          Offset(size.width - size.height * 0.5 - 6, size.height / 2),
          3,
        ),
        dot,
      );
  }

  @override
  bool shouldRepaint(SurahBannerPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

/// Round medallion for the page number.
class MedallionPainter extends CustomPainter {
  /// Creates the painter.
  const MedallionPainter({required this.fill, required this.stroke});

  /// Inside colour.
  final Color fill;

  /// Ring colour.
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas
      ..drawCircle(center, radius, Paint()..color = fill)
      ..drawCircle(
        center,
        radius - 1,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      )
      ..drawCircle(
        center,
        radius - 4,
        Paint()
          ..color = stroke.withValues(alpha: stroke.a * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
  }

  @override
  bool shouldRepaint(MedallionPainter old) =>
      old.fill != fill || old.stroke != stroke;
}
