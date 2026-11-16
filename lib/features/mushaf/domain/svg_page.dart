import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../quran_index/domain/quran_metadata.dart';

/// A point on a Mushaf page, in the units of the page's SVG view box.
typedef PagePoint = ({double x, double y});

/// A rectangle on a Mushaf page, in the units of the page's SVG view box.
typedef PageBox = ({double left, double top, double right, double bottom});

/// Width of [box].
double pageBoxWidth(PageBox box) => box.right - box.left;

/// Height of [box].
double pageBoxHeight(PageBox box) => box.bottom - box.top;

/// Where one ayah lies on a printed page: one closed ring per printed line
/// it occupies (or a single staircase ring on the ornate opening pages).
@immutable
class AyahRegion {
  /// Creates the region of [ref] from its [rings].
  const AyahRegion({required this.ref, required this.rings});

  /// The ayah.
  final AyahRef ref;

  /// Closed outlines, each a list of corners in order.
  final List<List<PagePoint>> rings;

  /// Whether the point lies inside any ring.
  bool contains(double x, double y) => rings.any((ring) => _inside(ring, x, y));

  /// The smallest box holding every ring.
  PageBox get bounds {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final ring in rings) {
      for (final point in ring) {
        left = math.min(left, point.x);
        top = math.min(top, point.y);
        right = math.max(right, point.x);
        bottom = math.max(bottom, point.y);
      }
    }
    return (left: left, top: top, right: right, bottom: bottom);
  }

  /// Even-odd ray casting: counts the edges a ray to the right crosses.
  static bool _inside(List<PagePoint> ring, double x, double y) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      if ((a.y > y) != (b.y > y) &&
          x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// The ayah regions of one printed page, and the part of the page to show.
@immutable
class SvgPageLayout {
  /// Creates the layout of a page whose SVG declares [viewBox].
  SvgPageLayout({required this.viewBox, required List<AyahRegion> regions})
    : regions = List.unmodifiable(regions);

  /// The page's declared view box.
  final PageBox viewBox;

  /// One region per ayah on the page, in reading order.
  final List<AyahRegion> regions;

  /// Width over height of the box every full page declares (345 × 550).
  /// A reader asks for a page's spread before the page is read, from this.
  static const double fullPageAspect = 345 / 550;

  /// Below this share of the view box, the ink is treated as a small block
  /// and the page is shown cropped to it.
  static const double _smallInkShare = 0.5;

  /// Margin kept around a cropped ink block, as a share of its size.
  static const double _cropMargin = 0.06;

  /// The ayah at a point of the page, or null between ayahs.
  AyahRef? ayahAt(double x, double y) {
    for (final region in regions) {
      if (region.contains(x, y)) return region.ref;
    }
    return null;
  }

  /// The region of [ref], or null when the ayah is not on this page.
  AyahRegion? regionOf(AyahRef ref) {
    for (final region in regions) {
      if (region.ref == ref) return region;
    }
    return null;
  }

  /// The part of the page to fit on screen.
  ///
  /// Every page declares the same box, but the two opening pages fill about
  /// a fifth of it; fitting the declared box would show them tiny in a mostly
  /// empty page. Such a page is cropped to its ayah regions plus a margin.
  PageBox get content {
    if (regions.isEmpty) return viewBox;
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final region in regions) {
      final box = region.bounds;
      left = math.min(left, box.left);
      top = math.min(top, box.top);
      right = math.max(right, box.right);
      bottom = math.max(bottom, box.bottom);
    }
    final ink = (right - left) * (bottom - top);
    final declared = pageBoxWidth(viewBox) * pageBoxHeight(viewBox);
    if (ink >= declared * _smallInkShare) return viewBox;
    final dx = (right - left) * _cropMargin;
    final dy = (bottom - top) * _cropMargin;
    return (
      left: math.max(viewBox.left, left - dx),
      top: math.max(viewBox.top, top - dy),
      right: math.min(viewBox.right, right + dx),
      bottom: math.min(viewBox.bottom, bottom + dy),
    );
  }
}

/// One layer of a page's artwork with its printed lines held apart, so the
/// lines can be moved further from each other to fill a taller screen.
///
/// Every line keeps its drawn shape and moves as a whole; nothing is scaled,
/// cut or redrawn. Stretching by `k` places each line where a page `k`
/// times as tall would have it.
class SvgSpreadLayer {
  /// Creates a layer from the pieces of its SVG document.
  ///
  /// The document is [head], the view box, then [parts] with one vertical
  /// shift written between each two neighbours. [shifts] holds, for each of
  /// those gaps, the shift in the document's own units for a stretch of 2.
  SvgSpreadLayer({
    required this.head,
    required this.box,
    required List<String> parts,
    required List<double> shifts,
  }) : assert(parts.length == shifts.length + 1),
       parts = List.unmodifiable(parts),
       shifts = List.unmodifiable(shifts);

  /// The document up to and including `viewBox="`.
  final String head;

  /// The visible part of the page at a stretch of 1.
  final PageBox box;

  /// The rest of the document, cut at each line's shift.
  final List<String> parts;

  /// Shift of each line for a stretch of 2, in document units.
  final List<double> shifts;

  final Map<double, String> _built = {};

  /// Stretches a layer remembers. A screen has one, two with rotation.
  static const int _remembered = 2;

  /// The SVG document with its lines spread for a page [stretch] times as
  /// tall. The same string is returned for the same stretch, so a renderer
  /// can cache its picture by it.
  String at(double stretch) {
    final known = _built[stretch];
    if (known != null) return known;
    final out = StringBuffer(head)
      ..write('${box.left} ${box.top} ')
      ..write('${pageBoxWidth(box)} ${pageBoxHeight(box) * stretch}')
      ..write(parts.first);
    for (var i = 0; i < shifts.length; i++) {
      out
        ..write(shifts[i] * (stretch - 1))
        ..write(parts[i + 1]);
    }
    if (_built.length >= _remembered) _built.remove(_built.keys.first);
    return _built[stretch] = out.toString();
  }
}

/// One printed Mushaf page, ready to draw.
///
/// The artwork is held as two SVG documents whose view box is the page's
/// visible part ([SvgPageLayout.content]): the ink of the script, and the
/// ayah-number ornaments. Each is painted in one colour chosen at paint
/// time, so a change of theme or accent needs no parsing.
@immutable
class SvgPage {
  /// Creates page [page].
  const SvgPage({
    required this.page,
    required this.ink,
    required this.marks,
    required this.layout,
    this.inkLines,
    this.marksLines,
  }) : assert((inkLines == null) == (marksLines == null));

  /// Page number, 1–604.
  final int page;

  /// SVG of the script, without the ayah-number ornaments.
  final String ink;

  /// SVG of the ayah-number ornaments alone.
  final String marks;

  /// Where each ayah lies.
  final SvgPageLayout layout;

  /// [ink] with its printed lines held apart, or null when the page's lines
  /// could not be told apart with certainty. Such a page is never spread.
  final SvgSpreadLayer? inkLines;

  /// [marks] with each ornament tied to its line; null exactly when
  /// [inkLines] is.
  final SvgSpreadLayer? marksLines;

  /// Whether the page's lines can be spread to fill a taller screen.
  bool get canSpread => inkLines != null;
}

/// A printed page compiled for drawing at one spread of its lines.
///
/// The two layers are vector-graphics binaries, made off the main isolate
/// together with the rest of the page, so a page that is ready is ready to
/// paint: nothing is left to parse when it comes on screen.
@immutable
class SvgPagePicture {
  /// Creates the picture of page [page].
  const SvgPagePicture({
    required this.page,
    required this.ink,
    required this.marks,
    required this.layout,
    required this.stretch,
  });

  /// Page number, 1–604.
  final int page;

  /// The script, compiled.
  final Uint8List ink;

  /// The ayah-number ornaments, compiled.
  final Uint8List marks;

  /// Where each ayah lies on the printed page.
  final SvgPageLayout layout;

  /// How many times taller than printed the page is drawn: the spread that
  /// was asked for, or 1 when the page's lines cannot be spread.
  final double stretch;
}
