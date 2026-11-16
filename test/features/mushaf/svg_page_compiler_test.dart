import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_compiler.dart';

import '../../helpers/svg_page_fixtures.dart';

void main() {
  group('compiling a page', () {
    test('a page whose lines can spread is compiled at the spread asked', () {
      final printed = SvgPageCompiler.compile(spreadPage(3));
      final spread = SvgPageCompiler.compile(spreadPage(3), stretch: 1.3);
      expect(printed.stretch, 1);
      expect(spread.stretch, 1.3);
      expect(spread.ink, isNot(printed.ink));
      expect(spread.layout.regions, hasLength(3));
    });

    test('a page whose lines are unclear stays at its printed height', () {
      final picture = SvgPageCompiler.compile(fixturePage(3), stretch: 1.3);
      expect(picture.stretch, 1);
      expect(picture.ink, isNotEmpty);
      expect(picture.marks, isNotEmpty);
    });

    test('a stretch below 1 is not a spread', () {
      expect(SvgPageCompiler.compile(spreadPage(3), stretch: 0.8).stretch, 1);
    });
  });

  group('pages kept ready', () {
    SvgPageRequest page(int number) => (page: number, stretch: 1000);

    test('the oldest goes once there are more than the list holds', () {
      final released = <int>[];
      final recent = RecentPages(capacity: 2);
      for (final number in [1, 2, 3]) {
        recent.hold(page(number), () => released.add(number));
      }
      expect(released, [1]);
    });

    test('a page used again becomes the newest', () {
      final released = <String>[];
      final recent = RecentPages(capacity: 2)
        ..hold(page(1), () => released.add('1 first'))
        ..hold(page(2), () => released.add('2'))
        // Page 1 was prepared afresh: its old hold is let go, the new kept.
        ..hold(page(1), () => released.add('1 again'));
      expect(released, ['1 first']);
      recent.hold(page(3), () => released.add('3'));
      expect(released, ['1 first', '2']);
    });
  });
}
