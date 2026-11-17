// Checks the line splitter against every page of the quran-svg Hafs set.
//
// Usage: dart run tool/check_svg_lines.dart <folder with 001.svg … 604.svg>
//        <folder with 001.json … 604.json> [--unordered]
//
// Pass --unordered for a Mushaf whose drawing order is not line by line
// (Shu'bah, Qalun, Al-Duri): every contour is then placed by where it lies.
//
// For each page it reports whether the page can be spread, and how: by the
// drawing order, by it leniently (a few contours placed by where they lie),
// or by where every contour lies; and how many printed lines were found. Pages 1 and 2 are cropped opening pages and are
// never spread. Run it after any change to the splitter; the expected
// output is recorded in docs/QURAN_SOURCES.md, section 14.
import 'dart:io';

import 'package:mre_quran/features/mushaf/data/svg_line_splitter.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';

void main(List<String> arguments) {
  final ordered = !arguments.contains('--unordered');
  final folders = [
    for (final argument in arguments)
      if (argument != '--unordered') argument,
  ];
  if (folders.length != 2) {
    stderr.writeln(
      'usage: check_svg_lines.dart <svg folder> <json folder> [--unordered]',
    );
    exit(64);
  }
  final byLines = <int, List<int>>{};
  final unspread = <int>[];
  // How each spread page was split: as SvgLineSplitter.split tries.
  final byWay = <String, List<int>>{};
  final ways = [
    if (ordered) ...[
      ('drawing order', false, true),
      ('drawing order, leniently', true, true),
    ],
    ('where contours lie', true, false),
  ];
  for (var page = 1; page <= 604; page++) {
    final name = page.toString().padLeft(3, '0');
    final svg = File('${folders[0]}/$name.svg').readAsStringSync();
    final layout = SvgPageLayout(
      viewBox: SvgPageParser.viewBox(svg),
      regions: SvgPageParser.regions(
        File('${folders[1]}/$name.json').readAsStringSync(),
      ),
    );
    if (layout.content != layout.viewBox) {
      stdout.writeln('$page: cropped opening page');
      unspread.add(page);
      continue;
    }
    final parts = SvgPageParser.split(svg);
    ({SvgSpreadLayer ink, SvgSpreadLayer marks})? lines;
    final reasons = <String>[];
    for (final (way, lenient, inOrder) in ways) {
      try {
        lines = SvgLineSplitter.splitOrThrow(
          ink: parts.ink,
          marks: parts.marks,
          box: layout.content,
          lenient: lenient,
          ordered: inOrder,
        );
        byWay.putIfAbsent(way, () => []).add(page);
        if (reasons.isNotEmpty) {
          stdout.writeln('$page: $way (${reasons.join('; ')})');
        }
        break;
      } on SvgLinesUnclear catch (problem) {
        reasons.add(problem.reason);
      }
    }
    if (lines == null) {
      stdout.writeln('$page: ${reasons.join('; ')}');
      unspread.add(page);
      continue;
    }
    final shifts = lines.ink.shifts;
    final distinct = shifts.toSet().toList()..sort((a, b) => b.compareTo(a));
    byLines.putIfAbsent(distinct.length, () => []).add(page);
    if (distinct.length != 15) {
      // An unusual page: each line's shift and how many runs it has.
      final summary = [
        for (final shift in distinct)
          '${shift.toStringAsFixed(1)}x'
              '${shifts.where((other) => other == shift).length}',
      ];
      stdout.writeln('$page: ${summary.join(' ')}');
    }
  }
  for (final MapEntry(key: way, value: pages) in byWay.entries) {
    stdout.writeln(
      '$way: ${pages.length}${pages.length <= 40 ? ' $pages' : ''}',
    );
  }
  stdout.writeln('not spread: ${unspread.length} $unspread');
  for (final count in byLines.keys.toList()..sort()) {
    final pages = byLines[count]!;
    stdout.writeln(
      '$count lines: ${pages.length} pages'
      '${pages.length <= 40 ? ' $pages' : ''}',
    );
  }
}
