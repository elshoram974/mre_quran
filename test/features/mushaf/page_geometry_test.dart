import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/domain/page_geometry.dart';
import 'package:mre_quran/features/mushaf/domain/page_layout.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';

/// A white image with black rectangles, given as (left, top, right, bottom).
InkImage _image(int w, int h, List<(int, int, int, int)> blocks) {
  final rgba = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
  for (final (l, t, r, b) in blocks) {
    for (var y = t; y < b; y++) {
      for (var x = l; x < r; x++) {
        final i = (y * w + x) * 4;
        rgba[i] = rgba[i + 1] = rgba[i + 2] = 0;
      }
    }
  }
  return InkImage(width: w, height: h, rgba: rgba);
}

Map<String, Object?> _word(String location, String word) => {
  'location': location,
  'word': word,
};

void main() {
  group('PageLayout.parse', () {
    test('reads lines, types, and word locations', () {
      final layout = PageLayout.parse(
        jsonEncode({
          'page': 1,
          'lines': [
            {'type': 'surah-header'},
            {'type': 'basmala'},
            {
              'type': 'text',
              'words': [_word('1:2:1', 'ٱلْحَمْدُ'), _word('1:2:2', 'لِلَّهِ')],
            },
          ],
        }),
      );
      expect(layout.page, 1);
      expect(layout.lines.map((l) => l.type), [
        LayoutLineType.surahHeader,
        LayoutLineType.basmala,
        LayoutLineType.text,
      ]);
      expect(layout.lines[2].words.first.ayah, const AyahRef(1, 2));
      expect(layout.lines[2].words.last.index, 2);
    });

    test('rejects malformed layouts', () {
      for (final source in [
        '[]',
        '{"page": 1}',
        '{"page": 1, "lines": [{"type": "poem"}]}',
        '{"page": 1, "lines": [{"type": "text", "words": '
            '[{"location": "1:x:1", "word": "a"}]}]}',
        'not json',
      ]) {
        expect(
          () => PageLayout.parse(source),
          throwsFormatException,
          reason: source,
        );
      }
    });
  });

  group('measurePageGeometry', () {
    // Two text lines. Line 1: two words of one and three letters, read right
    // to left. Line 2: a single word of the next ayah.
    final layout = PageLayout.parse(
      jsonEncode({
        'page': 9,
        'lines': [
          {
            'type': 'text',
            'words': [_word('2:1:1', 'ا'), _word('2:1:2', 'ابت')],
          },
          {
            'type': 'text',
            'words': [_word('2:2:1', 'ابت')],
          },
        ],
      }),
    );
    final image = _image(200, 100, [
      (150, 10, 180, 40), // word 1, right
      (40, 10, 130, 40), // word 2, left
      (60, 60, 180, 90), // line 2
    ]);
    final geometry = measurePageGeometry(layout, image);

    test('finds a box for every word', () {
      expect(geometry.words, hasLength(3));
    });

    test('splits the line at the ink gap, first word on the right', () {
      final first = geometry.words[0];
      final second = geometry.words[1];
      expect(first.word, 1);
      expect(first.right, closeTo(179 / 200, 0.01));
      expect(first.left, inInclusiveRange(130 / 200, 150 / 200));
      expect(second.right, first.left);
      expect(second.left, closeTo(40 / 200, 0.01));
    });

    test('lines do not overlap and cover their ink', () {
      final line1 = geometry.words[0];
      final line2 = geometry.words[2];
      expect(line1.top, lessThanOrEqualTo(0.1));
      expect(line1.bottom, inInclusiveRange(0.4, 0.6));
      expect(line2.top, line1.bottom);
      expect(line2.bottom, greaterThanOrEqualTo(0.9));
    });

    test('ayahAt and rectsOf agree with the boxes', () {
      expect(geometry.ayahAt(0.8, 0.25), const AyahRef(2, 1));
      expect(geometry.ayahAt(0.6, 0.75), const AyahRef(2, 2));
      expect(geometry.ayahAt(0.05, 0.75), isNull);
      final rects = geometry.rectsOf(const AyahRef(2, 1));
      expect(rects, hasLength(1));
      expect(rects.single.left, closeTo(0.2, 0.01));
      expect(rects.single.right, closeTo(179 / 200, 0.01));
    });

    test('a blank image gives no boxes', () {
      expect(measurePageGeometry(layout, _image(50, 50, [])).words, isEmpty);
    });
  });
}
