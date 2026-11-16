import '../domain/svg_page.dart';

/// Tells the printed lines of a quran-svg page apart, so they can be moved
/// further from each other without touching a glyph.
///
/// A page's script is one long path. The splitter cuts the path only between
/// two whole contours, and gives every printed line its own vertical shift.
/// No contour is cut, scaled, reordered or redrawn.
///
/// Whenever anything about a page is not as expected, the page is left as it
/// ships, unspread. The checks are listed in `docs/QURAN_SOURCES.md`,
/// section 14, and `tool/check_svg_lines.dart` runs them over every page.
abstract final class SvgLineSplitter {
  static final RegExp _rootMatrix = RegExp(r'<g transform="matrix\(([^)]*)\)"');
  static final RegExp _content = RegExp(
    r'<g id="content"><g transform="translate\(([-\d.]+)[ ,]([-\d.]+)\)">'
    r'<path d="([^"]*)"([^>]*?)/></g></g>',
  );
  static final RegExp _ornament = RegExp(
    r'class="ayah-mark-ornament" '
    r'transform="translate\(([-\d.]+)[ ,]([-\d.]+)\)',
  );
  static final RegExp _group = RegExp(r'<g\b|</g>');
  static const String _viewBoxOpen = 'viewBox="';
  static const String _markOpen = '<g class="ayah-mark">';
  static const String _shiftOpen = '<g transform="translate(0 ';
  static const String _shiftClose = ')">';

  // The shares below are of the page's width or height. A page has 15
  // lines, so one line is about 0.067 of its height.

  /// A jump this wide between two contours is the pen going back to start a
  /// new line. Words are narrower.
  static const double _lineReturn = 0.4;

  /// A jump this tall between two contours is a different line: more than a
  /// line and a half.
  static const double _lineSkip = 0.1;

  /// A contour within this of a line's middle is on that line beyond doubt:
  /// a third of a line, where the next line's middle is a whole line away.
  static const double _sure = 0.022;

  /// A contour of a line's own run may lie this far from the line's middle:
  /// the reach of the marks above and below the letters.
  static const double _reach = 0.04;

  /// Inside a line's run, a contour further than this from the line's
  /// middle is nearer to the next line than any mark reaches.
  static const double _far = 0.05;

  /// A sign drawn apart sits within this of its line's middle. Across the
  /// whole Mushaf such signs lie from 0.009 above it to 0.024 below, and
  /// nothing else drawn apart lies nearer than 0.058.
  static const double _near = 0.03;

  /// A pause sign has at least this many contours. A band with fewer is
  /// placed only where it lies on a line beyond doubt.
  static const int _signContours = 3;

  /// A gap this tall between contour middles separates two bands: more
  /// than a mark is from its letter, less than a sign is from the sign on
  /// the next line.
  static const double _gap = 0.025;

  /// The contour middles of one band span at most this much.
  static const double _band = 0.055;

  /// Two line middles closer than this are one line drawn in two goes.
  static const double _same = 0.035;

  /// Two different lines' middles are at least this far apart.
  static const double _apart = 0.045;

  /// The contour middles of one line span at most this much.
  static const double _tall = 0.075;

  /// The two layers of a page with their lines held apart, or null when the
  /// lines cannot be told apart with certainty.
  ///
  /// [ink] and [marks] are the layers [SvgPageParser.split] produced, and
  /// [box] is the part of the page they show.
  static ({SvgSpreadLayer ink, SvgSpreadLayer marks})? split({
    required String ink,
    required String marks,
    required PageBox box,
  }) {
    try {
      return splitOrThrow(ink: ink, marks: marks, box: box);
    } on SvgLinesUnclear {
      return null;
    }
  }

  /// As [split], but says why a page cannot be spread. For the checking
  /// tool; the app uses [split].
  static ({SvgSpreadLayer ink, SvgSpreadLayer marks}) splitOrThrow({
    required String ink,
    required String marks,
    required PageBox box,
  }) {
    final matrix = _matrix(ink);
    final content = _content.firstMatch(ink);
    final inkHead = _head(ink);
    final marksHead = _head(marks);
    if (matrix == null) throw const SvgLinesUnclear('no page matrix');
    if (content == null) throw const SvgLinesUnclear('no script path');
    if (inkHead == null || marksHead == null) {
      throw const SvgLinesUnclear('no view box');
    }
    // Exactly one path of script: on the few pages that ship it in pieces,
    // the drawing order no longer says where a line ends.
    if ('<path '.allMatches(ink).length != 1) {
      throw const SvgLinesUnclear('script in more than one path');
    }
    final tx = double.parse(content.group(1)!);
    final ty = double.parse(content.group(2)!);
    final d = content.group(3)!;
    final attributes = content.group(4)!;

    final contours = _PathScanner(d).contours();
    if (contours == null || contours.isEmpty) {
      throw const SvgLinesUnclear('unreadable path data');
    }
    for (final contour in contours) {
      contour
        ..centreX =
            matrix.a * ((contour.minX + contour.maxX) / 2 + tx) + matrix.e
        ..centreY =
            matrix.d * ((contour.minY + contour.maxY) / 2 + ty) + matrix.f;
    }
    final height = pageBoxHeight(box);
    final lineOf = _assign(contours, width: pageBoxWidth(box), height: height);

    double shiftOf(_Line line) => (line.middle - box.top) / matrix.d;

    // The script: one path per piece, each inside its line's shift.
    final inkParts = <String>[];
    final inkShifts = <double>[];
    final piece = StringBuffer(ink.substring(inkHead.end, content.start))
      ..write('<g id="content">');
    for (var first = 0; first < contours.length;) {
      // A piece: neighbours in drawing order that sit on one line.
      var end = first + 1;
      while (end < contours.length && lineOf[end] == lineOf[first]) {
        end++;
      }
      piece.write(_shiftOpen);
      inkParts.add(piece.toString());
      inkShifts.add(shiftOf(lineOf[first]));
      piece
        ..clear()
        ..write(_shiftClose)
        ..write('<g transform="translate($tx $ty)"><path d="')
        ..write(_pathData(d, contours, first, end))
        ..write('"$attributes/></g></g>');
      first = end;
    }
    piece
      ..write('</g>')
      ..write(ink.substring(content.end));
    inkParts.add(piece.toString());

    // The ornaments: each inside the shift of the line it sits on.
    final lines = lineOf.toSet();
    final marksParts = <String>[];
    final marksShifts = <double>[];
    var cursor = marksHead.end;
    piece.clear();
    for (
      var at = marks.indexOf(_markOpen, cursor);
      at >= 0;
      at = marks.indexOf(_markOpen, cursor)
    ) {
      final end = _groupEnd(marks, at);
      final ornament = _ornament.firstMatch(marks.substring(at, end));
      if (ornament == null) {
        throw const SvgLinesUnclear('ornament without a place');
      }
      final y = matrix.d * double.parse(ornament.group(2)!) + matrix.f;
      final line = _nearest(lines, y);
      if ((line.middle - y).abs() > height * _reach) {
        throw SvgLinesUnclear(
          'ornament at ${y.toStringAsFixed(1)} is on no line',
        );
      }
      piece
        ..write(marks.substring(cursor, at))
        ..write(_shiftOpen);
      marksParts.add(piece.toString());
      marksShifts.add(shiftOf(line));
      piece
        ..clear()
        ..write(_shiftClose)
        ..write(marks.substring(at, end))
        ..write('</g>');
      cursor = end;
    }
    piece.write(marks.substring(cursor));
    marksParts.add(piece.toString());

    return (
      ink: SvgSpreadLayer(
        head: inkHead.text,
        box: box,
        parts: inkParts,
        shifts: inkShifts,
      ),
      marks: SvgSpreadLayer(
        head: marksHead.text,
        box: box,
        parts: marksParts,
        shifts: marksShifts,
      ),
    );
  }

  /// The printed line of every contour, in drawing order.
  ///
  /// The script's own lines are drawn one after another, each from edge to
  /// edge, so the pen's return finds them. Signs from other fonts (pause
  /// marks, a basmala, a surah title) are drawn apart from their lines; each
  /// such contour is placed by where it lies, and only when that leaves no
  /// doubt.
  static List<_Line> _assign(
    List<_Contour> contours, {
    required double width,
    required double height,
  }) {
    final runs = <_Run>[];
    var first = 0;
    for (var i = 1; i <= contours.length; i++) {
      final ends =
          i == contours.length ||
          (contours[i].centreX - contours[i - 1].centreX).abs() >
              width * _lineReturn ||
          (contours[i].centreY - contours[i - 1].centreY).abs() >
              height * _lineSkip;
      if (!ends) continue;
      runs.add(_Run(contours, first, i));
      first = i;
    }

    // Lines of the script: the runs that cross the page.
    final lines = <_Line>[];
    final crossing = [
      for (final run in runs)
        if (run.span > width * _lineReturn) run,
    ]..sort((a, b) => b.length.compareTo(a.length));
    for (final run in crossing) {
      final near = lines
          .where((line) => (line.middle - run.middle).abs() < height * _same)
          .firstOrNull;
      run.line = near ?? _Line(run.middle);
      if (near == null) lines.add(run.line!);
    }

    final lineOf = List<_Line?>.filled(contours.length, null);
    final loose = <_Run>[];
    // Contours drawn at either end of a line's run but lying off it: signs
    // of a neighbouring line that the pen drew on its way.
    final strangers = <int>[];
    for (final run in runs) {
      final own = run.line;
      if (own == null) {
        if (!_placeApart(run, contours, lines, lineOf, height)) loose.add(run);
        continue;
      }
      bool off(int i) =>
          (own.middle - contours[i].centreY).abs() > height * _reach;
      var head = run.first;
      while (head < run.end && off(head)) {
        strangers.add(head++);
      }
      var tail = run.end;
      while (tail > head && off(tail - 1)) {
        strangers.add(--tail);
      }
      for (var i = head; i < tail; i++) {
        // Inside the run the drawing order vouches for the contour; only a
        // contour nearer to the next line than a mark can reach is refused.
        final y = contours[i].centreY;
        if ((own.middle - y).abs() > height * _far) {
          throw SvgLinesUnclear(
            'a contour at ${y.toStringAsFixed(1)}, drawn inside the line at '
            '${own.middle.toStringAsFixed(1)}, is too far from it',
          );
        }
        lineOf[i] = own;
      }
    }

    // What is left stands on lines the script did not draw: a basmala or a
    // surah title. Each band of it is one line.
    final added = <_Line>[];
    loose.sort((a, b) => b.length.compareTo(a.length));
    for (final run in loose) {
      final left = [
        for (var i = run.first; i < run.end; i++)
          if (lineOf[i] == null) i,
      ];
      for (final band in _bands(left, contours, height)) {
        final heights = [for (final i in band) contours[i].centreY];
        if (heights.last - heights.first > height * _tall) {
          throw SvgLinesUnclear(
            'loose contours from ${heights.first.toStringAsFixed(1)} to '
            '${heights.last.toStringAsFixed(1)} span more than a line',
          );
        }
        final middle = heights[heights.length ~/ 2];
        final near = added
            .where((line) => (line.middle - middle).abs() < height * _same)
            .firstOrNull;
        final line = near ?? _Line(middle);
        if (near == null) added.add(line);
        for (final i in band) {
          lineOf[i] = line;
        }
      }
    }

    final all = [...lines, ...added]
      ..sort((a, b) => a.middle.compareTo(b.middle));
    for (final i in strangers) {
      final y = contours[i].centreY;
      final line = _nearest(all, y);
      if ((line.middle - y).abs() > height * _sure) {
        throw SvgLinesUnclear(
          'a contour at ${y.toStringAsFixed(1)}, drawn at the end of a '
          'line, is on no line',
        );
      }
      lineOf[i] = line;
    }
    for (var i = 1; i < all.length; i++) {
      if (all[i].middle - all[i - 1].middle < height * _apart) {
        throw SvgLinesUnclear(
          'lines at ${all[i - 1].middle.toStringAsFixed(1)} and '
          '${all[i].middle.toStringAsFixed(1)} are too close',
        );
      }
    }
    return [for (final line in lineOf) line!];
  }

  /// Places the contours of [run], which was drawn apart from the script's
  /// lines, on those lines. Returns false when some of them stand on no
  /// line of the script.
  ///
  /// Such a run is a pause sign or two, or a few words set in another font.
  /// Its contours fall into bands by height. The largest band is on the
  /// line it lies on; a smaller band within a mark's reach of that line was
  /// drawn with it and is on it too; any other band is a sign of another
  /// line, and must lie on that line beyond doubt.
  static bool _placeApart(
    _Run run,
    List<_Contour> contours,
    List<_Line> lines,
    List<_Line?> lineOf,
    double height,
  ) {
    if (lines.isEmpty) return false;
    final bands = _bands(
      [for (var i = run.first; i < run.end; i++) i],
      contours,
      height,
    )..sort((a, b) => b.length.compareTo(a.length));
    double middleOf(List<int> band) => contours[band[band.length ~/ 2]].centreY;
    double extentOf(List<int> band) =>
        contours[band.last].centreY - contours[band.first].centreY;

    _Line? lineOn(List<int> band, double within) {
      final line = _nearest(lines, middleOf(band));
      final on =
          (line.middle - middleOf(band)).abs() <= height * within &&
          extentOf(band) <= height * _band;
      return on ? line : null;
    }

    final main = lineOn(bands.first, _near);
    var placed = true;
    for (final band in bands) {
      final _Line? line;
      if (identical(band, bands.first)) {
        line = main;
      } else if (main != null &&
          (main.middle - middleOf(band)).abs() <= height * _far &&
          (main.middle - contours[band.first].centreY).abs() <= height * _far &&
          (main.middle - contours[band.last].centreY).abs() <= height * _far) {
        line = main;
      } else {
        line = lineOn(band, band.length >= _signContours ? _near : _sure);
      }
      if (line == null) {
        placed = false;
        continue;
      }
      for (final i in band) {
        lineOf[i] = line;
      }
    }
    return placed;
  }

  /// [indices] grouped into bands of height: sorted by their contour's
  /// middle and cut wherever two neighbours are further apart than a mark
  /// is from its letter. Each band is sorted from the top down.
  static List<List<int>> _bands(
    List<int> indices,
    List<_Contour> contours,
    double height,
  ) {
    if (indices.isEmpty) return [];
    final sorted = [...indices]
      ..sort((a, b) => contours[a].centreY.compareTo(contours[b].centreY));
    final bands = [
      [sorted.first],
    ];
    for (var i = 1; i < sorted.length; i++) {
      final gap = contours[sorted[i]].centreY - contours[sorted[i - 1]].centreY;
      if (gap > height * _gap) bands.add([]);
      bands.last.add(sorted[i]);
    }
    return bands;
  }

  /// The path data of contours `[first, end)`: the original text from the
  /// first contour to the last, with only the opening move rewritten as an
  /// absolute one, as the path's earlier contours are no longer before it.
  static String _pathData(
    String d,
    List<_Contour> contours,
    int first,
    int end,
  ) {
    final head = contours[first];
    final until = end < contours.length ? contours[end].at : d.length;
    final body = d.substring(head.bodyAt, until);
    // Coordinates straight after a move are a line; keep them one.
    final follows = body.trimLeft();
    final bare =
        follows.isNotEmpty && !_PathScanner.isCommand(follows.codeUnitAt(0));
    final line = bare ? (head.relative ? 'l' : 'L') : '';
    return 'M${head.startX} ${head.startY}$line$body';
  }

  /// The document up to and including `viewBox="`, and where the text after
  /// the view box's value begins.
  static ({String text, int end})? _head(String svg) {
    final open = svg.indexOf(_viewBoxOpen);
    if (open < 0) return null;
    final valueEnd = svg.indexOf('"', open + _viewBoxOpen.length);
    if (valueEnd < 0) return null;
    return (text: svg.substring(0, open + _viewBoxOpen.length), end: valueEnd);
  }

  /// The page group's matrix, when it only scales and moves the page.
  static ({double a, double d, double e, double f})? _matrix(String svg) {
    final match = _rootMatrix.firstMatch(svg);
    if (match == null) return null;
    final values = [
      for (final value in match.group(1)!.trim().split(RegExp(r'[\s,]+')))
        double.tryParse(value),
    ];
    if (values.length != 6 || values.contains(null)) return null;
    if (values[1] != 0 || values[2] != 0 || values[3] == 0) return null;
    return (a: values[0]!, d: values[3]!, e: values[4]!, f: values[5]!);
  }

  static _Line _nearest(Iterable<_Line> lines, double y) => lines.reduce(
    (a, b) => (a.middle - y).abs() <= (b.middle - y).abs() ? a : b,
  );

  /// Index just past the `</g>` that closes the group opening at [start].
  static int _groupEnd(String svg, int start) {
    var depth = 0;
    for (final match in _group.allMatches(svg, start)) {
      if (match.group(0) == '</g>') {
        depth--;
        if (depth == 0) return match.end;
      } else {
        depth++;
      }
    }
    throw const SvgLinesUnclear('ornament group never closes');
  }
}

/// Why a page's lines could not be told apart.
class SvgLinesUnclear implements Exception {
  /// Creates the exception with its [reason].
  const SvgLinesUnclear(this.reason);

  /// What was not as expected.
  final String reason;

  @override
  String toString() => 'SvgLinesUnclear: $reason';
}

/// One outline of the script path.
class _Contour {
  _Contour({
    required this.at,
    required this.bodyAt,
    required this.relative,
    required this.startX,
    required this.startY,
  }) : minX = startX,
       maxX = startX,
       minY = startY,
       maxY = startY;

  /// Index of the contour's move command in the path data.
  final int at;

  /// Index just past the move's own coordinate pair.
  final int bodyAt;

  /// Whether coordinates that follow the move without a command of their
  /// own are relative.
  final bool relative;

  /// Where the contour starts, in path units.
  final double startX;
  final double startY;

  double minX;
  double maxX;
  double minY;
  double maxY;

  /// The middle of the contour's box, in page units.
  double centreX = 0;
  double centreY = 0;

  void include(double x, double y) {
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
}

/// Contours `[first, end)`, drawn one after another without the pen leaving
/// the line.
class _Run {
  _Run(List<_Contour> contours, this.first, this.end) {
    final heights = [for (var i = first; i < end; i++) contours[i].centreY]
      ..sort();
    middle = heights[heights.length ~/ 2];
    var left = double.infinity;
    var right = double.negativeInfinity;
    for (var i = first; i < end; i++) {
      final x = contours[i].centreX;
      if (x < left) left = x;
      if (x > right) right = x;
    }
    span = right - left;
  }

  final int first;
  final int end;

  /// Median height of the contours' middles, in page units.
  late final double middle;

  /// How much of the page's width the contours' middles cover.
  late final double span;

  /// The script line this run drew, when it crosses the page.
  _Line? line;

  int get length => end - first;
}

/// A printed line, known by the height of its middle in page units.
class _Line {
  _Line(this.middle);

  final double middle;
}

/// Reads SVG path data into contours, tracking the pen.
class _PathScanner {
  _PathScanner(this.d);

  final String d;
  int _i = 0;

  static bool isCommand(int unit) {
    final lower = unit | 0x20;
    // 'e' is an exponent, never a command.
    return lower >= 0x61 && lower <= 0x7a && lower != 0x65;
  }

  static int? _arity(int lower) => switch (lower) {
    0x6d || 0x6c || 0x74 => 2, // m l t
    0x68 || 0x76 => 1, // h v
    0x63 => 6, // c
    0x73 || 0x71 => 4, // s q
    _ => null,
  };

  /// The contours of the path, or null when it uses anything this scanner
  /// does not read exactly.
  List<_Contour>? contours() {
    final out = <_Contour>[];
    final args = List<double>.filled(6, 0);
    var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
    var command = 0;
    var commandAt = -1;
    while (true) {
      _skipSeparators();
      if (_i >= d.length) break;
      final unit = d.codeUnitAt(_i);
      if (isCommand(unit)) {
        command = unit;
        commandAt = _i++;
        if (unit | 0x20 == 0x7a) {
          // z: back to where the contour began.
          x = startX;
          y = startY;
          command = 0;
        }
        continue;
      }
      final lower = command | 0x20;
      final arity = _arity(lower);
      if (arity == null) return null;
      for (var j = 0; j < arity; j++) {
        _skipSeparators();
        final value = _number();
        if (value == null) return null;
        args[j] = value;
      }
      final relative = command == lower;
      switch (lower) {
        case 0x6d: // m
          x = relative ? x + args[0] : args[0];
          y = relative ? y + args[1] : args[1];
          startX = x;
          startY = y;
          out.add(
            _Contour(
              at: commandAt,
              bodyAt: _i,
              relative: relative,
              startX: x,
              startY: y,
            ),
          );
          // Pairs that follow a move are lines.
          command = relative ? 0x6c : 0x4c;
        case 0x68: // h
          if (out.isEmpty) return null;
          x = relative ? x + args[0] : args[0];
          out.last.include(x, y);
        case 0x76: // v
          if (out.isEmpty) return null;
          y = relative ? y + args[0] : args[0];
          out.last.include(x, y);
        default:
          if (out.isEmpty) return null;
          var px = x, py = y;
          for (var j = 0; j < arity; j += 2) {
            px = relative ? x + args[j] : args[j];
            py = relative ? y + args[j + 1] : args[j + 1];
            out.last.include(px, py);
          }
          x = px;
          y = py;
      }
    }
    return out;
  }

  void _skipSeparators() {
    while (_i < d.length) {
      final unit = d.codeUnitAt(_i);
      if (unit != 0x20 &&
          unit != 0x2c &&
          unit != 0x0a &&
          unit != 0x09 &&
          unit != 0x0d) {
        break;
      }
      _i++;
    }
  }

  /// Reads one number: sign, digits, fraction, exponent.
  double? _number() {
    final start = _i;
    if (_at(0x2d) || _at(0x2b)) _i++;
    _digits();
    if (_at(0x2e)) {
      _i++;
      _digits();
    }
    if (_i < d.length && (d.codeUnitAt(_i) | 0x20) == 0x65) {
      final mark = _i++;
      if (_at(0x2d) || _at(0x2b)) _i++;
      final before = _i;
      _digits();
      if (_i == before) _i = mark;
    }
    return _i == start ? null : double.tryParse(d.substring(start, _i));
  }

  bool _at(int unit) => _i < d.length && d.codeUnitAt(_i) == unit;

  void _digits() {
    while (_i < d.length) {
      final unit = d.codeUnitAt(_i);
      if (unit < 0x30 || unit > 0x39) break;
      _i++;
    }
  }
}
