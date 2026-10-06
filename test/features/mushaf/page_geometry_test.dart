import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/domain/page_geometry.dart';
import 'package:mre_quran/features/mushaf/domain/sakina_pages.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';

typedef _Rect = (int, int, int, int);

/// A white image with black [ink] rectangles and marker-filled [markers],
/// each given as (left, top, right, bottom).
InkImage _image(
  int w,
  int h, {
  List<_Rect> ink = const [],
  List<_Rect> markers = const [],
}) {
  final rgba = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
  void paint(List<_Rect> rects, int r, int g, int b) {
    for (final (l, t, rr, bb) in rects) {
      for (var y = t; y < bb; y++) {
        for (var x = l; x < rr; x++) {
          final i = (y * w + x) * 4;
          rgba[i] = r;
          rgba[i + 1] = g;
          rgba[i + 2] = b;
        }
      }
    }
  }

  paint(ink, 0, 0, 0);
  paint(markers, 0xD8, 0xE9, 0xD8);
  return InkImage(width: w, height: h, rgba: rgba);
}

void main() {
  group('measurePageGeometry', () {
    const first = AyahRef(2, 1);
    const second = AyahRef(2, 2);
    // Two lines. Line 1: letters, a marker closing the first ayah, more
    // letters of the second. Line 2: letters, then a marker closing the
    // second ayah at the left end.
    final image = _image(
      200,
      100,
      ink: [(30, 10, 180, 40), (62, 60, 180, 90)],
      markers: [(100, 15, 122, 35), (40, 65, 62, 85)],
    );
    final geometry = measurePageGeometry([first, second], image, lines: 2);

    test('cuts each ayah at the marker that closes it', () {
      expect(geometry.words, hasLength(3));
      final [a, b, c] = geometry.words;
      expect((a.ayah, a.line), (first, 0));
      expect((b.ayah, b.line), (second, 0));
      expect((c.ayah, c.line), (second, 1));
      expect(a.right, closeTo(181 / 200, 0.01));
      expect(a.left, closeTo(b.right, 0.001));
      expect(b.left, closeTo(30 / 200, 0.01));
      expect(geometry.inkTop, 0.1);
      expect(geometry.inkBottom, 0.9);
    });

    test('ayahAt and rectsOf agree with the boxes', () {
      expect(geometry.ayahAt(0.8, 0.25), first);
      expect(geometry.ayahAt(0.3, 0.25), second);
      expect(geometry.ayahAt(0.6, 0.75), second);
      expect(geometry.rectsOf(second), hasLength(2));
    });

    test('markers that do not match the ayahs give no boxes', () {
      final none = measurePageGeometry(
        [first, second, const AyahRef(2, 3)],
        image,
        lines: 2,
      );
      expect(none.words, isEmpty);
      expect(none.inkTop, 0.1);
    });

    test('a blank image gives no boxes', () {
      expect(
        measurePageGeometry([first], _image(50, 50), lines: 1).words,
        isEmpty,
      );
    });
  });

  group('Sakina pages', () {
    late QuranMetadata metadata;

    setUpAll(() {
      metadata = QuranMetadataParser.parse(
        File(QuranMetadataSource.assetPath).readAsStringSync(),
      );
    });

    test('the page counts add up to every ayah in the Quran', () {
      expect(sakinaAyahsEndingOnPage, hasLength(604));
      expect(sakinaAyahsEndingOnPage.reduce((a, b) => a + b), 6236);
    });

    test('pages follow one another without a gap or a repeat', () {
      AyahRef? last;
      for (var page = 1; page <= 604; page++) {
        final ayahs = sakinaAyahsOnPage(metadata, page);
        expect(ayahs, hasLength(sakinaAyahsEndingOnPage[page - 1]));
        if (last != null) {
          expect(ayahs.first.compareTo(last), greaterThan(0));
        }
        last = ayahs.last;
      }
      expect(last, const AyahRef(114, 6));
    });

    test('page 120 ends with ayah 77, unlike the 1405 H page map', () {
      final ayahs = sakinaAyahsOnPage(metadata, 120);
      expect(ayahs.first, const AyahRef(5, 71));
      expect(ayahs.last, const AyahRef(5, 77));
    });

    test('the opening pages have eight lines', () {
      expect([1, 2, 3].map(printedLinesOnPage), [8, 8, 15]);
    });
  });
}
