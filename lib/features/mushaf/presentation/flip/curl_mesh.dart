import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Triangles for one face of a turning leaf, ready for `Canvas.drawVertices`.
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

/// A point of a turning leaf: where it lies in the sheet's local space, how
/// high above the book it is, and how far the paper there has turned over,
/// from 0 (lying as the hand found it) to pi (lying upside down).
typedef CurlPoint = ({double x, double y, double z, double angle});

/// How a leaf of the book lies part of the way through a turn.
///
/// Mushaf geometry, the same in every app language because the book opens
/// right to left: the sheet's local space is physical, with the spine at
/// x = width. The leaf lies over 0..width (the left-hand page) before it turns
/// onward and over width..2 width (the right-hand page) once it has turned.
/// Only `PageCurlPainter` draws with it; ordinary layout never uses it.
///
/// A point of the leaf is named in the coordinates of its front, the
/// left-hand page: x from that page's left edge, which is the leaf's free
/// edge, y from its top.
///
/// A hand lifts the leaf by its free edge, the edge away from the spine: the
/// left edge to turn onward, the right edge to turn back. Paper folds, it does
/// not stretch. On the spine's side of a fold line the leaf stays flat where
/// it lay. Past the fold it rolls up over a cylinder and lies back over itself
/// upside down, its other page showing, so every length along the paper is
/// kept. The fold starts at the free edge and travels to the spine, where the
/// whole leaf has turned over and lies flat on the other side. The spine is
/// bound, so the fold never crosses it. A hand that holds the edge near a
/// corner lifts that corner first: the fold leans, and straightens as the leaf
/// lands.
@immutable
class CurlFold {
  const CurlFold._({
    required this.width,
    required this.height,
    required this.fromRight,
    required this.lift,
    required this.radius,
    required this.foldX,
    required this.pivotY,
    required this.normalX,
    required this.normalY,
  });

  /// The fold of a leaf of [size], [progress] of the way from lying on the
  /// left (0) to lying on the right (1).
  ///
  /// [fromRight] is true when the hand lifted the leaf off the right-hand
  /// side, turning it back; then the fold starts at the right edge.
  /// [grip] is where along its free edge the hand holds the leaf: -1 at the
  /// top corner, 0 in the middle, 1 at the bottom corner.
  factory CurlFold({
    required double progress,
    required Size size,
    bool fromRight = false,
    double grip = 0,
  }) {
    final w = size.width;
    final h = size.height;
    final turned = progress.clamp(0.0, 1.0);
    // How far the hand has taken the leaf from where it picked it up.
    final pulled = fromRight ? 1 - turned : turned;
    // Exactly flat at rest, where sin(pi) would leave a trace.
    final lift = pulled <= 0 || pulled >= 1 ? 0.0 : math.sin(math.pi * pulled);
    final radius = rollShare * w * lift;
    // The free edge travels twice as far as the fold: when the fold reaches
    // the spine the whole leaf lies on the other side.
    final foldX = w * pulled + math.pi / 2 * radius;
    final hold = grip.clamp(-1.0, 1.0);
    // The fold leans about the corner nearer the hand, so that corner lifts
    // first and the fold is furthest along there; it never gets nearer the
    // bound spine than foldX. The lean is the hand's and fades as the leaf
    // lands.
    final pivotY = hold >= 0 ? h : 0.0;
    var tilt = maxTilt * hold * (1 - pulled);
    // A leaning flap rises past the top or bottom of the page; keep that
    // within a few percent of its height.
    if (foldX > 0) {
      final limit = math.asin(math.min(1.0, maxOverhang * h / (2 * foldX)));
      tilt = tilt.clamp(-limit, limit);
    }
    return CurlFold._(
      width: w,
      height: h,
      fromRight: fromRight,
      lift: lift,
      radius: radius,
      foldX: foldX,
      pivotY: pivotY,
      normalX: -math.cos(tilt),
      normalY: math.sin(tilt),
    );
  }

  /// Radius of the roll at mid-turn, as a share of the leaf's width.
  static const double rollShare = 0.12;

  /// The most the fold leans when the hand holds a corner, in radians.
  static const double maxTilt = 0.15;

  /// How far past its top or bottom a leaning flap may rise, as a share of
  /// the page's height.
  static const double maxOverhang = 0.04;

  /// Size of the leaf.
  final double width;

  /// Height of the leaf.
  final double height;

  /// Whether the leaf was lifted off the right-hand side, turning back.
  final bool fromRight;

  /// 0 while the leaf lies flat, 1 at mid-turn, when it is highest.
  final double lift;

  /// Radius of the roll at the fold; 0 when the leaf lies flat.
  final double radius;

  /// Where the fold crosses the top or bottom edge nearer the hand, in the
  /// leaf's own coordinates: how far along the paper from its free edge.
  /// The fold is furthest along there.
  final double foldX;

  /// The edge nearer the hand: 0 for the top, height for the bottom.
  final double pivotY;

  /// The fold's unit normal in the leaf's own coordinates, pointing from the
  /// fold to the free edge.
  final double normalX;

  /// See [normalX].
  final double normalY;

  /// Half the length of paper in the roll: where it stands upright.
  double get _upright => math.pi * radius / 2;

  /// How far a point of the leaf is past the fold, toward the free edge:
  /// that much paper is lifted. At or below 0 the paper there lies flat.
  double depth(double x, double y) =>
      (x - foldX) * normalX + (y - pivotY) * normalY;

  /// Where the point ([x], [y]) of the leaf lies now.
  CurlPoint place(double x, double y) {
    final d = depth(x, y);
    double back;
    double z;
    double angle;
    if (d <= 0) {
      back = 0;
      z = 0;
      angle = 0;
    } else if (d < math.pi * radius) {
      // On the roll: bent around the cylinder.
      angle = d / radius;
      back = d - radius * math.sin(angle);
      z = radius * (1 - math.cos(angle));
    } else {
      // Past the roll: upside down, laid back over the leaf.
      angle = math.pi;
      back = 2 * d - math.pi * radius;
      z = 2 * radius;
    }
    final sx = x - back * normalX;
    final sy = y - back * normalY;
    // Turning back is the mirror image of turning onward about the spine:
    // the leaf lay over width..2 width, its free edge on the right.
    return (x: fromRight ? 2 * width - sx : sx, y: sy, z: z, angle: angle);
  }

  /// Whether the front of the leaf (the left-hand page) faces the reader at
  /// ([x], [y]); otherwise its back (the right-hand page) does.
  bool showsFront(double x, double y) =>
      (place(x, y).angle < math.pi / 2) != fromRight;
}

/// A turning leaf as triangles, with what its shadows need.
class CurlMesh {
  /// Creates a mesh.
  const CurlMesh({
    required this.front,
    required this.back,
    required this.frontOnTop,
    required this.silhouette,
    required this.outward,
    required this.lift,
  });

  /// Triangles showing the front of the leaf (the left-hand page).
  final CurlFace front;

  /// Triangles showing the back of the leaf (the right-hand page).
  final CurlFace back;

  /// Whether the front lies over the back: the part folded over is on top,
  /// and turning back that is the front.
  final bool frontOnTop;

  /// The edge of the roll seen from above, from one side of the page to the
  /// other, where its shadow falls on the page it uncovers. Null while the
  /// leaf lies flat.
  final ({Offset start, Offset end})? silhouette;

  /// Unit direction from the roll toward the page it uncovers.
  final Offset outward;

  /// 0 when the leaf lies flat, 1 at mid-turn. Drives the shadows.
  final double lift;
}

/// Builds the triangles of [fold]'s leaf. [pixelRatio] converts local units
/// to texture pixels. [rolls] is the number of strips the roll is cut into;
/// it is even so that one cut lies where the paper stands upright, between
/// the face lying as it was and the face turned over.
///
/// The leaf is cut into strips parallel to the fold, so the flat parts are
/// one strip each and drawn exactly; only the roll is approximated.
CurlMesh buildCurlMesh({
  required CurlFold fold,
  required double pixelRatio,
  int rolls = 12,
}) {
  assert(rolls >= 2 && rolls.isEven, 'rolls must be even');
  final w = fold.width;
  final h = fold.height;
  final r = fold.radius;

  // The corners, in order around the page.
  final cornerX = Float64List.fromList([0, w, w, 0]);
  final cornerY = Float64List.fromList([0, 0, h, h]);
  final cornerD = Float64List(4);
  var lowest = double.infinity;
  var highest = double.negativeInfinity;
  for (var i = 0; i < 4; i++) {
    final d = fold.depth(cornerX[i], cornerY[i]);
    cornerD[i] = d;
    lowest = math.min(lowest, d);
    highest = math.max(highest, d);
  }

  // Where the strips are cut: at the fold, through the roll, and past it.
  final cuts = <double>[lowest];
  void cut(double d) {
    if (d > lowest && d < highest) cuts.add(d);
  }

  cut(0);
  if (r > 0) {
    for (var k = 1; k <= rolls; k++) {
      cut(math.pi * r * k / rolls);
    }
  }
  cuts.add(highest);

  // At most two flat strips and [rolls] strips of roll; a strip is at most a
  // hexagon, four triangles.
  final capacity = (cuts.length - 1) * 12;
  final frontP = Float32List(capacity * 2);
  final frontT = Float32List(capacity * 2);
  final frontC = Int32List(capacity);
  final backP = Float32List(capacity * 2);
  final backT = Float32List(capacity * 2);
  final backC = Int32List(capacity);
  var frontN = 0;
  var backN = 0;

  // One strip at a time: its outline walked around the page's edge, in the
  // leaf's own coordinates, then where each of those points lies now and
  // how it is lit.
  final paperX = Float64List(8);
  final paperY = Float64List(8);
  final placedX = Float64List(8);
  final placedY = Float64List(8);
  final light = Int32List(8);

  for (var s = 0; s + 1 < cuts.length; s++) {
    final lo = cuts[s];
    final hi = cuts[s + 1];
    if (hi - lo < 1e-9) continue;
    var n = 0;
    for (var i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      final dA = cornerD[i];
      final dB = cornerD[j];
      if (dA >= lo && dA <= hi) {
        paperX[n] = cornerX[i];
        paperY[n] = cornerY[i];
        n++;
      }
      // Where the edge crosses the strip's sides, in order along the edge.
      for (var k = 0; k < 2; k++) {
        final bound = (k == 0) == (dA < dB) ? lo : hi;
        if ((dA - bound) * (dB - bound) < 0) {
          final t = (bound - dA) / (dB - dA);
          paperX[n] = cornerX[i] + (cornerX[j] - cornerX[i]) * t;
          paperY[n] = cornerY[i] + (cornerY[j] - cornerY[i]) * t;
          n++;
        }
      }
    }
    if (n < 3) continue;
    final mid = (lo + hi) / 2;
    final turned = mid > 0 && (r <= 0 || mid >= math.pi * r / 2);
    for (var i = 0; i < n; i++) {
      final at = fold.place(paperX[i], paperY[i]);
      placedX[i] = at.x;
      placedY[i] = at.y;
      // Light from above: paper facing the reader is fully lit and darkens
      // as it turns away on the roll, either face.
      final shade = 0.55 + 0.45 * (turned ? -1 : 1) * math.cos(at.angle);
      final g = (shade.clamp(0.0, 1.0) * 255).round();
      light[i] = 0xFF000000 | (g << 16) | (g << 8) | g;
    }
    // The face lying as the hand found it is the front going onward and the
    // back going back; the face turned over is the other one.
    final usesFront = turned == fold.fromRight;
    final positions = usesFront ? frontP : backP;
    final texture = usesFront ? frontT : backT;
    final colors = usesFront ? frontC : backC;
    var count = usesFront ? frontN : backN;
    for (var t = 1; t + 1 < n; t++) {
      for (var k = 0; k < 3; k++) {
        final i = k == 0 ? 0 : t + k - 1;
        positions[count * 2] = placedX[i];
        positions[count * 2 + 1] = placedY[i];
        // The front is the left-hand page; the back is the right-hand
        // page, whose left edge is at the spine.
        texture[count * 2] =
            (usesFront ? paperX[i] : w - paperX[i]) * pixelRatio;
        texture[count * 2 + 1] = paperY[i] * pixelRatio;
        colors[count] = light[i];
        count++;
      }
    }
    if (usesFront) {
      frontN = count;
    } else {
      backN = count;
    }
  }

  // The roll's silhouette: the line where the paper stands upright.
  ({Offset start, Offset end})? silhouette;
  if (r > 0) {
    final upright = fold._upright;
    final ends = <Offset>[];
    for (var i = 0; i < 4 && ends.length < 2; i++) {
      final j = (i + 1) % 4;
      final dA = cornerD[i] - upright;
      final dB = cornerD[j] - upright;
      if (dA == 0) {
        ends.add(Offset(cornerX[i], cornerY[i]));
      } else if (dA * dB < 0) {
        final t = dA / (dA - dB);
        ends.add(
          Offset(
            cornerX[i] + (cornerX[j] - cornerX[i]) * t,
            cornerY[i] + (cornerY[j] - cornerY[i]) * t,
          ),
        );
      }
    }
    if (ends.length == 2) {
      final a = fold.place(ends[0].dx, ends[0].dy);
      final b = fold.place(ends[1].dx, ends[1].dy);
      silhouette = (start: Offset(a.x, a.y), end: Offset(b.x, b.y));
    }
  }

  CurlFace face(Float32List p, Float32List t, Int32List c, int count) =>
      CurlFace(
        positions: Float32List.sublistView(p, 0, count * 2),
        textureCoordinates: Float32List.sublistView(t, 0, count * 2),
        colors: Int32List.sublistView(c, 0, count),
      );

  return CurlMesh(
    front: face(frontP, frontT, frontC, frontN),
    back: face(backP, backT, backC, backN),
    frontOnTop: fold.fromRight,
    silhouette: silhouette,
    outward: Offset(
      fold.fromRight ? -fold.normalX : fold.normalX,
      fold.normalY,
    ),
    lift: fold.lift,
  );
}
