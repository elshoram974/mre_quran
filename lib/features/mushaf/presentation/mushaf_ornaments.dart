import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../settings/domain/app_settings.dart';

/// Drawn ornaments for the Mushaf page. Vector shapes only, no image assets,
/// all coloured from the theme so they follow light, sepia, and dark.

/// The frame of a surah's name, in one of the [SurahFrameStyle]s: a long
/// panel across the line and, in its middle, a plaque that holds the name.
/// The designs are the app's own, after the ways printed Mushafs frame their
/// surah titles.
///
/// Every style is symmetric, so it reads the same in either direction. The
/// name is written over it by the caller, inside [SurahFrameGeometry.name],
/// or is the printed page's own calligraphy.
class SurahFramePainter extends CustomPainter {
  /// Creates the painter.
  const SurahFramePainter({
    required this.style,
    required this.paper,
    required this.band,
    required this.stroke,
    this.nameWidth = 0,
  });

  /// Which frame to draw.
  final SurahFrameStyle style;

  /// Inside of the plaque, under the name.
  final Color paper;

  /// Tint of the panel around the plaque.
  final Color band;

  /// Lines and ornaments.
  final Color stroke;

  /// Width of the name the plaque must hold, in the canvas's pixels.
  final double nameWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final _Ink ink = (
      line: Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, h * 0.032),
      thin: Paint()
        ..color = stroke.withValues(alpha: stroke.a * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, h * 0.016),
      solid: Paint()..color = stroke,
      paper: Paint()..color = paper,
      band: Paint()..color = band,
    );
    final plaque = SurahFrameGeometry.plaque(size, style, nameWidth: nameWidth);
    switch (style) {
      case SurahFrameStyle.cartouche:
        _paintCartouche(canvas, size, plaque, ink);
      case SurahFrameStyle.classic:
        _paintClassic(canvas, size, plaque, ink);
      case SurahFrameStyle.arch:
        _paintArch(canvas, size, plaque, ink);
      case SurahFrameStyle.minimal:
        _paintMinimal(canvas, size, plaque, ink);
    }
  }

  /// A rounded panel of small stars, a rosette at each end, and a cartouche
  /// with pointed ends.
  void _paintCartouche(Canvas canvas, Size size, Rect plaque, _Ink ink) {
    final h = size.height;
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(ink.line.strokeWidth / 2),
      Radius.circular(h * 0.2),
    );
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(h * 0.11),
      Radius.circular(h * 0.13),
    );
    canvas
      ..drawRRect(outer, ink.band)
      ..drawRRect(outer, ink.line)
      ..drawRRect(inner, ink.thin);

    final radius = h * 0.26;
    final ends = [inner.left + h * 0.36, inner.right - h * 0.36];
    for (final x in ends) {
      _rosette(canvas, Offset(x, h / 2), radius, ink);
    }
    _row(
      canvas,
      from: ends.first + radius * 1.6,
      to: plaque.left - h * 0.32,
      y: h / 2,
      step: h * 0.42,
      draw: (c) => _star(canvas, c, h * 0.1, ink.solid),
    );
    _row(
      canvas,
      from: plaque.right + h * 0.32,
      to: ends.last - radius * 1.6,
      y: h / 2,
      step: h * 0.42,
      draw: (c) => _star(canvas, c, h * 0.1, ink.solid),
    );

    final shape = _pointed(plaque);
    canvas
      ..drawPath(shape, ink.paper)
      ..drawPath(shape, ink.line)
      ..drawPath(_pointed(plaque.deflate(h * 0.07)), ink.thin);
    for (final x in [plaque.left, plaque.right]) {
      canvas.drawCircle(Offset(x, h / 2), h * 0.045, ink.solid);
    }
  }

  /// A square-cornered panel, double ruled, with a chain of lozenges, a
  /// lozenge at each end, and a plaque with cut corners.
  void _paintClassic(Canvas canvas, Size size, Rect plaque, _Ink ink) {
    final h = size.height;
    final outer = (Offset.zero & size).deflate(ink.line.strokeWidth / 2);
    final inner = (Offset.zero & size).deflate(h * 0.12);
    canvas
      ..drawRect(outer, ink.band)
      ..drawRect(outer, ink.line)
      ..drawRect(inner, ink.thin);
    // A small square at each inner corner.
    final corner = h * 0.07;
    for (final p in [
      inner.topLeft,
      inner.topRight,
      inner.bottomLeft,
      inner.bottomRight,
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: p, width: corner, height: corner),
        ink.solid,
      );
    }

    final endRadius = h * 0.24;
    final ends = [inner.left + h * 0.4, inner.right - h * 0.4];
    for (final x in ends) {
      final c = Offset(x, h / 2);
      final big = _lozenge(c, endRadius * 1.3, endRadius);
      canvas
        ..drawPath(big, ink.paper)
        ..drawPath(big, ink.line)
        ..drawPath(_lozenge(c, endRadius * 0.62, endRadius * 0.48), ink.solid);
    }
    var filled = false;
    void chain(Offset c) {
      final shape = _lozenge(c, h * 0.11, h * 0.11);
      canvas.drawPath(shape, filled ? ink.solid : ink.thin);
      filled = !filled;
    }

    _row(
      canvas,
      from: ends.first + endRadius * 1.9,
      to: plaque.left - h * 0.26,
      y: h / 2,
      step: h * 0.32,
      draw: chain,
    );
    filled = false;
    _row(
      canvas,
      from: plaque.right + h * 0.26,
      to: ends.last - endRadius * 1.9,
      y: h / 2,
      step: h * 0.32,
      draw: chain,
    );

    final shape = _cutCorners(plaque, plaque.height * 0.3);
    canvas
      ..drawPath(shape, ink.paper)
      ..drawPath(shape, ink.line)
      ..drawPath(
        _cutCorners(plaque.deflate(h * 0.07), plaque.height * 0.24),
        ink.thin,
      );
  }

  /// A fully rounded panel with a leaf on each side of the plaque, a dot
  /// line to the ends, and a plaque with scalloped ends.
  void _paintArch(Canvas canvas, Size size, Rect plaque, _Ink ink) {
    final h = size.height;
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(ink.line.strokeWidth / 2),
      Radius.circular(h / 2),
    );
    final inner = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(h * 0.12),
      Radius.circular(h * 0.38),
    );
    canvas
      ..drawRRect(outer, ink.band)
      ..drawRRect(outer, ink.line)
      ..drawRRect(inner, ink.thin);

    // Leaves beside the plaque, pointing away from it, and a small three
    // leaf sprig at each end of the panel.
    for (final side in [-1.0, 1.0]) {
      final root = Offset(
        side < 0 ? plaque.left - h * 0.1 : plaque.right + h * 0.1,
        h / 2,
      );
      _leaf(canvas, root, Offset(side * h * 0.55, 0), h * 0.16, ink.solid);
      final tip = Offset(
        side < 0 ? inner.left + h * 0.32 : inner.right - h * 0.32,
        h / 2,
      );
      for (final angle in [-0.7, 0.0, 0.7]) {
        final reach = Offset(math.cos(angle), math.sin(angle)) * h * 0.24;
        _leaf(
          canvas,
          tip,
          Offset(-side * reach.dx, reach.dy),
          h * 0.08,
          ink.solid,
        );
      }
    }
    final dot = h * 0.035;
    _row(
      canvas,
      from: inner.left + h * 0.62,
      to: plaque.left - h * 0.82,
      y: h / 2,
      step: h * 0.2,
      draw: (c) => canvas.drawCircle(c, dot, ink.solid),
    );
    _row(
      canvas,
      from: plaque.right + h * 0.82,
      to: inner.right - h * 0.62,
      y: h / 2,
      step: h * 0.2,
      draw: (c) => canvas.drawCircle(c, dot, ink.solid),
    );

    final shape = _scalloped(plaque);
    canvas
      ..drawPath(shape, ink.paper)
      ..drawPath(shape, ink.line)
      ..drawPath(_scalloped(plaque.deflate(h * 0.07)), ink.thin);
  }

  /// A fine rule above and below the line, and a rounded plaque with a
  /// short double rule and a bead on each side. No panel tint.
  void _paintMinimal(Canvas canvas, Size size, Rect plaque, _Ink ink) {
    final h = size.height;
    final w = size.width;
    final inset = h * 0.06;
    for (final y in [inset, h - inset]) {
      canvas.drawLine(Offset(h * 0.3, y), Offset(w - h * 0.3, y), ink.thin);
    }
    for (final x in [h * 0.3, w - h * 0.3]) {
      for (final y in [inset, h - inset]) {
        canvas.drawCircle(Offset(x, y), h * 0.04, ink.solid);
      }
    }
    for (final side in [-1.0, 1.0]) {
      final near = side < 0 ? plaque.left - h * 0.14 : plaque.right + h * 0.14;
      final far = near + side * math.min(w * 0.12, h * 1.4);
      for (final dy in [-h * 0.06, h * 0.06]) {
        canvas.drawLine(
          Offset(near, h / 2 + dy),
          Offset(far, h / 2 + dy),
          ink.thin,
        );
      }
      canvas.drawCircle(
        Offset(far + side * h * 0.08, h / 2),
        h * 0.05,
        ink.solid,
      );
    }
    final shape = RRect.fromRectAndRadius(
      plaque,
      Radius.circular(plaque.height / 2),
    );
    canvas
      ..drawRRect(shape, ink.paper)
      ..drawRRect(shape, ink.line);
  }

  /// Calls [draw] at even steps of about [step] from [from] to [to].
  void _row(
    Canvas canvas, {
    required double from,
    required double to,
    required double y,
    required double step,
    required void Function(Offset centre) draw,
  }) {
    final count = ((to - from) / step).floor();
    if (count < 1) return;
    final gap = (to - from) / count;
    for (var i = 0; i <= count; i++) {
      draw(Offset(from + gap * i, y));
    }
  }

  /// A long shape whose ends come to a point in curves, like a cartouche.
  static Path _pointed(Rect r) {
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

  /// A rectangle with its four corners cut by [cut].
  static Path _cutCorners(Rect r, double cut) => Path()
    ..moveTo(r.left + cut, r.top)
    ..lineTo(r.right - cut, r.top)
    ..lineTo(r.right, r.top + cut)
    ..lineTo(r.right, r.bottom - cut)
    ..lineTo(r.right - cut, r.bottom)
    ..lineTo(r.left + cut, r.bottom)
    ..lineTo(r.left, r.bottom - cut)
    ..lineTo(r.left, r.top + cut)
    ..close();

  /// A rectangle whose ends are three outward lobes, the middle one the
  /// largest.
  static Path _scalloped(Rect r) {
    final end = r.height * 0.5;
    final small = Radius.circular(r.height * 0.2);
    final large = Radius.circular(r.height * 0.32);
    final third = r.height / 3;
    final path = Path()
      ..moveTo(r.left + end, r.top)
      ..lineTo(r.right - end, r.top);
    final ends = [(x: r.right - end, sign: 1.0), (x: r.left + end, sign: -1.0)];
    for (final (index, side) in ends.indexed) {
      final down = index == 0;
      final ys = down
          ? [r.top, r.top + third, r.bottom - third, r.bottom]
          : [r.bottom, r.bottom - third, r.top + third, r.top];
      // Out to the lobes, then back to the plaque's edge.
      path.lineTo(side.x + side.sign * end * 0.2, ys[0]);
      for (var i = 0; i < 3; i++) {
        final reach = i == 1 ? end : end * 0.55;
        path.arcToPoint(
          Offset(
            side.x + side.sign * (i == 2 ? end * 0.2 : reach * 0.6),
            ys[i + 1],
          ),
          radius: i == 1 ? large : small,
          clockwise: true,
        );
      }
      path.lineTo(side.x, ys[3]);
      if (down) path.lineTo(r.left + end, r.bottom);
    }
    return path..close();
  }

  /// A rhombus around [c], [rx] wide and [ry] tall from its centre.
  static Path _lozenge(Offset c, double rx, double ry) => Path()
    ..moveTo(c.dx, c.dy - ry)
    ..lineTo(c.dx + rx, c.dy)
    ..lineTo(c.dx, c.dy + ry)
    ..lineTo(c.dx - rx, c.dy)
    ..close();

  /// A leaf from [root] reaching by [reach], [width] across at its widest.
  void _leaf(Canvas canvas, Offset root, Offset reach, double width, Paint p) {
    final tip = root + reach;
    final normal = Offset(-reach.dy, reach.dx) / reach.distance * width;
    final middle = root + reach * 0.45;
    canvas.drawPath(
      Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(
          (middle + normal).dx,
          (middle + normal).dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (middle - normal).dx,
          (middle - normal).dy,
          root.dx,
          root.dy,
        )
        ..close(),
      p,
    );
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
  void _rosette(Canvas canvas, Offset c, double r, _Ink ink) {
    canvas.drawCircle(c, r * 1.05, ink.paper);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.62,
        r * 0.32,
        ink.thin,
      );
    }
    canvas
      ..drawCircle(c, r * 0.28, ink.solid)
      ..drawCircle(c, r * 1.02, ink.thin);
  }

  @override
  bool shouldRepaint(SurahFramePainter old) =>
      old.style != style ||
      old.paper != paper ||
      old.band != band ||
      old.stroke != stroke ||
      old.nameWidth != nameWidth;
}

/// The paints of one frame.
typedef _Ink = ({Paint line, Paint thin, Paint solid, Paint paper, Paint band});

/// Where the parts of a surah frame of a given size lie, shared by the
/// painter and the widgets that write the name in it.
abstract final class SurahFrameGeometry {
  /// How far the plaque's ends reach past its straight middle, in plaque
  /// heights, per style: the name must sit between them.
  static double _ends(SurahFrameStyle style) => switch (style) {
    SurahFrameStyle.cartouche => 0.62,
    SurahFrameStyle.classic => 0.3,
    SurahFrameStyle.arch => 0.5,
    SurahFrameStyle.minimal => 0.5,
  };

  /// The plaque that holds the name, centred: about half the frame's width,
  /// never narrower than [nameWidth] with room on both sides, and narrower
  /// on a short frame so the ends keep their ornaments.
  static Rect plaque(Size size, SurahFrameStyle style, {double nameWidth = 0}) {
    final h = size.height;
    final tall = h * (style == SurahFrameStyle.minimal ? 0.62 : 0.82);
    final ends = _ends(style) * tall;
    final room = size.width - 2 * h * 1.13;
    final fits = nameWidth * 1.12 + 2 * ends;
    final width = math.min(
      size.width - h * 0.6,
      math.max(fits, math.max(h * 2.2, math.min(size.width * 0.5, room))),
    );
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: tall,
    );
  }

  /// Where a name written over the frame fits: the plaque's straight middle,
  /// a little inside its outline.
  static Rect name(Size size, SurahFrameStyle style) {
    final plaque = SurahFrameGeometry.plaque(size, style);
    final ends = _ends(style) * plaque.height;
    return Rect.fromLTRB(
      plaque.left + ends * 0.9,
      plaque.top + plaque.height * 0.05,
      plaque.right - ends * 0.9,
      plaque.bottom - plaque.height * 0.05,
    );
  }
}
