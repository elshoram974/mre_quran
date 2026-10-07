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

/// A page peeling off around a moving cylinder, as in a book reader: the free
/// edge lifts toward the reader, rolls over the cylinder, and lies back on the
/// sheet showing its reverse. The part beyond the cylinder is still flat.
///
/// The sheet is hinged on its left edge and its right edge is the free one.
/// [progress] runs from 0 (flat) to 1 (rolled off past the hinge). The
/// cylinder sits at the point of the sheet where it lifts, so a finger
/// holding the edge keeps it under the finger: at [progress] the roll is at
/// `size.width * (1 - progress)` from the left, going to the hinge.
CurlMesh buildPeelMesh({
  required double progress,
  required Size size,
  required double pixelRatio,
  bool mirror = false,
  int columns = 56,
}) {
  final t = progress.clamp(0.0, 1.0);
  final w = size.width;
  final h = size.height;
  final radius = w * 0.07;
  // Where the cylinder touches the sheet, from the hinge: it starts at the
  // free edge and ends at the hinge, with room for the roll itself.
  final line = (w + math.pi * radius) * (1 - t) - math.pi * radius * t;

  final xs = <double>[];
  final angles = <double>[];
  for (var i = 0; i <= columns; i++) {
    final s = w * i / columns; // distance from the hinge along the sheet
    final a = s - line;
    if (a <= 0) {
      xs.add(s);
      angles.add(0);
    } else if (a <= math.pi * radius) {
      final theta = a / radius;
      xs.add(line + radius * math.sin(theta));
      angles.add(theta);
    } else {
      xs.add(line - (a - math.pi * radius));
      angles.add(math.pi);
    }
  }

  int shade(double v) {
    final g = (v.clamp(0.0, 1.0) * 255).round();
    return 0xFF000000 | (g << 16) | (g << 8) | g;
  }

  // Light from above the reader: a sheet facing it is bright, the roll
  // darkens as it turns away and catches a soft highlight where it stands
  // up toward the light; the reverse is always a little dimmer.
  double sheen(double phi) => 0.16 * math.exp(-math.pow((phi - 1.0) / 0.38, 2));
  double frontShade(double phi) =>
      (0.74 + 0.26 * math.cos(phi) + sheen(phi)).clamp(0.0, 1.0);
  double backShade(double phi) =>
      (0.80 + 0.16 * math.cos(math.pi - phi) + sheen(math.pi - phi) * 0.6)
          .clamp(0.0, 1.0);

  final frontP = <double>[];
  final frontT = <double>[];
  final frontC = <int>[];
  final backP = <double>[];
  final backT = <double>[];
  final backC = <int>[];
  for (var i = 0; i < columns; i++) {
    final mid = (angles[i] + angles[i + 1]) / 2;
    final isFront = mid < math.pi / 2;
    final p = isFront ? frontP : backP;
    final tex = isFront ? frontT : backT;
    final c = isFront ? frontC : backC;
    final shadeOf = isFront ? frontShade : backShade;
    // Mirrored, the sheet is hinged on the right: a point s from the hinge
    // lies at w - s, and its texture is w - s too.
    final u0 = mirror ? w - w * i / columns : w * i / columns;
    final u1 = mirror ? w - w * (i + 1) / columns : w * (i + 1) / columns;
    final x0 = mirror ? w - xs[i] : xs[i];
    final x1 = mirror ? w - xs[i + 1] : xs[i + 1];
    final s0 = shadeOf(angles[i]);
    final s1 = shadeOf(angles[i + 1]);
    final corners = [
      (x0, 0.0, u0, 0.0, s0),
      (x1, 0.0, u1, 0.0, s1),
      (x1, h, u1, h, s1),
      (x0, h, u0, h, s0),
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

  CurlFace face(List<double> p, List<double> tex, List<int> c) => CurlFace(
    positions: Float32List.fromList(p),
    textureCoordinates: Float32List.fromList(tex),
    colors: Int32List.fromList(c),
  );
  return CurlMesh(
    front: face(frontP, frontT, frontC),
    back: face(backP, backT, backC),
    outline: [
      for (var i = 0; i <= columns; i++)
        (x: mirror ? w - xs[i] : xs[i], top: 0.0, bottom: h),
    ],
    lift: math.sin(math.pi * t),
  );
}
