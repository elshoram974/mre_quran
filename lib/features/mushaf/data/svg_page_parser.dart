import 'dart:convert';

import '../../quran_index/domain/quran_metadata.dart';
import '../domain/svg_page.dart';
import 'svg_line_splitter.dart';

/// Reads the files of one quran-svg page: the SVG artwork and the JSON list
/// of ayah polygons. Format notes: `docs/QURAN_SOURCES.md`, section 14.
///
/// Nothing in the artwork is redrawn or edited. The SVG is only divided into
/// its script and its ayah-number ornaments, so each can take a theme colour.
abstract final class SvgPageParser {
  static final RegExp _number = RegExp(r'-?\d+(?:\.\d+)?');
  static final RegExp _viewBox = RegExp(r'viewBox="([^"]+)"');
  static final RegExp _group = RegExp(r'<g\b[^>]*>|</g>');
  static final RegExp _polygon = RegExp(
    r'<path\b[^>]*\bclass="ayahPolygon"[^>]*/>',
  );
  static const String _marksOpen = '<g id="ayah_markers"';

  /// Builds page [page] from its [svg] and its polygon [json].
  ///
  /// Both halves of the artwork are given the page's visible box as their
  /// view box, so a renderer only has to fill a box of that shape: the
  /// opening pages come out cropped to their text with no placement maths.
  ///
  /// [ordered] says the edition draws its script line by line; see
  /// [SvgLineSplitter.split].
  static SvgPage page(
    int page, {
    required String svg,
    required String json,
    bool ordered = true,
  }) {
    final parts = split(svg);
    final declared = viewBox(svg);
    final ayahs = regions(json);
    final byRegions = SvgPageLayout(viewBox: declared, regions: ayahs);
    // Only a cropped page needs its ink measured: its name and basmala lie
    // outside the ayah regions.
    final layout = byRegions.content == declared
        ? byRegions
        : SvgPageLayout(
            viewBox: declared,
            regions: ayahs,
            ink: SvgLineSplitter.inkBox(parts.ink),
          );
    final ink = _show(parts.ink, layout.content);
    final marks = _show(parts.marks, layout.content);
    // A cropped opening page is a small ornate block; it is never spread.
    final lines = layout.content == layout.viewBox
        ? SvgLineSplitter.split(
            ink: ink,
            marks: marks,
            box: layout.content,
            ordered: ordered,
          )
        : null;
    return SvgPage(
      page: page,
      ink: ink,
      marks: marks,
      layout: layout,
      inkLines: lines?.ink,
      marksLines: lines?.marks,
      titles: layout.content == layout.viewBox
          ? titles(layout, lines?.lines ?? const [])
          : _openingTitle(layout, ink),
    );
  }

  /// The surah name of a cropped opening page: the topmost block of its
  /// ink above its first ayah, which the page sets apart in its own space.
  static List<SvgSurahTitle> _openingTitle(SvgPageLayout layout, String ink) {
    final first = layout.regions.where((r) => r.ref.ayah == 1).firstOrNull;
    if (first == null) return const [];
    final pitch = pageBoxHeight(layout.viewBox) / SvgPageLayout.printedLines;
    final box = SvgLineSplitter.topBlock(
      ink,
      above: first.bounds.top,
      gap: pitch * 0.5,
    );
    if (box == null) return const [];
    final width = pageBoxWidth(layout.content);
    final narrow = box.right - box.left < width * 0.6;
    if (!narrow || box.bottom - box.top > pitch * 1.2) return const [];
    return [
      (surah: first.ref.surah, box: box, line: (box.top + box.bottom) / 2),
    ];
  }

  /// Widest a printed surah name is, and the least and most width of a
  /// basmala, as shares of the page's width; and how far off the page's
  /// middle either may be centred.
  static const double _nameWidth = 0.4;
  static const double _basmalaLeast = 0.4;
  static const double _basmalaMost = 0.75;
  static const double _centred = 0.08;

  /// The surah names [layout] prints, each with the box its calligraphy
  /// covers on the page's printed [lines], so a frame can be drawn around
  /// it whatever its size, in any reading.
  ///
  /// A name is a short line in the middle of the page with a basmala, a
  /// little wider and also centred, straight under it (At-Tawbah has
  /// none). Short lines that end a surah are not followed by a basmala.
  /// The ayah regions only say about where a name is: some readings count
  /// the name and basmala lines into the first ayah. A name whose line is
  /// not found gets no frame, never one over the text.
  static List<SvgSurahTitle> titles(
    SvgPageLayout layout,
    List<SvgPrintedLine> lines,
  ) {
    final pitch = pageBoxHeight(layout.viewBox) / SvgPageLayout.printedLines;
    final width = pageBoxWidth(layout.viewBox);
    double share(PageBox box) => (box.right - box.left) / width;
    bool centred(PageBox box) =>
        (((box.left + box.right) / 2 - layout.viewBox.left) / width - 0.5)
            .abs() <
        _centred;
    final names = <({SvgPrintedLine line, bool basmala})>[
      for (var i = 0; i < lines.length; i++)
        if (share(lines[i].box) < _nameWidth && centred(lines[i].box))
          (
            line: lines[i],
            basmala:
                i + 1 < lines.length &&
                centred(lines[i + 1].box) &&
                share(lines[i + 1].box) >= _basmalaLeast &&
                share(lines[i + 1].box) <= _basmalaMost,
          ),
    ];
    final taken = <SvgPrintedLine>{};
    final titles = <SvgSurahTitle>[];
    for (final slot in layout.surahTitles) {
      final aim = (slot.top + slot.bottom) / 2;
      final basmala = slot.surah != 9;
      SvgPrintedLine? best;
      for (final name in names) {
        if (name.basmala != basmala || taken.contains(name.line)) continue;
        final off = (name.line.middle - aim).abs();
        if (off > pitch * 4) continue;
        if (best == null || off < (best.middle - aim).abs()) best = name.line;
      }
      if (best == null) continue;
      taken.add(best);
      titles.add((surah: slot.surah, box: best.box, line: best.middle));
    }
    return titles;
  }

  /// [svg] with its view box set to [box]. Only the viewport changes; the
  /// artwork is untouched.
  static String _show(String svg, PageBox box) => svg.replaceFirst(
    _viewBox,
    'viewBox="${box.left} ${box.top} '
    '${pageBoxWidth(box)} ${pageBoxHeight(box)}"',
  );

  /// The view box the SVG declares. The opening pages have a negative
  /// origin, so it is always read, never assumed.
  static PageBox viewBox(String svg) {
    final match = _viewBox.firstMatch(svg);
    final values = match == null
        ? const <double>[]
        : [
            for (final m in _number.allMatches(match.group(1)!))
              double.parse(m.group(0)!),
          ];
    if (values.length != 4 || values[2] <= 0 || values[3] <= 0) {
      throw const FormatException('SVG page without a usable viewBox');
    }
    return (
      left: values[0],
      top: values[1],
      right: values[0] + values[2],
      bottom: values[1] + values[3],
    );
  }

  /// The ayah regions in a page's polygon JSON.
  ///
  /// A polygon ships in two shapes: SVG path data with one `M … Z` subpath
  /// per printed line, or, on the two opening pages, a bare `x,y x,y …`
  /// point list. Subpaths stay separate rings; joining them would weld
  /// separate lines into one outline.
  static List<AyahRegion> regions(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Polygon file is not a list');
    }
    return [
      for (final entry in decoded)
        if (entry case {
          'surahNumber': final int surah,
          'ayahNumber': final int ayah,
          'polygon': final String polygon,
        })
          AyahRegion(ref: AyahRef(surah, ayah), rings: _rings(polygon))
        else
          throw const FormatException('Polygon entry without an ayah'),
    ];
  }

  static List<List<PagePoint>> _rings(String polygon) {
    final rings = <List<PagePoint>>[];
    // Path data starts each subpath with M; a point list has no commands.
    for (final part in polygon.split('M')) {
      final numbers = [
        for (final m in _number.allMatches(part)) double.parse(m.group(0)!),
      ];
      if (numbers.isEmpty) continue;
      if (numbers.length.isOdd || numbers.length < 6) {
        throw const FormatException('Polygon with a broken outline');
      }
      rings.add([
        for (var i = 0; i < numbers.length; i += 2)
          (x: numbers[i], y: numbers[i + 1]),
      ]);
    }
    if (rings.isEmpty) throw const FormatException('Empty polygon');
    return rings;
  }

  /// Divides the artwork into the script and the ayah-number ornaments,
  /// each a whole SVG over the same view box and page transform. The
  /// invisible ayah polygons are left out of both; their data comes from
  /// the JSON.
  static ({String ink, String marks}) split(String svg) {
    final svgOpenEnd = svg.indexOf('>', svg.indexOf('<svg'));
    final rootStart = svg.indexOf('<g', svgOpenEnd);
    final rootOpenEnd = svg.indexOf('>', rootStart);
    final start = svg.indexOf(_marksOpen);
    if (svgOpenEnd < 0 || rootStart < 0 || rootOpenEnd < 0) {
      throw const FormatException('SVG page without a page group');
    }
    final withoutPolygons = svg.replaceAll(_polygon, '');
    if (start < 0) {
      // A page with no ayah ending on it has no ornaments.
      return (
        ink: withoutPolygons,
        marks: '${svg.substring(0, svgOpenEnd + 1)}</svg>',
      );
    }
    final end = _groupEnd(svg, start);
    return (
      ink: (svg.substring(0, start) + svg.substring(end)).replaceAll(
        _polygon,
        '',
      ),
      marks:
          '${svg.substring(0, rootOpenEnd + 1)}'
          '${svg.substring(start, end)}</g></svg>',
    );
  }

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
    throw const FormatException('SVG page with an unclosed group');
  }
}
