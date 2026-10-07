import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/ayah_info_database.dart';
import 'package:mre_quran/features/mushaf/domain/page_geometry.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';

import '../../helpers/ayah_info_fixture.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('ayahinfo'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('reads the glyphs of one page', () {
    // page, line, sura, ayah, position, min_x, max_x, min_y, max_y
    final file = writeAyahInfo(dir, [
      [42, 1, 2, 253, 1, 920, 978, 53, 111],
      [42, 1, 2, 253, 2, 846, 909, 49, 109],
      [43, 1, 2, 257, 1, 900, 950, 50, 110],
    ]);
    final db = AyahInfoDatabase.open(file);
    addTearDown(db.close);
    final glyphs = db.page(42);
    expect(glyphs, hasLength(2));
    expect(glyphs.first.ayah, const AyahRef(2, 253));
    expect(glyphs.first.minX, 920);
    expect(db.page(1), isEmpty);
  });

  group('glyphGeometry', () {
    GlyphBox glyph(int ayah, int line, int x0, int x1, int y0, int y1) => (
      ayah: AyahRef(1, ayah),
      position: 1,
      line: line,
      minX: x0,
      maxX: x1,
      minY: y0,
      maxY: y1,
    );

    final geometry = glyphGeometry(
      [
        glyph(1, 1, 600, 900, 100, 180),
        glyph(1, 1, 300, 590, 120, 200),
        // Swapped edges are read either way round.
        glyph(2, 1, 290, 100, 110, 190),
        glyph(2, 2, 200, 800, 300, 380),
      ],
      width: 1000,
      height: 1000,
      lines: 5,
    );

    test('gives every glyph its line band and fixes swapped edges', () {
      expect(geometry.words, hasLength(4));
      for (final box in geometry.words.take(3)) {
        expect((box.top, box.bottom), (0.1, 0.2));
      }
      expect(geometry.words[2].left, 0.1);
      expect(geometry.words[2].right, 0.29);
      expect(geometry.inkTop, 0.1);
      expect(geometry.inkBottom, 0.38);
    });

    test('lays equal rows through the text lines, title rows included', () {
      expect(geometry.lineCuts, hasLength(6));
      expect(geometry.lineCuts.first, closeTo(0.055, 1e-9));
      expect(geometry.lineCuts[1] - geometry.lineCuts[0], closeTo(0.19, 1e-9));
    });

    test('a press between words picks the nearest one on the line', () {
      expect(geometry.ayahAt(0.595, 0.15), const AyahRef(1, 1));
      expect(geometry.ayahAt(0.292, 0.15), const AyahRef(1, 2));
      expect(geometry.ayahAt(0.02, 0.35), isNull, reason: 'far from words');
    });

    test('a press between lines picks the nearer line', () {
      expect(geometry.ayahAt(0.5, 0.21), const AyahRef(1, 1));
      expect(geometry.ayahAt(0.5, 0.29), const AyahRef(1, 2));
      expect(geometry.ayahAt(0.5, 0.25), isNull, reason: 'too far from both');
      expect(geometry.ayahAt(0.5, 0.6), isNull, reason: 'below the text');
    });

    test('an ayah spans one rectangle per line', () {
      final rects = geometry.rectsOf(const AyahRef(1, 2));
      expect(rects, hasLength(2));
      expect(rects.first.left, 0.1);
    });

    test('a selection takes whole rows, equally tall, with no gap between', () {
      final rects = geometry.rectsOf(const AyahRef(1, 2));
      final pitch = geometry.lineCuts[1] - geometry.lineCuts[0];
      for (final rect in rects) {
        expect(rect.bottom - rect.top, closeTo(pitch, 1e-9));
      }
      expect(rects.last.top, closeTo(rects.first.bottom, 1e-9));
    });
  });
}
