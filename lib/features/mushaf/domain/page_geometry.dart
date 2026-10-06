import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// Raw RGBA pixels of a page image.
@immutable
class InkImage {
  /// Wraps [rgba], [width] by [height] pixels, four bytes each.
  const InkImage({
    required this.width,
    required this.height,
    required this.rgba,
  });

  /// Width in pixels.
  final int width;

  /// Height in pixels.
  final int height;

  /// Pixels, row by row, four bytes (RGBA) each.
  final Uint8List rgba;
}

/// Where one word sits on the page image, in fractions of its size.
@immutable
class WordBox {
  /// Creates a box.
  const WordBox({
    required this.ayah,
    required this.word,
    required this.line,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// The word's ayah.
  final AyahRef ayah;

  /// Position of the word in its ayah, 1-based.
  final int word;

  /// Line index on the page, 0-based.
  final int line;

  /// Left edge, 0–1.
  final double left;

  /// Top edge, 0–1.
  final double top;

  /// Right edge, 0–1.
  final double right;

  /// Bottom edge, 0–1.
  final double bottom;

  /// Whether the fractional point is inside the box.
  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;
}

/// A fractional rectangle, 0–1 on both axes.
typedef FractionRect = ({double left, double top, double right, double bottom});

/// Word positions on one page image.
@immutable
class PageGeometry {
  /// Creates geometry from [words] and the page's ink extent.
  const PageGeometry({
    required this.words,
    this.inkTop = 0,
    this.inkBottom = 1,
    this.lineCuts = const [],
  });

  /// Every word on the page.
  final List<WordBox> words;

  /// Top of the topmost ink on the page, 0–1.
  final double inkTop;

  /// Bottom of the lowest ink on the page, 0–1.
  final double inkBottom;

  /// Top of every line row of the page, then the bottom of the last, as
  /// fractions of the image height; empty when the rows are not known.
  final List<double> lineCuts;

  /// The area of [ayah] on the page: one rectangle per line it covers.
  List<FractionRect> rectsOf(AyahRef ayah) {
    final byLine = <int, FractionRect>{};
    for (final box in words) {
      if (box.ayah != ayah) continue;
      final current = byLine[box.line];
      byLine[box.line] = current == null
          ? (left: box.left, top: box.top, right: box.right, bottom: box.bottom)
          : (
              left: math.min(current.left, box.left),
              top: math.min(current.top, box.top),
              right: math.max(current.right, box.right),
              bottom: math.max(current.bottom, box.bottom),
            );
    }
    final lines = byLine.keys.toList()..sort();
    return [for (final line in lines) byLine[line]!];
  }

  /// The ayah under the fractional point, or null.
  ///
  /// Fingers are wider than the gaps in the script: a press between two
  /// lines picks the nearer line, and a press between words, or beside the
  /// end of a line, picks the nearest word on that line. A press far from
  /// any word finds nothing.
  AyahRef? ayahAt(double x, double y) {
    int? line;
    var lineDistance = double.infinity;
    for (final box in words) {
      final dy = y < box.top
          ? box.top - y
          : y > box.bottom
          ? y - box.bottom
          : 0.0;
      if (dy < lineDistance) {
        lineDistance = dy;
        line = box.line;
      }
    }
    if (line == null || lineDistance > _lineReach) return null;
    WordBox? nearest;
    var distance = double.infinity;
    for (final box in words) {
      if (box.line != line) continue;
      final dx = x < box.left
          ? box.left - x
          : x > box.right
          ? x - box.right
          : 0.0;
      if (dx < distance) {
        distance = dx;
        nearest = box;
      }
    }
    return distance <= _wordReach ? nearest?.ayah : null;
  }

  /// How far above or below a line a press still selects it, as a fraction
  /// of the page height.
  static const double _lineReach = 0.025;

  /// How far beside a word a press still selects it, as a fraction of the
  /// page width.
  static const double _wordReach = 0.04;
}

/// Line rows on a printed Madinah page: 15, except the two opening pages.
int printedLinesOnPage(int page) => page <= 2 ? 8 : 15;

/// A glyph's box from a page's glyph database, in image pixels.
typedef GlyphBox = ({
  AyahRef ayah,
  int position,
  int line,
  int minX,
  int maxX,
  int minY,
  int maxY,
});

/// Geometry of a page from its glyph database, for an image of [width] by
/// [height] pixels and [lines] rows.
///
/// Every glyph on a line gets the line's full height, so a press anywhere in
/// the line's band finds a word. Some rows have their edges swapped; they are
/// read either way round.
PageGeometry glyphGeometry(
  List<GlyphBox> glyphs, {
  required int width,
  required int height,
  required int lines,
}) {
  if (glyphs.isEmpty) return const PageGeometry(words: []);
  final bands = <int, (int, int)>{};
  for (final glyph in glyphs) {
    final top = math.min(glyph.minY, glyph.maxY);
    final bottom = math.max(glyph.minY, glyph.maxY);
    final band = bands[glyph.line];
    bands[glyph.line] = band == null
        ? (top, bottom)
        : (math.min(band.$1, top), math.max(band.$2, bottom));
  }
  var inkTop = height;
  var inkBottom = 0;
  final boxes = <WordBox>[];
  for (final glyph in glyphs) {
    final (top, bottom) = bands[glyph.line]!;
    inkTop = math.min(inkTop, top);
    inkBottom = math.max(inkBottom, bottom);
    boxes.add(
      WordBox(
        ayah: glyph.ayah,
        word: glyph.position,
        line: glyph.line,
        left: math.min(glyph.minX, glyph.maxX) / width,
        right: math.max(glyph.minX, glyph.maxX) / width,
        top: top / height,
        bottom: bottom / height,
      ),
    );
  }
  return PageGeometry(
    words: List.unmodifiable(boxes),
    inkTop: inkTop / height,
    inkBottom: inkBottom / height,
    lineCuts: _rowsFromBands(bands, lines, height),
  );
}

/// Row edges of a page with [lines] equal rows, from the bands of the rows
/// that hold text; title and basmala rows have no glyphs of their own.
List<double> _rowsFromBands(Map<int, (int, int)> bands, int lines, int height) {
  final numbers = bands.keys.toList()..sort();
  final first = numbers.first;
  final last = numbers.last;
  if (last == first || last > lines) return const [];
  double centre(int line) => (bands[line]!.$1 + bands[line]!.$2) / 2;
  final pitch = (centre(last) - centre(first)) / (last - first);
  final top = centre(first) - (first - 0.5) * pitch;
  return [
    for (var row = 0; row <= lines; row++)
      ((top + row * pitch) / height).clamp(0.0, 1.0),
  ];
}

/// Finds where each ayah of a printed page sits on [image].
///
/// Every printed Mushaf page ends on an ayah end, so the ayah markers
/// (rosettes filled with [markerFill], 0xRRGGBB), read right to left and top
/// to bottom, close the page's [ayahs] one by one. Nothing else is needed:
/// not where words break, nor how many words a line holds.
///
/// Lines: the page's ink is split into [lines] bands, cutting at the quietest
/// rows near an even spacing, so taller title lines do not throw later lines
/// off. A band holding a surah banner (a fill blob nearly as wide as the page)
/// is a title; the band under it is the basmala unless the surah that begins
/// there is al-Fatiha, whose basmala is its first ayah, or at-Tawba, which has
/// none.
///
/// Returns no words, only the ink extent, when the markers found are not as
/// many as [ayahs].
PageGeometry measurePageGeometry(
  List<AyahRef> ayahs,
  InkImage image, {
  int lines = 15,
  int markerFill = 0xD8E9D8,
}) {
  final w = image.width;
  final h = image.height;
  final px = image.rgba;
  if (ayahs.isEmpty || w == 0 || h == 0) return const PageGeometry(words: []);

  // Background colour from the four corners.
  var br = 0, bg = 0, bb = 0;
  for (final (x, y) in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]) {
    final i = (y * w + x) * 4;
    br += px[i];
    bg += px[i + 1];
    bb += px[i + 2];
  }
  br ~/= 4;
  bg ~/= 4;
  bb ~/= 4;
  // Ink for the letters, and the marker fill apart from it.
  final fr = (markerFill >> 16) & 0xFF;
  final fg = (markerFill >> 8) & 0xFF;
  final fb = markerFill & 0xFF;
  final mask = Uint8List(w * h);
  final fill = Uint8List(w * h);
  for (var i = 0; i < w * h; i++) {
    final j = i * 4;
    if ((px[j] - br).abs() + (px[j + 1] - bg).abs() + (px[j + 2] - bb).abs() >
        150) {
      mask[i] = 1;
    }
    if ((px[j] - fr).abs() < 8 &&
        (px[j + 1] - fg).abs() < 8 &&
        (px[j + 2] - fb).abs() < 8) {
      fill[i] = 1;
    }
  }

  final rows = List<int>.filled(h, 0);
  for (var y = 0; y < h; y++) {
    var count = 0;
    for (var x = 0; x < w; x++) {
      count += mask[y * w + x];
    }
    rows[y] = count;
  }
  var top = 0;
  while (top < h && rows[top] == 0) {
    top++;
  }
  var bottom = h - 1;
  while (bottom > top && rows[bottom] == 0) {
    bottom--;
  }
  if (top >= bottom) return const PageGeometry(words: []);

  final inkTop = top / h;
  final inkBottom = (bottom + 1) / h;
  final cuts = _lineCuts(rows, top, bottom, lines);
  final boxes = _placeByMarkers(ayahs, mask, fill, w, h, cuts);
  return PageGeometry(
    words: boxes ?? const [],
    inkTop: inkTop,
    inkBottom: inkBottom,
    lineCuts: [for (final cut in cuts) cut / h],
  );
}

/// Inked pixels per column between rows [y0] and [y1].
List<int> _columnInk(Uint8List mask, int w, int y0, int y1) {
  final columns = List<int>.filled(w, 0);
  for (var y = y0; y < y1; y++) {
    final row = y * w;
    for (var x = 0; x < w; x++) {
      columns[x] += mask[row + x];
    }
  }
  return columns;
}

/// First and last inked column.
(int, int) _inkSpan(List<int> columns) {
  var first = 0;
  while (first < columns.length && columns[first] == 0) {
    first++;
  }
  var last = columns.length - 1;
  while (last > first && columns[last] == 0) {
    last--;
  }
  return (first, last);
}

/// Boxes of [ayahs] on a page, cut at its ayah markers, or null when the
/// markers found are not as many as the ayahs. [mask] holds the letters,
/// [fill] the marker fill, and [cuts] are the line bands.
///
/// Each box spans one ayah's part of one text line; a marker belongs to the
/// ayah it closes.
List<WordBox>? _placeByMarkers(
  List<AyahRef> ayahs,
  Uint8List mask,
  Uint8List fill,
  int w,
  int h,
  List<int> cuts,
) {
  final lines = cuts.length - 1;
  final pitch = (cuts.last - cuts.first) / lines;
  final rim = (pitch * 0.06).round();
  final markers = List.generate(lines, (_) => <(int, int)>[]);
  final banners = <int>{};
  for (final blob in _blobs(fill, w, h, cuts.first, cuts.last)) {
    final bw = blob.maxX - blob.minX + 1;
    final bh = blob.maxY - blob.minY + 1;
    final line = _lineOf(cuts, (blob.minY + blob.maxY) ~/ 2);
    if (bw >= w * 0.5) {
      banners.add(line);
    } else if (bw >= 0.3 * pitch &&
        bw <= 0.8 * pitch &&
        bh >= 0.18 * pitch &&
        bh <= 0.6 * pitch &&
        blob.count >= 0.25 * bw * bh) {
      // The fill sits inside the rosette's rim.
      markers[line].add((blob.minX - rim, blob.maxX + rim));
    }
  }
  var found = 0;
  for (final line in banners) {
    // A banner's ornaments are filled alike.
    markers[line].clear();
  }
  final lefts = <List<int>>[];
  for (final line in markers) {
    // Right to left. A letter over a rosette can split its fill in two; the
    // pieces overlap in x and count once.
    line.sort((a, b) => b.$1.compareTo(a.$1));
    final merged = <int>[];
    for (final (left, right) in line) {
      if (merged.isNotEmpty && right > merged.last) {
        merged.last = math.min(merged.last, left);
      } else {
        merged.add(left);
      }
    }
    lefts.add(merged);
    found += merged.length;
  }
  if (found != ayahs.length) return null;

  final boxes = <WordBox>[];
  var current = 0;
  var basmala = false;
  for (var line = 0; line < lines; line++) {
    if (banners.contains(line)) {
      final next = current < ayahs.length ? ayahs[current] : null;
      basmala = next != null && next.surah != 1 && next.surah != 9;
      continue;
    }
    if (basmala) {
      basmala = false;
      continue;
    }
    final y0 = cuts[line];
    final y1 = cuts[line + 1];
    final (xMin, xMax) = _inkSpan(_columnInk(mask, w, y0, y1));
    if (xMin >= xMax) continue;
    // Right to left: a box runs from the previous edge to the marker's left.
    var right = xMax + 1;
    final edges = [...lefts[line], xMin];
    for (var i = 0; i < edges.length; i++) {
      final left = math.max(edges[i], xMin);
      if (current < ayahs.length && right - left > 2) {
        boxes.add(
          WordBox(
            ayah: ayahs[current],
            word: 1,
            line: line,
            left: left / w,
            right: right / w,
            top: y0 / h,
            bottom: y1 / h,
          ),
        );
      }
      right = left;
      // Every edge but the line's own end is a marker, closing an ayah.
      if (i < edges.length - 1) current++;
    }
  }
  return current == ayahs.length ? List.unmodifiable(boxes) : null;
}

/// A connected group of marked pixels.
typedef _Blob = ({int minX, int minY, int maxX, int maxY, int count});

/// The groups of 8-connected pixels of [mask] whose first pixel lies between
/// rows [y0] and [y1].
List<_Blob> _blobs(Uint8List mask, int w, int h, int y0, int y1) {
  final blobs = <_Blob>[];
  final seen = Uint8List(w * h);
  final stack = Int32List(w * h);
  for (var y = y0; y < y1; y++) {
    for (var x = 0; x < w; x++) {
      final start = y * w + x;
      if (mask[start] == 0 || seen[start] == 1) continue;
      var minX = x, maxX = x, minY = y, maxY = y, count = 0;
      var depth = 0;
      stack[depth++] = start;
      seen[start] = 1;
      while (depth > 0) {
        final at = stack[--depth];
        final px = at % w;
        final py = at ~/ w;
        count++;
        minX = math.min(minX, px);
        maxX = math.max(maxX, px);
        minY = math.min(minY, py);
        maxY = math.max(maxY, py);
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = px + dx;
            final ny = py + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final next = ny * w + nx;
            if (mask[next] == 1 && seen[next] == 0) {
              seen[next] = 1;
              stack[depth++] = next;
            }
          }
        }
      }
      blobs.add((minX: minX, minY: minY, maxX: maxX, maxY: maxY, count: count));
    }
  }
  return blobs;
}

/// Index of the line band holding row [y].
int _lineOf(List<int> cuts, int y) {
  var line = 0;
  while (line < cuts.length - 2 && y >= cuts[line + 1]) {
    line++;
  }
  return line;
}

/// Row positions cutting the ink between [top] and [bottom] into [count] lines.
List<int> _lineCuts(List<int> rows, int top, int bottom, int count) {
  if (count == 1) return [top, bottom + 1];
  final pitch = (bottom - top + 1) / count;
  final k = math.max(1, pitch ~/ 10);
  final smooth = List<double>.filled(rows.length, 0);
  for (var y = top; y <= bottom; y++) {
    var sum = 0;
    var n = 0;
    for (
      var j = math.max(0, y - k);
      j <= math.min(rows.length - 1, y + k);
      j++
    ) {
      sum += rows[j];
      n++;
    }
    smooth[y] = sum / n;
  }
  var peak = 1.0;
  for (var y = top; y <= bottom; y++) {
    peak = math.max(peak, smooth[y]);
  }
  final candidates = <int>[];
  for (var y = top + 1; y < bottom; y++) {
    if (smooth[y] <= smooth[y - 1] && smooth[y] <= smooth[y + 1]) {
      if (candidates.isEmpty || y - candidates.last > 2) candidates.add(y);
    }
  }
  final m = candidates.length;
  if (m < count - 1) {
    return [
      for (var i = 0; i < count; i++) (top + i * pitch).round(),
      bottom + 1,
    ];
  }
  double segment(int a, int b) => 2 * ((b - a) - pitch).abs() / pitch;
  double quiet(int c) => smooth[candidates[c]] / peak * 4;

  const inf = double.infinity;
  final cost = List.generate(count, (_) => List<double>.filled(m, inf));
  final from = List.generate(count, (_) => List<int>.filled(m, -1));
  for (var c = 0; c < m; c++) {
    cost[1][c] = quiet(c) + segment(top, candidates[c]);
  }
  for (var j = 2; j < count; j++) {
    for (var c = 0; c < m; c++) {
      var best = inf;
      var arg = -1;
      for (var q = 0; q < c; q++) {
        final v = cost[j - 1][q];
        if (v == inf) continue;
        final total = v + segment(candidates[q], candidates[c]);
        if (total < best) {
          best = total;
          arg = q;
        }
      }
      if (arg >= 0) {
        cost[j][c] = best + quiet(c);
        from[j][c] = arg;
      }
    }
  }
  var last = -1;
  var best = inf;
  for (var c = 0; c < m; c++) {
    final v = cost[count - 1][c];
    if (v == inf) continue;
    final total = v + segment(candidates[c], bottom + 1);
    if (total < best) {
      best = total;
      last = c;
    }
  }
  if (last < 0) {
    return [
      for (var i = 0; i < count; i++) (top + i * pitch).round(),
      bottom + 1,
    ];
  }
  final picked = <int>[];
  var c = last;
  for (var j = count - 1; j >= 1; j--) {
    picked.add(candidates[c]);
    c = from[j][c];
  }
  return [top, ...picked.reversed, bottom + 1];
}
