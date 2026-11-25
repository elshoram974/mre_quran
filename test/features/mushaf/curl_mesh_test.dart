import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/curl_mesh.dart';

const _size = Size(300, 600);
const _w = 300.0;
const _h = 600.0;

CurlFold _fold(double progress, {bool fromRight = false, double grip = 0}) =>
    CurlFold(progress: progress, size: _size, fromRight: fromRight, grip: grip);

/// Points spread over the whole leaf.
Iterable<Offset> _grid() sync* {
  for (var x = 0.0; x <= _w; x += 30) {
    for (var y = 0.0; y <= _h; y += 60) {
      yield Offset(x, y);
    }
  }
}

/// Length of the paper between [a] and [b], measured along the bent leaf.
double _bentLength(CurlFold fold, Offset a, Offset b, {int samples = 600}) {
  var length = 0.0;
  var last = fold.place(a.dx, a.dy);
  for (var i = 1; i <= samples; i++) {
    final p = Offset.lerp(a, b, i / samples)!;
    final now = fold.place(p.dx, p.dy);
    final dx = now.x - last.x;
    final dy = now.y - last.y;
    final dz = now.z - last.z;
    length += math.sqrt(dx * dx + dy * dy + dz * dz);
    last = now;
  }
  return length;
}

void main() {
  const progresses = [0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95];
  const grips = [-1.0, -0.4, 0.0, 0.6, 1.0];

  test('the leaf lies flat at both ends of a turn, however it was lifted', () {
    for (final fromRight in [false, true]) {
      for (final grip in grips) {
        final before = _fold(0, fromRight: fromRight, grip: grip);
        final after = _fold(1, fromRight: fromRight, grip: grip);
        for (final p in _grid()) {
          final left = before.place(p.dx, p.dy);
          expect(left.x, closeTo(p.dx, 1e-6));
          expect(left.y, closeTo(p.dy, 1e-6));
          expect(left.z, 0);
          // On the spine itself both faces meet.
          if (p.dx < _w) expect(before.showsFront(p.dx, p.dy), isTrue);
          // Turned over about the spine at x = width: mirrored, back up.
          final right = after.place(p.dx, p.dy);
          expect(right.x, closeTo(2 * _w - p.dx, 1e-6));
          expect(right.y, closeTo(p.dy, 1e-6));
          expect(right.z, closeTo(0, 1e-9));
          if (p.dx < _w) expect(after.showsFront(p.dx, p.dy), isFalse);
        }
      }
    }
  });

  test('turning onward, the left edge folds back over the page toward the '
      'spine and shows the next page', () {
    final fold = _fold(0.4);
    // Held in the middle of the edge the fold runs straight down the page,
    // between the free edge and the spine.
    expect(fold.normalY, 0);
    expect(fold.foldX, inInclusiveRange(0.1 * _w, 0.9 * _w));
    for (final y in [0.0, _h / 2, _h]) {
      // Between the fold and the spine the page has not moved.
      final flat = fold.place(fold.foldX + 10, y);
      expect(flat.x, closeTo(fold.foldX + 10, 1e-9));
      expect(flat.z, 0);
      expect(fold.showsFront(_w - 1, y), isTrue);
      // The free edge is lifted over the fold and lies on the spine's side
      // of it, upside down: the back of the leaf faces the reader.
      final edge = fold.place(0, y);
      expect(edge.x, greaterThan(fold.foldX));
      expect(edge.x, lessThan(_w));
      expect(edge.z, greaterThan(0));
      expect(fold.showsFront(0, y), isFalse);
    }
  });

  test('turning back is the mirror image about the spine, lifting the right '
      'edge', () {
    for (final f in progresses) {
      for (final grip in grips) {
        final back = _fold(f, fromRight: true, grip: grip);
        final onward = _fold(1 - f, grip: grip);
        for (final p in _grid()) {
          final b = back.place(p.dx, p.dy);
          final o = onward.place(p.dx, p.dy);
          expect(b.x, closeTo(2 * _w - o.x, 1e-6), reason: 'f=$f $p');
          expect(b.y, closeTo(o.y, 1e-6));
          expect(b.z, closeTo(o.z, 1e-6));
          expect(back.showsFront(p.dx, p.dy), !onward.showsFront(p.dx, p.dy));
        }
      }
    }
    // Lifted off the right, the leaf's free edge is its right edge: it is
    // that edge that rises and comes over toward the spine.
    final back = _fold(0.6, fromRight: true);
    final edge = back.place(0, _h / 2);
    expect(edge.x, greaterThan(_w));
    expect(edge.x, lessThan(2 * _w - 10));
    expect(edge.z, greaterThan(0));
    expect(back.showsFront(0, _h / 2), isTrue, reason: 'the page before');
    expect(back.place(_w - 1, _h / 2).x, closeTo(_w + 1, 1e-9));
  });

  test('the paper never stretches or tears', () {
    for (final fromRight in [false, true]) {
      for (final f in progresses) {
        for (final grip in grips) {
          final fold = _fold(f, fromRight: fromRight, grip: grip);
          for (final (a, b) in [
            (const Offset(0, _h / 2), const Offset(_w, _h / 2)),
            (Offset.zero, const Offset(_w, _h)),
            (const Offset(0, _h), const Offset(_w, 0)),
            (Offset.zero, const Offset(0, _h)),
          ]) {
            final paper = (b - a).distance;
            expect(
              _bentLength(fold, a, b),
              closeTo(paper, paper * 0.002),
              reason: 'fromRight=$fromRight f=$f grip=$grip $a-$b',
            );
          }
        }
      }
    }
  });

  test('the bound spine never moves', () {
    for (final fromRight in [false, true]) {
      for (final f in progresses) {
        for (final grip in grips) {
          final fold = _fold(f, fromRight: fromRight, grip: grip);
          for (var y = 0.0; y <= _h; y += 30) {
            final spine = fold.place(_w, y);
            expect(spine.x, closeTo(_w, 1e-9));
            expect(spine.y, closeTo(y, 1e-9));
            expect(spine.z, 0, reason: 'fromRight=$fromRight f=$f grip=$grip');
          }
        }
      }
    }
  });

  test('held near a corner, that corner lifts first', () {
    final low = _fold(0.1, grip: 1);
    expect(low.depth(0, _h), greaterThan(low.depth(0, 0)));
    expect(low.showsFront(0, _h), isFalse, reason: 'bottom corner turned');
    expect(low.place(0, 0).z, lessThan(low.place(0, _h).z));
    final high = _fold(0.1, grip: -1);
    expect(high.depth(0, 0), greaterThan(high.depth(0, _h)));
    // Lifted off the right, the top right corner leads.
    final back = _fold(0.9, fromRight: true, grip: -1);
    expect(back.depth(0, 0), greaterThan(back.depth(0, _h)));
    expect(back.place(0, 0).x, lessThan(2 * _w));
  });

  group('mesh', () {
    /// The point of the leaf a vertex of [face] shows.
    Offset paperOf(CurlFace face, int i, {required bool front}) {
      final tx = face.textureCoordinates[i * 2];
      final ty = face.textureCoordinates[i * 2 + 1];
      // The back is the right-hand page, whose left edge is at the spine.
      return Offset(front ? tx : _w - tx, ty);
    }

    test('each face shows its own page, drawn where the paper is', () {
      for (final fromRight in [false, true]) {
        for (final f in progresses) {
          for (final grip in [-1.0, 0.0, 1.0]) {
            final fold = _fold(f, fromRight: fromRight, grip: grip);
            final mesh = buildCurlMesh(fold: fold, pixelRatio: 1);
            for (final (face, front) in [
              (mesh.front, true),
              (mesh.back, false),
            ]) {
              final count = face.positions.length ~/ 2;
              expect(face.colors, hasLength(count));
              for (var i = 0; i < count; i++) {
                final paper = paperOf(face, i, front: front);
                final at = fold.place(paper.dx, paper.dy);
                expect(face.positions[i * 2], closeTo(at.x, 1e-2));
                expect(face.positions[i * 2 + 1], closeTo(at.y, 1e-2));
              }
              // Every triangle is on the side of the paper that faces up.
              for (var t = 0; t + 2 < count; t += 3) {
                final centre =
                    (paperOf(face, t, front: front) +
                        paperOf(face, t + 1, front: front) +
                        paperOf(face, t + 2, front: front)) /
                    3;
                expect(fold.showsFront(centre.dx, centre.dy), front);
              }
            }
          }
        }
      }
    });

    test('the part folded over is drawn on top', () {
      final onward = buildCurlMesh(fold: _fold(0.5), pixelRatio: 2);
      expect(
        onward.frontOnTop,
        isFalse,
        reason: 'the next page is folded over',
      );
      expect(onward.back.isEmpty, isFalse);
      final back = buildCurlMesh(
        fold: _fold(0.5, fromRight: true),
        pixelRatio: 2,
      );
      expect(back.frontOnTop, isTrue, reason: 'the page before is folded over');
      expect(back.front.isEmpty, isFalse);
    });

    test('the roll casts its shadow on the page it uncovers', () {
      final onward = buildCurlMesh(fold: _fold(0.5), pixelRatio: 1);
      final fold = _fold(0.5);
      // Turning onward the uncovered page is on the left of the roll.
      expect(onward.outward.dx, lessThan(0));
      expect(onward.silhouette!.start.dx, lessThan(fold.foldX));
      expect(onward.silhouette!.start.dx, greaterThan(0));
      final back = buildCurlMesh(
        fold: _fold(0.5, fromRight: true),
        pixelRatio: 1,
      );
      expect(back.outward.dx, greaterThan(0));
      expect(back.silhouette!.start.dx, greaterThan(_w));
      expect(back.silhouette!.start.dx, lessThan(2 * _w));
      // Lying flat, nothing casts a shadow.
      expect(buildCurlMesh(fold: _fold(0), pixelRatio: 1).silhouette, isNull);
    });
  });
}
