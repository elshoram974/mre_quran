import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/domain/page_scrub_scale.dart';

void main() {
  group('whole scale', () {
    const scale = PageScrubScale.whole(604);

    test('spans the Mushaf from end to end', () {
      expect(scale.fine, isFalse);
      expect(scale.pageAt(0), 1);
      expect(scale.pageAt(1), 604);
      expect(scale.pageAt(0.5), 303);
    });

    test('keeps fractions outside the track at its ends', () {
      expect(scale.pageAt(-2), 1);
      expect(scale.pageAt(3), 604);
      expect(scale.fractionOf(0), 0);
      expect(scale.fractionOf(900), 1);
    });

    test('a page maps back to itself', () {
      for (final page in [1, 2, 213, 603, 604]) {
        expect(scale.pageAt(scale.fractionOf(page)), page);
      }
    });
  });

  group('fine scale', () {
    test('keeps the page under the finger', () {
      final scale = PageScrubScale.fineAt(213, fraction: 0.4, pageCount: 604);
      expect(scale.fine, isTrue);
      expect(scale.last - scale.first, PageScrubScale.defaultFineSpan);
      expect(scale.pageAt(0.4), 213);
    });

    test('moves one page per step of the track', () {
      final scale = PageScrubScale.fineAt(213, fraction: 0.5, pageCount: 604);
      const step = 1 / PageScrubScale.defaultFineSpan;
      expect(scale.pageAt(0.5 + step), 214);
      expect(scale.pageAt(0.5 - step), 212);
    });

    test('stays inside the Mushaf at both ends', () {
      final start = PageScrubScale.fineAt(2, fraction: 0.9, pageCount: 604);
      expect(start.first, 1);
      expect(start.last, 21);
      final end = PageScrubScale.fineAt(603, fraction: 0.1, pageCount: 604);
      expect(end.first, 584);
      expect(end.last, 604);
    });

    test('shrinks to a Mushaf shorter than its span', () {
      final scale = PageScrubScale.fineAt(3, fraction: 0.5, pageCount: 5);
      expect(scale.first, 1);
      expect(scale.last, 5);
    });

    test('labels every fifth page', () {
      final scale = PageScrubScale.fineAt(213, fraction: 0.5, pageCount: 604);
      expect(scale.isMajor(210), isTrue);
      expect(scale.isMajor(213), isFalse);
    });
  });
}
