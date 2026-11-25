import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'curl_mesh.dart';

/// Paints a turning leaf from snapshots of its two pages, with the shadows it
/// casts.
///
/// Mushaf geometry: the canvas is physical in every app language, with the
/// spine on the right edge of the leaf's own page (see [CurlFold]).
class PageCurlPainter extends CustomPainter {
  /// Creates a painter.
  PageCurlPainter({
    required this.progress,
    required this.front,
    required this.back,
    required this.pixelRatio,
    required this.paper,
    required this.shadow,
    this.fromRight = false,
    this.grip = 0,
  });

  /// 0 lying on the left, 1 turned over onto the right.
  final double progress;

  /// Snapshot of the leaf's front: its left-hand page.
  final ui.Image front;

  /// Snapshot of the leaf's back, its right-hand page, or null for blank
  /// paper.
  final ui.Image? back;

  /// Snapshot scale.
  final double pixelRatio;

  /// Colour of blank paper.
  final Color paper;

  /// Colour of the shadows, from the theme.
  final Color shadow;

  /// Whether the hand lifted the leaf off the right-hand side, turning back.
  final bool fromRight;

  /// Where along the free edge the hand holds the leaf: -1 top corner, 0
  /// middle, 1 bottom corner.
  final double grip;

  /// The fold this painter draws, for its size.
  CurlFold foldFor(Size size) => CurlFold(
    progress: progress,
    size: size,
    fromRight: fromRight,
    grip: grip,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final mesh = buildCurlMesh(fold: foldFor(size), pixelRatio: pixelRatio);
    final lift = mesh.lift;
    final w = size.width;
    final h = size.height;

    // The roll's shadow on the page it uncovers, beyond the fold on the free
    // side, cut to that page.
    final edge = mesh.silhouette;
    if (edge != null && lift > 0.01) {
      final reach = mesh.outward * (w * 0.08 * lift + 6);
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(fromRight ? w : 0, 0, w, h))
        ..drawPath(
          Path()
            ..moveTo(edge.start.dx, edge.start.dy)
            ..lineTo(edge.end.dx, edge.end.dy)
            ..lineTo(edge.end.dx + reach.dx, edge.end.dy + reach.dy)
            ..lineTo(edge.start.dx + reach.dx, edge.start.dy + reach.dy)
            ..close(),
          Paint()
            ..shader = ui.Gradient.linear(edge.start, edge.start + reach, [
              shadow.withValues(alpha: 0.32 * lift),
              shadow.withValues(alpha: 0),
            ]),
        )
        ..restore();
    }

    final (lower, lowerImage, upper, upperImage) = mesh.frontOnTop
        ? (mesh.back, back, mesh.front, front)
        : (mesh.front, front, mesh.back, back);
    _drawFace(canvas, lower, lowerImage);

    // The flap's shadow on the leaf under it and the facing page, falling
    // past the flap's free edge, toward the spine.
    if (!upper.isEmpty && lift > 0.01) {
      final flap = Path();
      final p = upper.positions;
      for (var i = 0; i + 5 < p.length; i += 6) {
        flap
          ..moveTo(p[i], p[i + 1])
          ..lineTo(p[i + 2], p[i + 3])
          ..lineTo(p[i + 4], p[i + 5])
          ..close();
      }
      final offset = -mesh.outward * (2 + 6 * lift) + Offset(0, 3 * lift);
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(0, 0, 2 * w, h))
        ..translate(offset.dx, offset.dy)
        ..drawPath(
          flap,
          Paint()
            ..color = shadow.withValues(alpha: 0.3 * lift)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + 7 * lift),
        )
        ..restore();
    }
    _drawFace(canvas, upper, upperImage);
  }

  void _drawFace(Canvas canvas, CurlFace face, ui.Image? image) {
    if (face.isEmpty) return;
    if (image == null) {
      _drawBlank(canvas, face);
      return;
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      face.positions,
      textureCoordinates: face.textureCoordinates,
      colors: face.colors,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
    vertices.dispose();
  }

  void _drawBlank(Canvas canvas, CurlFace face) {
    // Blank paper: the paper colour shaded by each vertex's light.
    final colors = Int32List(face.colors.length);
    for (var i = 0; i < colors.length; i++) {
      final shade = (face.colors[i] & 0xFF) / 255;
      colors[i] = Color.fromARGB(
        255,
        (paper.r * 255 * shade).round(),
        (paper.g * 255 * shade).round(),
        (paper.b * 255 * shade).round(),
      ).toARGB32();
    }
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      face.positions,
      colors: colors,
    );
    canvas.drawVertices(vertices, BlendMode.src, Paint());
    vertices.dispose();
  }

  @override
  bool shouldRepaint(PageCurlPainter old) =>
      old.progress != progress ||
      old.front != front ||
      old.back != back ||
      old.pixelRatio != pixelRatio ||
      old.paper != paper ||
      old.shadow != shadow ||
      old.fromRight != fromRight ||
      old.grip != grip;
}
