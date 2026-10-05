import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';
import 'page_layout.dart';

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
  /// Creates geometry from [words].
  const PageGeometry({required this.words});

  /// Every word on the page.
  final List<WordBox> words;

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
  AyahRef? ayahAt(double x, double y) {
    for (final box in words) {
      if (box.contains(x, y)) return box.ayah;
    }
    return null;
  }
}

/// Finds where each word of [layout] sits on [image].
///
/// Lines: the page's ink is split into as many bands as the layout has lines,
/// cutting at the quietest rows near an even spacing, so taller title and
/// basmala lines do not throw later lines off. Words: inside each text line,
/// boundaries are placed at gaps in the ink near where the words' letter
/// counts predict them. Both steps use dynamic programming over candidates.
PageGeometry measurePageGeometry(PageLayout layout, InkImage image) {
  final w = image.width;
  final h = image.height;
  final px = image.rgba;
  final lineCount = layout.lines.length;
  if (lineCount == 0 || w == 0 || h == 0) return const PageGeometry(words: []);

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
  bool ink(int x, int y) {
    final i = (y * w + x) * 4;
    return (px[i] - br).abs() +
            (px[i + 1] - bg).abs() +
            (px[i + 2] - bb).abs() >
        150;
  }

  final rows = List<int>.filled(h, 0);
  for (var y = 0; y < h; y++) {
    var count = 0;
    for (var x = 0; x < w; x++) {
      if (ink(x, y)) count++;
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

  final cuts = _lineCuts(rows, top, bottom, lineCount);
  final boxes = <WordBox>[];
  for (var line = 0; line < lineCount; line++) {
    final words = layout.lines[line].words;
    if (words.isEmpty) continue;
    final y0 = cuts[line];
    final y1 = cuts[line + 1];
    final columns = List<int>.filled(w, 0);
    for (var x = 0; x < w; x++) {
      var count = 0;
      for (var y = y0; y < y1; y++) {
        if (ink(x, y)) count++;
      }
      columns[x] = count;
    }
    var xMin = 0;
    while (xMin < w && columns[xMin] == 0) {
      xMin++;
    }
    var xMax = w - 1;
    while (xMax > xMin && columns[xMax] == 0) {
      xMax--;
    }
    if (xMin >= xMax) continue;
    final bounds = _wordBounds(columns, xMin, xMax, words);
    for (var i = 0; i < words.length; i++) {
      boxes.add(
        WordBox(
          ayah: words[i].ayah,
          word: words[i].index,
          line: line,
          left: bounds[i + 1] / w,
          right: bounds[i] / w,
          top: y0 / h,
          bottom: y1 / h,
        ),
      );
    }
  }
  return PageGeometry(words: List.unmodifiable(boxes));
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

/// Weight of a word: its letters, without marks and signs, plus a space.
double _weight(String word) {
  var letters = 0;
  for (final rune in word.runes) {
    final mark =
        (rune >= 0x0610 && rune <= 0x061A) ||
        (rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        rune == 0x0640 ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        (rune >= 0x0660 && rune <= 0x0669) ||
        rune == 0x20;
    if (!mark) letters++;
  }
  return letters + 1.2;
}

/// Word edges from right to left: `bounds[0]` is the right edge of the first
/// word, `bounds[i + 1]` the left edge of word `i`.
List<double> _wordBounds(
  List<int> columns,
  int xMin,
  int xMax,
  List<LayoutWord> words,
) {
  final count = words.length;
  final span = (xMax - xMin).toDouble();
  if (count == 1) return [xMax.toDouble(), xMin.toDouble()];

  // Ink gaps, right to left, as (centre, width).
  final gaps = <(double, int)>[];
  int? start;
  for (var x = xMin; x <= xMax; x++) {
    if (columns[x] == 0) {
      start ??= x;
    } else if (start != null) {
      gaps.add(((start + x - 1) / 2, x - start));
      start = null;
    }
  }
  gaps.sort((a, b) => b.$1.compareTo(a.$1));

  final weights = [for (final word in words) _weight(word.text)];
  final total = weights.reduce((a, b) => a + b);
  final predicted = <double>[];
  var sum = 0.0;
  for (var j = 0; j < count - 1; j++) {
    sum += weights[j];
    predicted.add(xMax - span * sum / total);
  }

  final m = gaps.length;
  if (m < count - 1) {
    return [xMax.toDouble(), ...predicted, xMin.toDouble()];
  }
  // Wider gaps are likelier word breaks, up to a cap of 1/90 of the width.
  final gapCap = columns.length / 90;
  double cost(int g, int j) =>
      (gaps[g].$1 - predicted[j]).abs() - 2.0 * math.min(gaps[g].$2, gapCap);

  const inf = double.infinity;
  final dp = List.generate(count - 1, (_) => List<double>.filled(m, inf));
  final from = List.generate(count - 1, (_) => List<int>.filled(m, -1));
  for (var g = 0; g < m; g++) {
    dp[0][g] = cost(g, 0);
  }
  for (var j = 1; j < count - 1; j++) {
    var best = inf;
    var arg = -1;
    for (var g = 0; g < m; g++) {
      if (g > 0 && dp[j - 1][g - 1] < best) {
        best = dp[j - 1][g - 1];
        arg = g - 1;
      }
      if (best < inf) {
        dp[j][g] = best + cost(g, j);
        from[j][g] = arg;
      }
    }
  }
  var last = 0;
  for (var g = 1; g < m; g++) {
    if (dp[count - 2][g] < dp[count - 2][last]) last = g;
  }
  if (dp[count - 2][last] == inf) {
    return [xMax.toDouble(), ...predicted, xMin.toDouble()];
  }
  final picked = <double>[];
  var g = last;
  for (var j = count - 2; j >= 0; j--) {
    picked.add(gaps[g].$1);
    g = from[j][g];
  }
  return [xMax.toDouble(), ...picked.reversed, xMin.toDouble()];
}
