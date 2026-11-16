import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:xml/xml.dart';

/// A page shaped like the real ones: a flipped page group holding some ink,
/// the ayah-number ornaments, more ink, then the invisible polygons at the
/// root. Ink before the ornaments is how page 17 ships.
const String _svg = '''
<?xml version='1.0' encoding='UTF-8'?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:ayah="https://quranpedia.net" version="1.1" viewBox="0 0 345 550" xml:space="preserve"><g transform="matrix(1.3333 0 0 -1.3333 -115 640)"><g transform="translate(1 2)"> <path d="M0 0L1 1Z" fill="#231f20" /> </g><g id="ayah_markers" class="ayah_markers"><g class="ayah-mark"><g class="ayah-mark-ornament" transform="scale(0.009 -0.009)"><path d="M2 2L3 3Z" fill="#231f20" fill-rule="evenodd" /></g><g transform="translate(9 9)" ayah:x="17.38" ayah:y="528.28"><path d="M4 4L5 5Z" fill="#231f20" fill-rule="evenodd" /></g></g></g><g transform="translate(5 6)"><path d="M6 6L7 7Z" fill="#231f20" fill-rule="evenodd" /></g></g><path class="ayahPolygon" fill-opacity="0" id="verse-1" number="002062" ayah="62" surah="2" d="M 0 0 L 10 0 L 10 10 L 0 10 Z" /></svg>''';

void main() {
  group('view box', () {
    test('is read from the page, negative origin included', () {
      expect(SvgPageParser.viewBox(_svg), (
        left: 0.0,
        top: 0.0,
        right: 345.0,
        bottom: 550.0,
      ));
      expect(
        SvgPageParser.viewBox(
          '<svg viewBox="-53.3109 -198.4777 345 550"></svg>',
        ),
        (left: -53.3109, top: -198.4777, right: 291.6891, bottom: 351.5223),
      );
    });

    test('a page without one is rejected', () {
      expect(() => SvgPageParser.viewBox('<svg></svg>'), throwsFormatException);
      expect(
        () => SvgPageParser.viewBox('<svg viewBox="0 0 0 550"></svg>'),
        throwsFormatException,
      );
    });
  });

  group('split', () {
    late ({String ink, String marks}) parts;
    setUpAll(() => parts = SvgPageParser.split(_svg));

    test('both halves are whole SVG documents over the same view box', () {
      for (final half in [parts.ink, parts.marks]) {
        final root = XmlDocument.parse(half).rootElement;
        expect(root.name.local, 'svg');
        expect(root.getAttribute('viewBox'), '0 0 345 550');
        // Both keep the flipped page transform, so they overlay exactly.
        expect(
          root.childElements.first.getAttribute('transform'),
          'matrix(1.3333 0 0 -1.3333 -115 640)',
        );
      }
    });

    test('the ornaments go to one half and the script to the other', () {
      expect(parts.marks, contains('ayah-mark-ornament'));
      expect(parts.marks, contains('M2 2L3 3Z'));
      expect(parts.marks, contains('M4 4L5 5Z'));
      expect(parts.marks, isNot(contains('M0 0L1 1Z')));
      expect(parts.marks, isNot(contains('M6 6L7 7Z')));

      expect(parts.ink, isNot(contains('ayah_markers')));
      // Ink on both sides of the ornaments is kept.
      expect(parts.ink, contains('M0 0L1 1Z'));
      expect(parts.ink, contains('M6 6L7 7Z'));
    });

    test('no path is lost or duplicated, and nothing is redrawn', () {
      int paths(String svg) => '<path '.allMatches(svg).length;
      // 4 artwork paths; the polygon is dropped from both halves.
      expect(paths(parts.ink) + paths(parts.marks), 4);
      expect(parts.ink, isNot(contains('ayahPolygon')));
      expect(parts.marks, isNot(contains('ayahPolygon')));
    });

    test('an empty group that closes itself opens nothing', () {
      // Some pages of other readings ship an ornament whose number group is
      // empty and self-closed.
      final svg = _svg.replaceFirst(
        '<g transform="translate(9 9)" ayah:x="17.38" ayah:y="528.28">'
            '<path d="M4 4L5 5Z" fill="#231f20" fill-rule="evenodd" /></g>',
        '<g transform="translate(9 9)" ayah:x="17.38" ayah:y="528.28" />',
      );
      expect(svg, isNot(_svg));
      final split = SvgPageParser.split(svg);
      expect(split.marks, contains('ayah-mark-ornament'));
      expect(split.marks, isNot(contains('M6 6L7 7Z')));
      expect(split.ink, contains('M6 6L7 7Z'));
      XmlDocument.parse(split.ink);
      XmlDocument.parse(split.marks);
    });

    test('a page without ornaments yields an empty ornament layer', () {
      final plain = _svg.replaceRange(
        _svg.indexOf('<g id="ayah_markers"'),
        _svg.indexOf('<g transform="translate(5 6)">'),
        '',
      );
      final halves = SvgPageParser.split(plain);
      expect(XmlDocument.parse(halves.marks).rootElement.children, isEmpty);
      expect(halves.ink, contains('M0 0L1 1Z'));
    });
  });

  group('regions', () {
    final page1 = File('test/fixtures/svg/001.json').readAsStringSync();
    final page3 = File('test/fixtures/svg/003.json').readAsStringSync();

    test('page 1 is Al-Fatiha: seven point-list staircases', () {
      final regions = SvgPageParser.regions(page1);
      expect(
        [for (final r in regions) r.ref],
        [for (var ayah = 1; ayah <= 7; ayah++) AyahRef(1, ayah)],
      );
      for (final region in regions) {
        expect(region.rings, hasLength(1));
        expect(region.rings.single.length, greaterThanOrEqualTo(4));
      }
    });

    test('page 3 uses path data: one ring per printed line', () {
      final regions = SvgPageParser.regions(page3);
      expect(regions.first.ref, const AyahRef(2, 6));
      expect(regions.any((r) => r.rings.length > 1), isTrue);
      for (final region in regions) {
        for (final ring in region.rings) {
          expect(ring, hasLength(4), reason: 'line bands are rectangles');
        }
      }
    });

    test('broken files are rejected', () {
      expect(() => SvgPageParser.regions('{}'), throwsFormatException);
      expect(
        () => SvgPageParser.regions('[{"surahNumber":1,"ayahNumber":1}]'),
        throwsFormatException,
      );
      expect(
        () => SvgPageParser.regions(
          '[{"surahNumber":1,"ayahNumber":1,"polygon":"M 0 0 L 1"}]',
        ),
        throwsFormatException,
      );
    });
  });

  group('layout', () {
    SvgPageLayout layoutOf(String name, PageBox viewBox) => SvgPageLayout(
      viewBox: viewBox,
      regions: SvgPageParser.regions(
        File('test/fixtures/svg/$name.json').readAsStringSync(),
      ),
    );
    const full = (left: 0.0, top: 0.0, right: 345.0, bottom: 550.0);
    const opening = (
      left: -53.3109,
      top: -198.4777,
      right: 291.6891,
      bottom: 351.5223,
    );

    test('every ayah is found inside its own region and nowhere else', () {
      final layout = layoutOf('003', full);
      for (final region in layout.regions) {
        final ring = region.rings.first;
        final x = (ring[0].x + ring[2].x) / 2;
        final y = (ring[0].y + ring[2].y) / 2;
        expect(layout.ayahAt(x, y), region.ref);
        expect(layout.regionOf(region.ref), same(region));
      }
      expect(layout.ayahAt(-5, -5), isNull);
      expect(layout.regionOf(const AyahRef(114, 1)), isNull);
    });

    test('a full page shows its whole view box', () {
      expect(layoutOf('003', full).content, full);
    });

    test('an opening page is cropped to its small block of text', () {
      final content = layoutOf('001', opening).content;
      final shown = pageBoxWidth(content) * pageBoxHeight(content);
      expect(shown, lessThan(345 * 550 * 0.4));
      // Every ayah is still inside what is shown.
      for (final region in layoutOf('001', opening).regions) {
        final box = region.bounds;
        expect(box.left, greaterThanOrEqualTo(content.left));
        expect(box.top, greaterThanOrEqualTo(content.top));
        expect(box.right, lessThanOrEqualTo(content.right));
        expect(box.bottom, lessThanOrEqualTo(content.bottom));
      }
    });

    test('a page builds from its two files', () {
      final page = SvgPageParser.page(
        3,
        svg: _svg,
        json: File('test/fixtures/svg/003.json').readAsStringSync(),
      );
      expect(page.page, 3);
      expect(page.layout.viewBox, full);
      expect(page.marks, contains('ayah-mark-ornament'));
      // A full page keeps its whole box as the view box of both halves.
      for (final half in [page.ink, page.marks]) {
        expect(SvgPageParser.viewBox(half), full);
      }
    });

    test('an opening page’s artwork is cropped by its view box alone', () {
      final page = SvgPageParser.page(
        1,
        svg: _svg.replaceFirst(
          'viewBox="0 0 345 550"',
          'viewBox="-53.3109 -198.4777 345 550"',
        ),
        json: File('test/fixtures/svg/001.json').readAsStringSync(),
      );
      for (final half in [page.ink, page.marks]) {
        final shown = SvgPageParser.viewBox(half);
        expect(shown.left, closeTo(page.layout.content.left, 0.001));
        expect(shown.bottom, closeTo(page.layout.content.bottom, 0.001));
      }
      // Only the viewport changed: every path is as it was.
      expect(page.ink, contains('M0 0L1 1Z'));
      expect(page.marks, contains('M2 2L3 3Z'));
    });
  });
}
