import 'dart:math' as math;

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
  static const String _contentOpen = '<g id="content">';

  /// One path of the script, in its own transform group or bare.
  static final RegExp _scriptPath = RegExp(
    r'\s*(?:<g transform="((?:translate|matrix)\([^)]*\))">\s*)?'
    r'<path((?:\s+(?!d=)[\w:-]+="[^"]*")*)\s+d="([^"]*)"([^>]*?)/>'
    r'(\s*</g>)?',
  );
  static final RegExp _ornament = RegExp(
    r'class="ayah-mark-ornament" '
    r'transform="translate\(([-\d.]+)[ ,]([-\d.]+)\)',
  );
  static final RegExp _group = RegExp(r'<g\b[^>]*>|</g>');
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

  /// How much a doubtful contour's distance from a line's middle weighs
  /// against its distance from the line's nearest outline. Tuned against
  /// Hafs, whose lines the drawing order gives: 0.25 misplaces the fewest.
  static const double _middleWeight = 0.25;

  /// The two layers of a page with their lines held apart, or null when the
  /// lines cannot be told apart at all.
  ///
  /// [ink] and [marks] are the layers [SvgPageParser.split] produced, and
  /// [box] is the part of the page they show. A page whose drawing order
  /// leaves a few contours in doubt is split leniently: see [splitOrThrow].
  ///
  /// [ordered] says the Mushaf draws its script line by line, as Hafs and
  /// Warsh do. When it does not, every contour is placed by where it lies:
  /// see [splitOrThrow].
  static SvgSplit? split({
    required String ink,
    required String marks,
    required PageBox box,
    bool ordered = true,
  }) {
    // The surest way first: the drawing order, strictly, then leniently;
    // then where each contour lies.
    for (final (lenient, inOrder) in [
      if (ordered) ...[(false, true), (true, true)],
      (true, false),
    ]) {
      try {
        return splitOrThrow(
          ink: ink,
          marks: marks,
          box: box,
          lenient: lenient,
          ordered: inOrder,
        );
      } on SvgLinesUnclear {
        continue;
      }
    }
    return null;
  }

  /// As [split], but says why a page cannot be spread. For the checking
  /// tool; the app uses [split].
  ///
  /// When [lenient] is true, a contour the drawing order does not place
  /// beyond doubt is put on the nearer of the two lines it lies between:
  /// the one whose already placed outlines come closest to it. The script's
  /// own lines are still found from the drawing order.
  ///
  /// When [ordered] is false the drawing order says nothing, and the split
  /// is always lenient: the page's fifteen lines are found where its
  /// contours gather, each contour that lies on a line beyond doubt goes
  /// with it, and every other one goes with the nearer of its two lines.
  /// Checked against Hafs, whose lines the drawing order gives, this puts
  /// about three contours in ten thousand on the wrong line.
  static SvgSplit splitOrThrow({
    required String ink,
    required String marks,
    required PageBox box,
    bool lenient = false,
    bool ordered = true,
  }) {
    final matrix = _matrix(ink);
    final inkHead = _head(ink);
    final marksHead = _head(marks);
    if (matrix == null) throw const SvgLinesUnclear('no page matrix');
    if (inkHead == null || marksHead == null) {
      throw const SvgLinesUnclear('no view box');
    }
    final contentStart = ink.indexOf(_contentOpen);
    if (contentStart < 0) throw const SvgLinesUnclear('no script path');
    final contentEnd = _groupEnd(ink, contentStart);
    final paths = _scriptPaths(
      ink.substring(contentStart + _contentOpen.length, contentEnd - 4),
    );
    if (paths.isEmpty) throw const SvgLinesUnclear('no script path');
    // On the few pages whose script comes in many paths, the drawing order
    // no longer says where a line ends: each contour goes where it lies.
    if (paths.length > 1) ordered = false;
    if (!ordered) lenient = true;

    final contours = <_Contour>[];
    for (var item = 0; item < paths.length; item++) {
      final path = paths[item];
      final own = _PathScanner(path.d).contours();
      if (own == null || own.isEmpty) {
        throw const SvgLinesUnclear('unreadable path data');
      }
      for (final contour in own) {
        contour
          ..item = item
          ..toPage(
            xScale: matrix.a * path.place.a,
            xMove: matrix.a * path.place.e + matrix.e,
            yScale: matrix.d * path.place.d,
            yMove: matrix.d * path.place.f + matrix.f,
          );
      }
      contours.addAll(own);
    }
    final height = pageBoxHeight(box);
    final lineOf = _assign(
      contours,
      width: pageBoxWidth(box),
      height: height,
      top: box.top,
      lenient: lenient,
      ordered: ordered,
    );

    double shiftOf(_Line line) => (line.middle - box.top) / matrix.d;

    // The script: one path per piece, each inside its line's shift.
    final inkParts = <String>[];
    final inkShifts = <double>[];
    final piece = StringBuffer(ink.substring(inkHead.end, contentStart))
      ..write(_contentOpen);
    for (var first = 0; first < contours.length;) {
      // A piece: neighbours in drawing order, of one path, on one line.
      final item = contours[first].item;
      var end = first + 1;
      while (end < contours.length &&
          contours[end].item == item &&
          lineOf[end] == lineOf[first]) {
        end++;
      }
      final path = paths[item];
      final until = end < contours.length && contours[end].item == item
          ? contours[end].at
          : path.d.length;
      piece.write(_shiftOpen);
      inkParts.add(piece.toString());
      inkShifts.add(shiftOf(lineOf[first]));
      piece
        ..clear()
        ..write(_shiftClose)
        ..write('<g transform="${path.transform}"><path d="')
        ..write(_pathData(path.d, contours[first], until))
        ..write('"${path.attributes}/></g></g>');
      first = end;
    }
    piece
      ..write('</g>')
      ..write(ink.substring(contentEnd));
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
      if (!lenient && (line.middle - y).abs() > height * _reach) {
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
      lines: _printedLines(contours, lineOf),
    );
  }

  /// Each line of [lineOf], top first: its middle, and the box of its ink.
  static List<SvgPrintedLine> _printedLines(
    List<_Contour> contours,
    List<_Line> lineOf,
  ) {
    final boxes = <_Line, PageBox>{};
    for (var i = 0; i < contours.length; i++) {
      final c = contours[i];
      final known = boxes[lineOf[i]];
      boxes[lineOf[i]] = known == null
          ? (left: c.left, top: c.top, right: c.right, bottom: c.bottom)
          : (
              left: math.min(known.left, c.left),
              top: math.min(known.top, c.top),
              right: math.max(known.right, c.right),
              bottom: math.max(known.bottom, c.bottom),
            );
    }
    return [
      for (final MapEntry(key: line, value: box) in boxes.entries)
        (middle: line.middle, box: box),
    ]..sort((a, b) => a.middle.compareTo(b.middle));
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
    required double top,
    bool lenient = false,
    bool ordered = true,
  }) {
    if (!ordered) return _assignByPlace(contours, height: height, top: top);
    // Contours left in doubt, placed last when [lenient].
    final doubtful = <int>[];
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
    // Leniently, two runs closer than two lines can be are one line: the
    // halves of a surah title drawn across the page.
    final same = height * (lenient ? _apart : _same);
    for (final run in crossing) {
      final near = lines
          .where((line) => (line.middle - run.middle).abs() < same)
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
          if (lenient) {
            doubtful.add(i);
            continue;
          }
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
          if (lenient) {
            doubtful.addAll(band);
            continue;
          }
          throw SvgLinesUnclear(
            'loose contours from ${heights.first.toStringAsFixed(1)} to '
            '${heights.last.toStringAsFixed(1)} span more than a line',
          );
        }
        final middle = heights[heights.length ~/ 2];
        final near = added
            .where((line) => (line.middle - middle).abs() < same)
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
    if (lenient) _settle(all, contours, lineOf, height);
    // Contours drawn at a line's end that lie on no line: leniently, the
    // lines nothing else drew, such as a surah title drawn with its basmala.
    final homeless = <int>[];
    for (final i in strangers) {
      final y = contours[i].centreY;
      final line = all.isEmpty ? null : _nearest(all, y);
      if (line == null || (line.middle - y).abs() > height * _sure) {
        if (lenient) {
          homeless.add(i);
          continue;
        }
        throw SvgLinesUnclear(
          'a contour at ${y.toStringAsFixed(1)}, drawn at the end of a '
          'line, is on no line',
        );
      }
      lineOf[i] = line;
    }
    for (final band in _bands(homeless, contours, height)) {
      final middle = contours[band[band.length ~/ 2]].centreY;
      final near = all.isEmpty ? null : _nearest(all, middle);
      final line = near != null && (near.middle - middle).abs() < height * _same
          ? near
          : _addLine(all, middle);
      for (final i in band) {
        lineOf[i] = line;
      }
    }
    if (all.isEmpty) throw const SvgLinesUnclear('no line');
    all.sort((a, b) => a.middle.compareTo(b.middle));
    _placeDoubtful(doubtful, contours, all, lineOf);
    if (lenient) {
      _settle(all, contours, lineOf, height);
      // Once the lines sit where their contours are, a contour further from
      // its line than any mark reaches was drawn with a neighbouring line:
      // the vowels of a surah title drawn with its basmala.
      // Each round moves the lines a little; a few rounds settle them.
      for (var round = 0; round < 4; round++) {
        final strays = [
          for (var i = 0; i < contours.length; i++)
            if ((lineOf[i]!.middle - contours[i].centreY).abs() >
                height * _reach)
              i,
        ];
        final before = [for (final i in strays) lineOf[i]];
        for (final i in strays) {
          lineOf[i] = null;
        }
        _placeDoubtful(strays, contours, all, lineOf);
        _settle(all, contours, lineOf, height);
        var moved = false;
        for (var k = 0; k < strays.length; k++) {
          if (!identical(before[k], lineOf[strays[k]])) moved = true;
        }
        if (!moved) break;
      }
    }
    for (var i = 1; i < all.length; i++) {
      if (all[i].middle - all[i - 1].middle < height * _apart) {
        throw SvgLinesUnclear(
          'lines at ${all[i - 1].middle.toStringAsFixed(1)} and '
          '${all[i].middle.toStringAsFixed(1)} are too close',
        );
      }
    }
    // Leniently, a page whose drawing order found other than its printed
    // lines is better split by where its contours lie.
    if (lenient && all.length != SvgPageLayout.printedLines) {
      throw SvgLinesUnclear('${all.length} lines found leniently');
    }
    return [for (final line in lineOf) line!];
  }

  /// The line of every contour of a page whose drawing order says nothing:
  /// the printed page's fifteen lines, each moved to the median height of
  /// the contours near it; each contour within [_sure] of a line goes with
  /// it, and the rest are placed as [_placeDoubtful] does.
  static List<_Line> _assignByPlace(
    List<_Contour> contours, {
    required double height,
    required double top,
  }) {
    const printed = SvgPageLayout.printedLines;
    final pitch = height / printed;
    final all = [
      for (var k = 0; k < printed; k++) _Line(top + pitch * (k + 0.5)),
    ];
    // Twice: the second pass starts from where the first found the lines.
    for (var pass = 0; pass < 2; pass++) {
      for (final line in all) {
        final heights = [
          for (final contour in contours)
            if ((contour.centreY - line.middle).abs() < pitch * 0.3)
              contour.centreY,
        ]..sort();
        if (heights.length >= 5) line.middle = heights[heights.length ~/ 2];
      }
    }
    final lineOf = List<_Line?>.filled(contours.length, null);
    final doubtful = <int>[];
    for (var i = 0; i < contours.length; i++) {
      final line = _nearest(all, contours[i].centreY);
      if ((line.middle - contours[i].centreY).abs() <= height * _sure) {
        lineOf[i] = line;
      } else {
        doubtful.add(i);
      }
    }
    _placeDoubtful(doubtful, contours, all, lineOf);
    _placeTogether(doubtful, contours, all, lineOf);
    return [for (final line in lineOf) line!];
  }

  /// Puts the doubtful contours whose boxes overlap, the parts of one sign,
  /// on one line: a sign of [_signContours] or more parts on the line
  /// nearest its middle, a smaller group where most of its area went.
  static void _placeTogether(
    List<int> doubtful,
    List<_Contour> contours,
    List<_Line> all,
    List<_Line?> lineOf,
  ) {
    final parent = {for (final i in doubtful) i: i};
    int root(int i) {
      var at = i;
      while (parent[at] != at) {
        at = parent[at]!;
      }
      return at;
    }

    for (var a = 0; a < doubtful.length; a++) {
      final p = contours[doubtful[a]];
      for (var b = a + 1; b < doubtful.length; b++) {
        final q = contours[doubtful[b]];
        final overlap =
            p.left <= q.right &&
            q.left <= p.right &&
            p.top <= q.bottom &&
            q.top <= p.bottom;
        if (overlap) parent[root(doubtful[a])] = root(doubtful[b]);
      }
    }
    final groups = <int, List<int>>{};
    for (final i in doubtful) {
      groups.putIfAbsent(root(i), () => []).add(i);
    }
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final _Line line;
      if (group.length >= _signContours) {
        final middle =
            group.map((i) => contours[i].centreY).reduce((a, b) => a + b) /
            group.length;
        line = _nearest(all, middle);
      } else {
        final area = <_Line, double>{};
        for (final i in group) {
          final c = contours[i];
          area[lineOf[i]!] =
              (area[lineOf[i]!] ?? 0) + (c.right - c.left) * (c.bottom - c.top);
        }
        line = area.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }
      for (final i in group) {
        lineOf[i] = line;
      }
    }
  }

  /// Puts every line of [all] at the median height of the contours on it,
  /// then makes one line of any two closer than two lines can be: the parts
  /// of a surah title or a basmala that the drawing order split. [all] stays
  /// sorted from the top down.
  static void _settle(
    List<_Line> all,
    List<_Contour> contours,
    List<_Line?> lineOf,
    double height,
  ) {
    while (true) {
      final heights = <_Line, List<double>>{};
      for (var i = 0; i < contours.length; i++) {
        final line = lineOf[i];
        if (line != null) {
          heights.putIfAbsent(line, () => []).add(contours[i].centreY);
        }
      }
      for (final line in all) {
        final ys = heights[line];
        if (ys == null || ys.isEmpty) continue;
        ys.sort();
        line.middle = ys[ys.length ~/ 2];
      }
      all.sort((a, b) => a.middle.compareTo(b.middle));
      final at = [
        for (var i = 1; i < all.length; i++)
          if (all[i].middle - all[i - 1].middle < height * _apart) i,
      ].firstOrNull;
      if (at == null) return;
      final upper = all[at - 1];
      final lower = all[at];
      final keep =
          (heights[upper]?.length ?? 0) >= (heights[lower]?.length ?? 0)
          ? upper
          : lower;
      final gone = identical(keep, upper) ? lower : upper;
      all.remove(gone);
      for (var i = 0; i < lineOf.length; i++) {
        if (identical(lineOf[i], gone)) lineOf[i] = keep;
      }
    }
  }

  /// Puts each contour of [doubtful] on one of the two lines of [all] it
  /// lies between: the one whose placed outlines have a point nearest to
  /// the contour's middle, or simply the nearer line when neither has.
  static void _placeDoubtful(
    List<int> doubtful,
    List<_Contour> contours,
    List<_Line> all,
    List<_Line?> lineOf,
  ) {
    if (doubtful.isEmpty) return;
    final placed = <_Line, List<_Contour>>{};
    for (var i = 0; i < contours.length; i++) {
      final line = lineOf[i];
      if (line != null) placed.putIfAbsent(line, () => []).add(contours[i]);
    }
    // The clearest first: each placed contour then guides those near it,
    // such as a vowel drawn on a shadda.
    var left = [...doubtful];
    for (final margin in const [16.0, 4.0, 2.0, 0.0]) {
      final choices = <int, _Line>{};
      for (final i in left) {
        final contour = contours[i];
        final y = contour.centreY;
        var below = all.indexWhere((line) => line.middle >= y);
        if (below < 0) below = all.length - 1;
        final candidates = {all[below], all[below > 0 ? below - 1 : below]};
        var best = _nearest(candidates, y);
        var bestGap = double.infinity;
        var otherGap = double.infinity;
        for (final line in candidates) {
          var gap = double.infinity;
          for (final other in placed[line] ?? const <_Contour>[]) {
            final g = contour.gapTo(other);
            if (g < gap) gap = g;
          }
          if (gap.isFinite) {
            // How far the contour is from the line's middle counts too: a
            // pause sign over a word can come closer to the tail of a
            // letter on the line above than to its own word.
            final score =
                math.sqrt(gap) +
                _middleWeight * (contour.centreY - line.middle).abs();
            gap = score * score;
          }
          if (gap < bestGap) {
            otherGap = bestGap;
            bestGap = gap;
            best = line;
          } else if (gap < otherGap) {
            otherGap = gap;
          }
        }
        if (margin == 0 || otherGap >= bestGap * margin) choices[i] = best;
      }
      for (final MapEntry(key: i, value: line) in choices.entries) {
        lineOf[i] = line;
        placed.putIfAbsent(line, () => []).add(contours[i]);
      }
      left = [
        for (final i in left)
          if (!choices.containsKey(i)) i,
      ];
      if (left.isEmpty) break;
    }
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

  /// The path data from contour [head] up to index [until] of [d]: the
  /// original text, with only the opening move rewritten as an absolute
  /// one, as the path's earlier contours are no longer before it.
  static String _pathData(String d, _Contour head, int until) {
    final body = d.substring(head.bodyAt, until);
    // Coordinates straight after a move are a line; keep them one.
    final follows = body.trimLeft();
    final bare =
        follows.isNotEmpty && !_PathScanner.isCommand(follows.codeUnitAt(0));
    final line = bare ? (head.relative ? 'l' : 'L') : '';
    return 'M${head.startX} ${head.startY}$line$body';
  }

  /// The paths of the script in [inside], the content group's text: each
  /// with its transform (none for a bare path), data and other attributes.
  /// Empty when the group holds anything else.
  static List<_ScriptPath> _scriptPaths(String inside) {
    final paths = <_ScriptPath>[];
    var at = 0;
    while (at < inside.length) {
      final match = _scriptPath.matchAsPrefix(inside, at);
      if (match == null) {
        return inside.substring(at).trim().isEmpty ? paths : const [];
      }
      final transform = match.group(1);
      // A group opened is closed, and none is closed unopened.
      if ((transform != null) != (match.group(5) != null)) return const [];
      final place = transform == null
          ? (a: 1.0, d: 1.0, e: 0.0, f: 0.0)
          : _placement(transform);
      if (place == null) return const [];
      paths.add((
        transform: transform ?? 'translate(0 0)',
        place: place,
        d: match.group(3)!,
        attributes: '${match.group(4)!}${match.group(2)!}',
      ));
      at = match.end;
    }
    return paths;
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

  /// What `translate(x y)` or a `matrix(…)` that only scales and moves
  /// does, as `x' = a·x + e`, `y' = d·y + f`; null for anything else.
  static ({double a, double d, double e, double f})? _placement(
    String transform,
  ) {
    final open = transform.indexOf('(');
    final values = [
      for (final value
          in transform
              .substring(open + 1, transform.length - 1)
              .trim()
              .split(RegExp(r'[\s,]+')))
        double.tryParse(value),
    ];
    if (values.contains(null)) return null;
    if (transform.startsWith('translate')) {
      if (values.length != 2) return null;
      return (a: 1, d: 1, e: values[0]!, f: values[1]!);
    }
    if (values.length != 6 || values[1] != 0 || values[2] != 0) return null;
    return (a: values[0]!, d: values[3]!, e: values[4]!, f: values[5]!);
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

  static _Line _addLine(List<_Line> all, double middle) {
    final line = _Line(middle);
    all.add(line);
    return line;
  }

  static _Line _nearest(Iterable<_Line> lines, double y) => lines.reduce(
    (a, b) => (a.middle - y).abs() <= (b.middle - y).abs() ? a : b,
  );

  /// Index just past the `</g>` that closes the group opening at [start].
  static int _groupEnd(String svg, int start) {
    var depth = 0;
    for (final match in _group.allMatches(svg, start)) {
      final tag = match.group(0)!;
      // An empty group closes itself; it opens nothing.
      if (tag.endsWith('/>')) continue;
      if (tag == '</g>') {
        depth--;
        if (depth == 0) return match.end;
      } else {
        depth++;
      }
    }
    throw const SvgLinesUnclear('a group never closes');
  }
}

/// A page split into its printed lines: its two layers, each ready to be
/// spread, and the lines themselves.
typedef SvgSplit = ({
  SvgSpreadLayer ink,
  SvgSpreadLayer marks,
  List<SvgPrintedLine> lines,
});

/// One path of a page's script: the transform of its group, what that
/// transform does, its data, and its other attributes.
typedef _ScriptPath = ({
  String transform,
  ({double a, double d, double e, double f}) place,
  String d,
  String attributes,
});

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

  /// Which of the script's paths the contour is in.
  int item = 0;

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

  /// Every point the outline passes or bends towards, as x, y pairs: in
  /// path units while the path is read, in page units after [toPage].
  final List<double> points = [];

  /// The contour's box in page units, top above bottom, set by [toPage].
  double left = 0;
  double right = 0;
  double top = 0;
  double bottom = 0;

  /// Moves the contour's middle, box and points into page units:
  /// `x' = xScale·x + xMove`, `y' = yScale·y + yMove`.
  void toPage({
    required double xScale,
    required double xMove,
    required double yScale,
    required double yMove,
  }) {
    final x0 = xScale * minX + xMove;
    final x1 = xScale * maxX + xMove;
    final y0 = yScale * minY + yMove;
    final y1 = yScale * maxY + yMove;
    left = math.min(x0, x1);
    right = math.max(x0, x1);
    top = math.min(y0, y1);
    bottom = math.max(y0, y1);
    centreX = (left + right) / 2;
    centreY = (top + bottom) / 2;
    for (var i = 0; i < points.length; i += 2) {
      points[i] = xScale * points[i] + xMove;
      points[i + 1] = yScale * points[i + 1] + yMove;
    }
  }

  /// The middle of the contour's box, in page units.
  double centreX = 0;
  double centreY = 0;

  void include(double x, double y) {
    points
      ..add(x)
      ..add(y);
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
}

extension on _Contour {
  /// Squared distance, in page units, from this contour's middle to the
  /// nearest point of [other].
  double gapTo(_Contour other) {
    final x = centreX;
    final y = centreY;
    var best = double.infinity;
    for (var i = 0; i < other.points.length; i += 2) {
      final dx = other.points[i] - x;
      final dy = other.points[i + 1] - y;
      final d = dx * dx + dy * dy;
      if (d < best) best = d;
    }
    return best;
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

  /// Moves only while a lenient split settles its lines.
  double middle;
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
