import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/svg_line_splitter.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';

import '../../helpers/svg_page_fixtures.dart';

const PageBox _box = (left: 0, top: 0, right: 345, bottom: 550);

({SvgSpreadLayer ink, SvgSpreadLayer marks})? _split(String svg) {
  final parts = SvgPageParser.split(svg);
  return SvgLineSplitter.split(ink: parts.ink, marks: parts.marks, box: _box);
}

String _why(String svg) {
  final parts = SvgPageParser.split(svg);
  try {
    SvgLineSplitter.splitOrThrow(ink: parts.ink, marks: parts.marks, box: _box);
  } on SvgLinesUnclear catch (problem) {
    return problem.reason;
  }
  return 'spread';
}

/// Every coordinate pair a path's absolute opening moves name.
Iterable<String> _starts(String svg) =>
    RegExp(r'd="(M[-\d.]+ [-\d.]+)').allMatches(svg).map((m) => m.group(1)!);

void main() {
  group('a page with clear lines', () {
    final layers = _split(spreadSvg())!;

    test('finds both lines and puts the sign on the line it sits on', () {
      // Three pieces in drawing order: the sign, the lower line, the upper.
      expect(layers.ink.shifts, hasLength(3));
      expect(layers.ink.shifts.toSet(), hasLength(2));
      // The page group flips the page, so moving down is a negative shift.
      // The upper line's middle is 98 below the top; the lower one's, 135.
      expect(layers.ink.shifts, [-98, -135, -98]);
    });

    test('ties each ornament to its line', () {
      expect(layers.marks.shifts, [-98]);
    });

    test('at a stretch of 1 nothing moves and the view box is unchanged', () {
      final ink = layers.ink.at(1);
      expect(ink, contains('viewBox="0.0 0.0 345.0 550.0"'));
      expect(RegExp(r'translate\(0 -?0\.0\)').allMatches(ink), hasLength(3));
    });

    test('a stretch moves each line as far as a taller page would', () {
      final ink = layers.ink.at(1.5);
      expect(ink, contains('viewBox="0.0 0.0 345.0 825.0"'));
      expect('translate(0 -49.0)'.allMatches(ink), hasLength(2));
      expect('translate(0 -67.5)'.allMatches(ink), hasLength(1));
      expect(layers.marks.at(1.5), contains('translate(0 -49.0)'));
    });

    test('keeps every contour, once, and redraws none', () {
      final ink = layers.ink.at(1.3);
      // 3 contours of the sign and 9 of each line.
      expect('h4v4h-4z'.allMatches(ink), hasLength(21));
      // Each piece opens where the original pen was, written out in full,
      // as the contours before it are no longer in its path.
      expect(_starts(ink), ['M150.0 447.0', 'M10.0 413.0', 'M10.0 450.0']);
      // Past its opening move, each piece is the original text.
      expect(ink, contains('M10.0 413.0h4v4h-4zm40 0h4v4h-4z'));
      expect(ink, isNot(contains('ayahPolygon')));
    });

    test('the same stretch gives the same string, for the picture cache', () {
      expect(identical(layers.ink.at(1.2), layers.ink.at(1.2)), isTrue);
    });

    test('a page built by the parser can spread', () {
      final page = spreadPage(3);
      expect(page.canSpread, isTrue);
      expect(page.inkLines!.shifts.toSet(), hasLength(2));
    });
  });

  group('a page is left alone when', () {
    test('its script is in more than one path', () {
      final svg = spreadSvg().replaceFirst(
        '<g id="content">',
        '<g transform="translate(1 1)"><path d="M0 0L1 1Z" /></g>'
            '<g id="content">',
      );
      expect(_why(svg), 'script in more than one path');
      expect(_split(svg), isNull);
    });

    test('its path uses a command the scanner does not read', () {
      final svg = spreadSvg(script: 'm10 450a4 4 0 0 1 4 4z');
      expect(_why(svg), 'unreadable path data');
    });

    test('a contour inside a line lies nearer the next line', () {
      // The fifth square of the upper line, dropped 30 below it.
      final script = [
        lineOfSquares(10, 413),
        square(-320, 37),
        for (var i = 1; i < 4; i++) square(40, 0),
        square(40, -30),
        square(40, 30),
        for (var i = 6; i < 9; i++) square(40, 0),
      ].join();
      expect(_why(spreadSvg(script: script)), contains('too far from it'));
    });

    test('a sign lies between two lines', () {
      // Three contours 18 below the upper line and 19 above the lower.
      final script = [
        'm150 432h4v4h-4z',
        square(2, 0),
        square(2, 0),
        lineOfSquares(-144, -19),
        lineOfSquares(-320, 37),
      ].join();
      expect(_why(spreadSvg(script: script)), contains('too close'));
    });

    test('an ornament sits on no line', () {
      final svg = spreadSvg().replaceFirst(
        'translate(300 448)',
        'translate(300 300)',
      );
      expect(_why(svg), contains('is on no line'));
    });

    test('the page group turns or skews the page', () {
      final svg = spreadSvg().replaceFirst(
        'matrix(1 0 0 -1 0 550)',
        'matrix(1 0.2 0 -1 0 550)',
      );
      expect(_why(svg), 'no page matrix');
    });
  });

  test('a sign drawn with the first line but lying on another goes to the '
      'line it lies on', () {
    // The sign of the upper line is drawn straight before the lower line,
    // near its start, so the pen never returns between them.
    final script = [
      'm20 447h4v4h-4z',
      square(2, 0),
      square(2, 0),
      lineOfSquares(-14, -34),
      lineOfSquares(-320, 37),
    ].join();
    final layers = _split(spreadSvg(script: script))!;
    expect(layers.ink.shifts, [-98, -135, -98]);
  });

  test('the fixture of a real page layout is not spread: its script is not '
      'in a content group', () {
    expect(fixturePage(3).canSpread, isFalse);
  });
}
