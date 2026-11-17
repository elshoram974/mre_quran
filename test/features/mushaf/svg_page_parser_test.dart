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

    test('an opening page keeps its surah\'s name and basmala, which lie in '
        'no ayah region', () {
      // Al-Baqarah's opening: its ayahs from 0 to 150, its name and basmala
      // drawn above them, from -60.
      final layout = SvgPageLayout(
        viewBox: (left: -53, top: -198, right: 292, bottom: 352),
        regions: [
          const AyahRegion(
            ref: AyahRef(2, 1),
            rings: [
              [(x: 0, y: 0), (x: 240, y: 0), (x: 240, y: 150), (x: 0, y: 150)],
            ],
          ),
        ],
        ink: (left: 0, top: -60, right: 240, bottom: 150),
      );
      final content = layout.content;
      expect(content.top, lessThan(-60));
      expect(content.bottom, greaterThan(150));
      expect(content, isNot(layout.viewBox));
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

  group('surah names on a printed page', () {
    AyahRegion band(int surah, int ayah, double top, double bottom) =>
        AyahRegion(
          ref: AyahRef(surah, ayah),
          rings: [
            [
              (x: 0, y: top),
              (x: 345, y: top),
              (x: 345, y: bottom),
              (x: 0, y: bottom),
            ],
          ],
        );
    const line = 550 / 15;

    test('a name stands two lines above its first ayah, over the basmala', () {
      // Page 50: Al Imran opens on the third line.
      final layout = SvgPageLayout(
        viewBox: (left: 0, top: 0, right: 345, bottom: 550),
        regions: [band(3, 1, 74.8, 112.8), band(3, 2, 112.8, 550)],
      );
      final title = layout.surahTitles.single;
      expect(title.surah, 3);
      expect(title.bottom, closeTo(74.8 - line, 0.01));
      expect(title.top, closeTo(74.8 - 2 * line, 0.01));
    });

    test('At-Tawbah has no basmala: its name is on the line above', () {
      final layout = SvgPageLayout(
        viewBox: (left: 0, top: 0, right: 345, bottom: 550),
        regions: [band(8, 75, 0, 39.5), band(9, 1, 39.5, 550)],
      );
      final title = layout.surahTitles.single;
      expect(title.surah, 9);
      expect(title.bottom, closeTo(39.5, 0.01));
    });

    test('several surahs on one page each get their name, top first', () {
      // Page 604: Al-Ikhlas, Al-Falaq, An-Nas.
      final layout = SvgPageLayout(
        viewBox: (left: 0, top: 0, right: 345, bottom: 550),
        regions: [
          band(112, 1, 74.2, 112.8),
          band(113, 1, 218.5, 257.2),
          band(114, 1, 398.5, 550),
        ],
      );
      expect([for (final t in layout.surahTitles) t.surah], [112, 113, 114]);
    });

    test('a page with no opening has no name, and the cropped opening pages '
        'keep their own frames', () {
      expect(
        SvgPageParser.page(
          3,
          svg: _svg,
          json: File('test/fixtures/svg/003.json').readAsStringSync(),
        ).layout.surahTitles,
        isEmpty,
      );
      final cropped = SvgPageLayout(
        viewBox: (left: 0, top: 0, right: 345, bottom: 550),
        regions: [band(1, 1, 200, 230), band(1, 2, 230, 260)],
      );
      expect(cropped.content, isNot(cropped.viewBox));
      expect(cropped.surahTitles, isEmpty);
    });

    group('the name\'s own box, from the printed lines', () {
      /// A printed line at [middle], [share] of the page wide, centred
      /// unless moved by [offset].
      SvgPrintedLine printed(double middle, double share, {double offset = 0}) {
        final half = 345 * share / 2;
        return (
          middle: middle,
          box: (
            left: 172.5 - half + offset,
            top: middle - 12,
            right: 172.5 + half + offset,
            bottom: middle + 12,
          ),
        );
      }

      // Full lines, at the printed pitch.
      List<SvgPrintedLine> page(Map<int, SvgPrintedLine> special) => [
        for (var k = 0; k < 15; k++)
          special[k] ?? printed(line * (k + 0.6), 0.94),
      ];

      test('is the short centred line with a basmala under it', () {
        final layout = SvgPageLayout(
          viewBox: (left: 0, top: 0, right: 345, bottom: 550),
          regions: [band(3, 1, 74.8, 112.8), band(3, 2, 112.8, 550)],
        );
        final name = printed(line * 0.6, 0.22);
        final titles = SvgPageParser.titles(
          layout,
          page({0: name, 1: printed(line * 1.6, 0.58)}),
        );
        expect(titles.single.surah, 3);
        expect(titles.single.box, name.box);
        expect(titles.single.line, name.middle);
      });

      test('is found where a reading counts the name into the first ayah, '
          'and never on the short line that ends a surah', () {
        // Qalun page 528: the regions put Al-Qamar's first ayah three lines
        // too high; a short last line of An-Najm stands above its name.
        final layout = SvgPageLayout(
          viewBox: (left: 0, top: 0, right: 345, bottom: 550),
          regions: [band(53, 50, 0, 287), band(54, 1, 287, 550)],
        );
        final name = printed(line * 9.6, 0.23);
        final titles = SvgPageParser.titles(
          layout,
          page({
            8: printed(line * 8.6, 0.38),
            9: name,
            10: printed(line * 10.6, 0.6),
          }),
        );
        expect(titles.single.box, name.box);
      });

      test('At-Tawbah\'s has no basmala under it', () {
        final layout = SvgPageLayout(
          viewBox: (left: 0, top: 0, right: 345, bottom: 550),
          regions: [band(8, 75, 0, 39.5), band(9, 1, 39.5, 550)],
        );
        final name = printed(line * 0.6, 0.2);
        expect(
          SvgPageParser.titles(layout, page({0: name})).single.box,
          name.box,
        );
      });

      test('a name not found gets no frame rather than one over the text', () {
        final layout = SvgPageLayout(
          viewBox: (left: 0, top: 0, right: 345, bottom: 550),
          regions: [band(3, 1, 74.8, 112.8), band(3, 2, 112.8, 550)],
        );
        expect(SvgPageParser.titles(layout, page({})), isEmpty);
        expect(SvgPageParser.titles(layout, const []), isEmpty);
      });
    });
  });
}
