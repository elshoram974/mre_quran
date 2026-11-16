// Checks the line splitter against every page of the quran-svg Hafs set.
//
// Usage: dart run tool/check_svg_lines.dart <folder with 001.svg … 604.svg>
//        <folder with 001.json … 604.json>
//
// For each page it reports whether the page can be spread and how many
// printed lines were found. Pages 1 and 2 are cropped opening pages and are
// never spread. Run it after any change to the splitter; the expected
// output is recorded in docs/QURAN_SOURCES.md, section 14.
import 'dart:io';

import 'package:mre_quran/features/mushaf/data/svg_line_splitter.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln('usage: check_svg_lines.dart <svg folder> <json folder>');
    exit(64);
  }
  final byLines = <int, List<int>>{};
  final unspread = <int>[];
  for (var page = 1; page <= 604; page++) {
    final name = page.toString().padLeft(3, '0');
    final svg = File('${arguments[0]}/$name.svg').readAsStringSync();
    final layout = SvgPageLayout(
      viewBox: SvgPageParser.viewBox(svg),
      regions: SvgPageParser.regions(
        File('${arguments[1]}/$name.json').readAsStringSync(),
      ),
    );
    if (layout.content != layout.viewBox) {
      stdout.writeln('$page: cropped opening page');
      unspread.add(page);
      continue;
    }
    final parts = SvgPageParser.split(svg);
    try {
      final lines = SvgLineSplitter.splitOrThrow(
        ink: parts.ink,
        marks: parts.marks,
        box: layout.content,
      );
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
    } on SvgLinesUnclear catch (problem) {
      stdout.writeln('$page: ${problem.reason}');
      unspread.add(page);
    }
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
