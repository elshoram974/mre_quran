import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

/// Triangles for one face of a bent sheet, ready for `Canvas.drawVertices`.
class CurlFace {
  /// Creates a face from flat vertex lists.
  const CurlFace({
    required this.positions,
    required this.textureCoordinates,
    required this.colors,
  });

  /// x, y pairs in the sheet's local space.
  final Float32List positions;

  /// x, y pairs in texture pixels.
  final Float32List textureCoordinates;

  /// One ARGB shade per vertex, to modulate the texture.
  final Int32List colors;

  /// Whether the face has no triangles.
  bool get isEmpty => positions.isEmpty;
}

/// A sheet of paper bent between a hinge and a free edge.
class CurlMesh {
  /// Creates a mesh.
  const CurlMesh({
    required this.front,
    required this.back,
    required this.outline,
    required this.lift,
  });

  /// Triangles showing the front of the sheet.
  final CurlFace front;

  /// Triangles showing the back of the sheet.
  final CurlFace back;

  /// Points along the sheet's lower surface projected flat, for its shadow:
  /// x, then top y, then bottom y, for each column.
  final List<({double x, double top, double bottom})> outline;

  /// 0 when the sheet lies flat, 1 when it stands up. Drives the shadow.
  final double lift;
}

/// Builds the mesh of a sheet of [size] hinged on its right edge, turned by
/// [progress] from 0 (flat on its page) to 1 (turned over).
///
/// The sheet bends as it turns: the part near the hinge follows behind and the
/// free edge leads, so the paper curves instead of staying flat. At 0 and 1 it
/// is flat. [vanishX] is the horizontal position of the viewer's eye, in the
/// sheet's local space. [pixelRatio] converts local units to texture pixels.
///
/// [lead] is the direction of the turn: 1 while the sheet is being turned
/// forward, -1 while it is being turned back. A hand pulling the free edge
/// leads with it, so going forward the free edge runs ahead of the hinge and
/// going back it runs ahead the other way: the bend is mirrored. Values in
/// between blend the two, so a change of mind mid-turn does not jump.
CurlMesh buildCurlMesh({
  required double progress,
  required Size size,
  required double vanishX,
  required double pixelRatio,
  double lead = 1,
  int columns = 30,
}) {
  final t = progress.clamp(0.0, 1.0);
  final w = size.width;
  final h = size.height;
  final bend = math.sin(math.pi * t);
  // Far camera: the lifted part grows only a few percent, so the sheet
  // stays within the page's height instead of spilling over its top and
  // bottom (and its labels).
  final camera = w * 14;
  final step = w / columns;

  // Going forward the sheet lifts off its own page: the bend grows with the
  // turn, and the free edge runs ahead. Going back the sheet lifts off the
  // page it landed on, the exact mirror of that: seen from the far side the
  // same lift, so the bend grows with the turn *left to go*, and again the
  // free edge runs ahead. Mixing the two weights keeps a change of direction
  // smooth.
  final backWeight = ((1 - lead) / 2).clamp(0.0, 1.0);
  double angleAt(double s) {
    final base = math.pi * t;
    final bow = 0.5 * bend * (2 * math.pow(s, 1.6) - 1);
    final forward = base * (1 + bow);
    final back = math.pi - (math.pi - base) * (1 + bow);
    final angle = forward + (back - forward) * backWeight;
    return math.max(0.0, math.min(math.pi, angle));
  }

  final xs = <double>[w];
  final zs = <double>[0];
  final angles = <double>[0];
  for (var i = 1; i <= columns; i++) {
    final phi = angleAt((i - 0.5) / columns);
    xs.add(xs.last - step * math.cos(phi));
    zs.add(zs.last + step * math.sin(phi));
    angles.add(phi);
  }

  final screenX = <double>[];
  final screenTop = <double>[];
  final screenBottom = <double>[];
  for (var i = 0; i <= columns; i++) {
    final scale = camera / (camera - zs[i]);
    screenX.add(vanishX + (xs[i] - vanishX) * scale);
    screenTop.add(h / 2 + (0 - h / 2) * scale);
    screenBottom.add(h / 2 + (h - h / 2) * scale);
  }

  int shade(double v) {
    final g = (v.clamp(0.0, 1.0) * 255).round();
    return 0xFF000000 | (g << 16) | (g << 8) | g;
  }

  double frontShade(double phi) => 0.58 + 0.42 * math.cos(phi);
  double backShade(double phi) => 0.8 + 0.2 * math.cos(phi - math.pi);

  final frontP = <double>[];
  final frontT = <double>[];
  final frontC = <int>[];
  final backP = <double>[];
  final backT = <double>[];
  final backC = <int>[];

  void quad(
    int i,
    List<double> p,
    List<double> tex,
    List<int> c, {
    required bool isFront,
  }) {
    // Column i is nearer the hinge than column i + 1.
    final u0 = i * step;
    final u1 = (i + 1) * step;
    final x0 = isFront ? (w - u0) : u0;
    final x1 = isFront ? (w - u1) : u1;
    final s0 = isFront ? frontShade(angles[i]) : backShade(angles[i]);
    final s1 = isFront ? frontShade(angles[i + 1]) : backShade(angles[i + 1]);
    final corners = [
      (screenX[i], screenTop[i], x0, 0.0, s0),
      (screenX[i + 1], screenTop[i + 1], x1, 0.0, s1),
      (screenX[i + 1], screenBottom[i + 1], x1, h, s1),
      (screenX[i], screenBottom[i], x0, h, s0),
    ];
    for (final index in [0, 1, 2, 0, 2, 3]) {
      final corner = corners[index];
      p
        ..add(corner.$1)
        ..add(corner.$2);
      tex
        ..add(corner.$3 * pixelRatio)
        ..add(corner.$4 * pixelRatio);
      c.add(shade(corner.$5));
    }
  }

  for (var i = 0; i < columns; i++) {
    final mid = (angles[i] + angles[i + 1]) / 2;
    if (mid < math.pi / 2) {
      quad(i, frontP, frontT, frontC, isFront: true);
    } else {
      quad(i, backP, backT, backC, isFront: false);
    }
  }

  CurlFace face(List<double> p, List<double> tex, List<int> c) => CurlFace(
    positions: Float32List.fromList(p),
    textureCoordinates: Float32List.fromList(tex),
    colors: Int32List.fromList(c),
  );

  return CurlMesh(
    front: face(frontP, frontT, frontC),
    back: face(backP, backT, backC),
    outline: [
      for (var i = 0; i <= columns; i++) (x: xs[i], top: 0.0, bottom: h),
    ],
    lift: bend,
  );
}

/// Where the free edge of a sheet of [width] hinged on its right edge lies,
/// measured from the sheet's own left edge when flat: [width] at the hinge,
/// 0 while the sheet lies on its page, up to twice [width] once it has landed
/// on the far side.
double curlFreeEdgeX({
  required double progress,
  required double width,
  required double height,
  double lead = 1,
}) => buildCurlMesh(
  progress: progress,
  size: Size(width, height),
  vanishX: width,
  pixelRatio: 1,
  lead: lead,
  columns: 12,
).outline.last.x;
