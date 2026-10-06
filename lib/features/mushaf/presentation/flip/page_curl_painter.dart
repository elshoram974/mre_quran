import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'curl_mesh.dart';

/// Paints a bent sheet from two page snapshots, with the shadow it casts.
class PageCurlPainter extends CustomPainter {
  /// Creates a painter.
  PageCurlPainter({
    required this.progress,
    required this.front,
    required this.back,
    required this.vanishX,
    required this.pixelRatio,
    required this.paper,
  });

  /// 0 flat on its page, 1 turned over.
  final double progress;

  /// Snapshot of the page on the front of the sheet.
  final ui.Image front;

  /// Snapshot of the page on the back of the sheet, or null for blank paper.
  final ui.Image? back;

  /// Eye position, in the sheet's local space.
  final double vanishX;

  /// Snapshot scale.
  final double pixelRatio;

  /// Colour of blank paper.
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final mesh = buildCurlMesh(
      progress: progress,
      size: size,
      vanishX: vanishX,
      pixelRatio: pixelRatio,
    );

    // The shadow on the page below: the sheet's footprint, blurred.
    final shadow = Path()..moveTo(size.width, 0);
    for (final point in mesh.outline) {
      shadow.lineTo(point.x, point.top);
    }
    for (final point in mesh.outline.reversed) {
      shadow.lineTo(point.x, point.bottom);
    }
    shadow.close();
    canvas.drawPath(
      shadow.shift(Offset(-4 * mesh.lift, 6 * mesh.lift)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.3 * mesh.lift)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 12 * mesh.lift),
    );

    _drawFace(canvas, mesh.front, front);
    if (!mesh.back.isEmpty) {
      final image = back;
      if (image != null) {
        _drawFace(canvas, mesh.back, image);
      } else {
        _drawBlank(canvas, mesh.back);
      }
    }
  }

  void _drawFace(Canvas canvas, CurlFace face, ui.Image image) {
    if (face.isEmpty) return;
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
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      face.positions,
      colors: face.colors,
    );
    canvas.drawVertices(vertices, BlendMode.modulate, Paint()..color = paper);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(PageCurlPainter old) =>
      old.progress != progress ||
      old.front != front ||
      old.back != back ||
      old.vanishX != vanishX ||
      old.pixelRatio != pixelRatio ||
      old.paper != paper;
}
