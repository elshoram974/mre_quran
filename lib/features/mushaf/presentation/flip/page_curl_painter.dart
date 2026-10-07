import 'dart:typed_data';
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
    this.lead = 1,
    this.peel = false,
    this.mirror = false,
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

  /// 1 turning forward, -1 turning back: the bend of the sheet mirrors.
  final double lead;

  /// Whether the sheet peels off its own page around a cylinder (going back,
  /// hinged on the left) instead of swinging over the spine. Its reverse then
  /// shows its own print faintly through the paper.
  final bool peel;

  /// Whether a peel is hinged on the right (going forward) instead of the
  /// left (going back).
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final mesh = peel
        ? buildPeelMesh(
            progress: progress,
            size: size,
            pixelRatio: pixelRatio,
            mirror: mirror,
          )
        : buildCurlMesh(
            progress: progress,
            size: size,
            vanishX: vanishX,
            pixelRatio: pixelRatio,
            lead: lead,
          );

    // Where the peeling sheet reaches on each side: its rolled edge, over
    // the page it uncovers, and the free end of its reverse, lying on itself.
    var rolledEdge = 0.0;
    var freeEnd = 0.0;
    if (peel) {
      var low = size.width;
      var high = 0.0;
      for (final point in mesh.outline) {
        if (point.x < low) low = point.x;
        if (point.x > high) high = point.x;
      }
      rolledEdge = mirror ? low : high;
      freeEnd = mirror ? high : low;
    }

    if (peel) {
      // The roll shades the page it uncovers: dark at the edge, fading out.
      _edgeShadow(
        canvas,
        size,
        edge: rolledEdge,
        toward: mirror ? -1 : 1,
        reach: size.width * 0.16,
        strength: 0.34 * mesh.lift.clamp(0.25, 1.0),
      );
    } else {
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
    }

    _drawFace(canvas, mesh.front, front);
    if (peel && !mesh.back.isEmpty) {
      // The reverse lying on the sheet casts a shadow on it.
      _edgeShadow(
        canvas,
        size,
        edge: freeEnd,
        toward: mirror ? 1 : -1,
        reach: size.width * 0.05,
        strength: 0.22,
      );
    }
    if (!mesh.back.isEmpty) {
      final image = back;
      if (peel) {
        // Paper shows its print through, faintly.
        _drawBlank(canvas, mesh.back);
        canvas.saveLayer(
          null,
          Paint()..color = const Color(0xFF000000).withValues(alpha: 0.13),
        );
        _drawFace(canvas, mesh.back, front);
        canvas.restore();
      } else if (image != null) {
        _drawFace(canvas, mesh.back, image);
      } else {
        _drawBlank(canvas, mesh.back);
      }
    }
  }

  /// A strip of shadow beside [edge], fading out over [reach] toward
  /// [toward] (1 right, -1 left).
  void _edgeShadow(
    Canvas canvas,
    Size size, {
    required double edge,
    required int toward,
    required double reach,
    required double strength,
  }) {
    final far = edge + toward * reach;
    final rect = Rect.fromLTRB(
      toward > 0 ? edge : far,
      0,
      toward > 0 ? far : edge,
      size.height,
    );
    final dark = const Color(0xFF000000).withValues(alpha: strength);
    final clear = const Color(0x00000000);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(Offset(edge, 0), Offset(far, 0), [
          dark,
          clear,
        ]),
    );
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
      old.vanishX != vanishX ||
      old.pixelRatio != pixelRatio ||
      old.paper != paper ||
      old.lead != lead ||
      old.peel != peel ||
      old.mirror != mirror;
}
