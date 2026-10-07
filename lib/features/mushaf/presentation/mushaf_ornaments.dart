import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Drawn ornaments for the Mushaf page. Vector shapes only, no image assets,
/// all coloured from the theme so they follow light, sepia, and dark.

/// The frame of a surah opening, after the printed Madinah Mushaf: a long
/// panel with a double border; at each end a lattice panel with a rosette;
/// and beside the name two round medallions, which hold the surah's details
/// (see [SurahBannerGeometry]).
class SurahBannerPainter extends CustomPainter {
  /// Creates the painter.
  const SurahBannerPainter({required this.fill, required this.stroke});

  /// Inside colour.
  final Color fill;

  /// Line and ornament colour.
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final rect = Offset.zero & size;
    final line = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final thin = Paint()
      ..color = stroke.withValues(alpha: stroke.a * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final faint = Paint()
      ..color = stroke.withValues(alpha: stroke.a * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final solid = Paint()..color = stroke;
    final outer = RRect.fromRectAndRadius(
      rect.deflate(0.9),
      const Radius.circular(3),
    );

    canvas
      ..drawRRect(outer, Paint()..color = fill)
      ..drawRRect(outer, line)
      ..drawRRect(
        RRect.fromRectAndRadius(rect.deflate(4.5), const Radius.circular(2)),
        thin,
      );

    final inner = rect.deflate(4.5);
    final end = SurahBannerGeometry.endWidth(size.width, h);
    for (final start in [true, false]) {
      final panel = start
          ? Rect.fromLTRB(inner.left, inner.top, inner.left + end, inner.bottom)
          : Rect.fromLTRB(
              inner.right - end,
              inner.top,
              inner.right,
              inner.bottom,
            );
      _panel(canvas, panel, start, faint, thin, solid, line);
      final centre = Offset(
        start
            ? SurahBannerGeometry.circleCentreX(size.width, h, left: true)
            : SurahBannerGeometry.circleCentreX(size.width, h, left: false),
        h / 2,
      );
      _medallion(
        canvas,
        centre,
        SurahBannerGeometry.circleDiameter(size.width, h) / 2,
        line,
        thin,
        Paint()..color = stroke.withValues(alpha: stroke.a * 0.1),
      );
    }
  }

  /// An end panel: a lattice of diagonals with a dot at each crossing, and a
  /// rosette in the middle, inside a double rule.
  void _panel(
    Canvas canvas,
    Rect panel,
    bool towardNameOnRight,
    Paint faint,
    Paint thin,
    Paint solid,
    Paint line,
  ) {
    canvas.save();
    canvas.clipRect(panel);
    final pitch = panel.height / 5;
    final span = panel.width + panel.height;
    for (var k = -panel.height; k < span; k += pitch) {
      canvas
        ..drawLine(
          Offset(panel.left + k, panel.top),
          Offset(panel.left + k + panel.height, panel.bottom),
          faint,
        )
        ..drawLine(
          Offset(panel.left + k, panel.bottom),
          Offset(panel.left + k + panel.height, panel.top),
          faint,
        );
    }
    for (var x = panel.left; x < panel.right + pitch; x += pitch) {
      for (var y = panel.top; y < panel.bottom + pitch; y += pitch) {
        canvas.drawCircle(Offset(x, y), 0.9, solid);
      }
    }
    canvas.restore();
    // The rosette's disc clears the lattice behind it, so the lattice reads
    // as a border around it.
    _rosette(canvas, panel.center, panel.height * 0.3, solid, thin);
    // The rule closing the panel on the side of the name.
    final x = towardNameOnRight ? panel.right : panel.left;
    canvas.drawLine(Offset(x, panel.top), Offset(x, panel.bottom), line);
  }

  /// A medallion: a double ring around a tinted disc.
  void _medallion(
    Canvas canvas,
    Offset centre,
    double radius,
    Paint line,
    Paint thin,
    Paint tint,
  ) {
    canvas
      ..drawCircle(centre, radius, tint)
      ..drawCircle(centre, radius, line)
      ..drawCircle(centre, radius - 3.2, thin);
    // Small beads on the outer ring at the four directions.
    final bead = Paint()..color = line.color;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * (radius + 2.6),
        1.1,
        bead,
      );
    }
  }

  /// Eight petals around a small disc.
  void _rosette(Canvas canvas, Offset c, double r, Paint solid, Paint thin) {
    canvas.drawCircle(c, r * 1.05, Paint()..color = fill);
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

/// Where the parts of a surah banner of a given size lie, shared by the
/// painter and the widgets that put text inside it. On a narrow page the
/// ornaments shrink so the name keeps its room.
abstract final class SurahBannerGeometry {
  /// Width of a lattice panel at each end.
  static double endWidth(double width, double height) =>
      math.min(height * 1.45, width * 0.15);

  /// Diameter of a medallion.
  static double circleDiameter(double width, double height) =>
      math.min(height * 0.74, width * 0.15);

  /// Space between a lattice panel and its medallion.
  static const double circleGap = 6;

  /// Distance from a side edge to the start of its medallion.
  static double circleInset(double width, double height) =>
      4.5 + endWidth(width, height) + circleGap;

  /// Distance of a medallion's centre from the banner's left edge when
  /// [left], or from its right edge.
  static double circleCentreX(
    double width,
    double height, {
    required bool left,
  }) {
    final fromEdge =
        circleInset(width, height) + circleDiameter(width, height) / 2;
    return left ? fromEdge : width - fromEdge;
  }
}
