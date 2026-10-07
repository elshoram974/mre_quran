import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/curl_mesh.dart';

/// Screen x of the free edge: the left end of the sheet's outline.
double _freeEdge(double lead, double progress) => buildCurlMesh(
  progress: progress,
  size: const Size(300, 600),
  vanishX: 300,
  pixelRatio: 1,
  lead: lead,
).outline.last.x;

void main() {
  test('flat at both ends, however the sheet is being turned', () {
    for (final lead in [-1.0, 0.0, 1.0]) {
      expect(_freeEdge(lead, 0), closeTo(0, 1e-6));
      expect(_freeEdge(lead, 1), closeTo(600, 1e-6));
    }
  });

  test('turning back bends the sheet the opposite way to turning forward', () {
    const halfway = 0.5;
    final forward = _freeEdge(1, halfway);
    final back = _freeEdge(-1, halfway);
    final plain = _freeEdge(0, halfway);
    // The two bends lie on opposite sides of the plain sheet.
    expect(forward, lessThan(plain));
    expect(back, greaterThan(plain));
    expect(forward, isNot(closeTo(back, 10)));
  });

  test('turning back is the exact mirror of turning forward', () {
    // A sheet turned back at progress f has the shape of the same sheet turned
    // forward at 1 - f, seen from the other side: the same lift, mirrored
    // about the spine, so a page being peeled off the page it landed on does
    // not start out bent.
    for (var f = 0.05; f < 1; f += 0.1) {
      final back = _freeEdge(-1, f);
      final forward = _freeEdge(1, 1 - f);
      expect(back, closeTo(600 - forward, 1e-6), reason: 'f=$f');
    }
  });
}
