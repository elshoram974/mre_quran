import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/line_spread.dart';

void main() {
  // Three rows of 0.2 of the image height, from 0.1.
  const cuts = [0.1, 0.3, 0.5, 0.7];
  const crop = (left: 0.0, top: 0.0, right: 1.0, bottom: 1.0);

  // The image is as wide as it is tall: 100 px wide area, 0.6 of 100 px of
  // rows, in 100 + 60 = 160 px of height.
  final spread = LineSpread.fit(
    cuts: cuts,
    crop: crop,
    aspect: 1,
    area: const Size(100, 120),
  )!;

  test('keeps every row at the width scale and shares out the rest', () {
    final rows = spread.rows;
    expect(rows, hasLength(3));
    for (final row in rows) {
      expect(row.destHeight, closeTo(20, 1e-9));
    }
    // 120 - 60 = 60 px of room, 20 px per row, half above and half below.
    expect(rows[0].destTop, closeTo(10, 1e-9));
    expect(rows[1].destTop, closeTo(50, 1e-9));
    expect(rows[2].destTop, closeTo(90, 1e-9));
  });

  test('maps image fractions to the screen and back', () {
    expect(spread.toScreen(0.1), closeTo(10, 1e-9));
    expect(spread.toScreen(0.3, bottom: true), closeTo(30, 1e-9));
    expect(spread.toScreen(0.3), closeTo(50, 1e-9));
    expect(spread.toImage(20), closeTo(0.2, 1e-9));
    expect(spread.toImage(60), closeTo(0.4, 1e-9));
  });

  test('a press in a gap lands on the nearer row', () {
    expect(spread.toImage(35), closeTo(0.3, 1e-9));
    expect(spread.toImage(41), closeTo(0.3, 1e-9));
  });

  test('a page that already fills the area is not spread', () {
    expect(
      LineSpread.fit(
        cuts: cuts,
        crop: crop,
        aspect: 1,
        area: const Size(100, 50),
      ),
      isNull,
    );
    expect(
      LineSpread.fit(
        cuts: const [],
        crop: crop,
        aspect: 1,
        area: const Size(100, 500),
      ),
      isNull,
    );
  });

  test('a page of few rows keeps its gaps modest and sits in the middle', () {
    // Two rows of 20 px in 400 px: gaps are capped at one row.
    final few = LineSpread.fit(
      cuts: const [0.1, 0.3, 0.5],
      crop: crop,
      aspect: 1,
      area: const Size(100, 400),
    )!;
    final rows = few.rows;
    expect(rows[1].destTop - (rows[0].destTop + rows[0].destHeight), 20);
    // 400 - (20 + 20 + 2 * 20 gaps) = 320 left over, half above.
    expect(rows[0].destTop, closeTo(170, 1e-9));
  });
}
