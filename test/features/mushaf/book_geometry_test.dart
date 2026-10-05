import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_geometry.dart';

void main() {
  const single = BookGeometry(pageCount: 604, spread: false);
  const spread = BookGeometry(pageCount: 604, spread: true);

  test('single mode: one page per step', () {
    expect(single.stepCount, 604);
    expect(single.stepOfPage(1), 0);
    expect(single.stepOfPage(604), 603);
    expect(single.pageOfStep(41), 42);
    expect(single.rightPage(603), 604);
    expect(single.rightPage(604), isNull);
    expect(single.leftPage(0), isNull);
  });

  test('spread mode: odd page on the right, even page on its left', () {
    expect(spread.stepCount, 302);
    expect(spread.rightPage(0), 1);
    expect(spread.leftPage(0), 2);
    expect(spread.rightPage(1), 3);
    expect(spread.leftPage(1), 4);
    expect(spread.rightPage(301), 603);
    expect(spread.leftPage(301), 604);
    expect(spread.leftPage(302), isNull);
  });

  test('every page belongs to exactly one spread', () {
    final seen = <int>[];
    for (var step = 0; step < spread.stepCount; step++) {
      seen
        ..add(spread.rightPage(step)!)
        ..add(spread.leftPage(step)!);
    }
    expect(seen, [for (var page = 1; page <= 604; page++) page]);
  });

  test('page and step round-trip', () {
    for (var page = 1; page <= 604; page++) {
      final step = spread.stepOfPage(page);
      expect(
        page == spread.rightPage(step) || page == spread.leftPage(step),
        isTrue,
        reason: 'page $page',
      );
      expect(single.pageOfStep(single.stepOfPage(page)), page);
    }
  });

  test('an odd page count leaves the last left page empty', () {
    const odd = BookGeometry(pageCount: 5, spread: true);
    expect(odd.stepCount, 3);
    expect(odd.rightPage(2), 5);
    expect(odd.leftPage(2), isNull);
  });

  test('positions are clamped to the book', () {
    expect(spread.clampPosition(-3), 0);
    expect(spread.clampPosition(999), 301);
    expect(spread.clampPosition(2.5), 2.5);
  });
}
