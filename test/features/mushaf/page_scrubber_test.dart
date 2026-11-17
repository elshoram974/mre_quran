import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/page_scrubber.dart';

const double _width = 400;

Future<List<int>> _pump(
  WidgetTester tester, {
  int page = 100,
  TextDirection direction = TextDirection.rtl,
  VoidCallback? onEnterNumber,
}) async {
  final picked = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: _width,
              child: PageScrubber(
                page: page,
                pageCount: 604,
                titleOf: (p) => 'Page $p',
                subtitleOf: (p) => 'Place $p',
                digits: (p) => '$p',
                fineLabel: 'Fine',
                cancelHint: 'Up to cancel',
                cancelNow: 'Lift to cancel',
                numberTooltip: 'Type a page',
                onChanged: picked.add,
                onEnterNumber: onEnterNumber ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return picked;
}

Rect _track(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(PageScrubber),
        matching: find.byType(CustomPaint),
      )
      .last,
);

int _shownPage(WidgetTester tester) {
  final title = tester
      .widgetList<Text>(find.textContaining('Page '))
      .first
      .data!;
  return int.parse(title.substring(5));
}

void main() {
  testWidgets('shows the page and its place', (tester) async {
    await _pump(tester);
    expect(find.text('Page 100'), findsOneWidget);
    expect(find.text('Place 100'), findsOneWidget);
    expect(find.text('Fine'), findsNothing);
  });

  for (final direction in TextDirection.values) {
    testWidgets('the first page is at the right end in $direction', (
      tester,
    ) async {
      final picked = await _pump(tester, direction: direction);
      final track = _track(tester);
      await tester.tapAt(Offset(track.right - 1, track.center.dy));
      await tester.pump();
      expect(picked.single, lessThan(5));
      await tester.tapAt(Offset(track.left + 1, track.center.dy));
      await tester.pump();
      expect(picked.last, greaterThan(600));
    });
  }

  testWidgets('a drag previews the page and reports it once, on release', (
    tester,
  ) async {
    final picked = await _pump(tester);
    final track = _track(tester);
    final gesture = await tester.startGesture(track.center);
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    expect(picked, isEmpty);
    final preview = _shownPage(tester);
    expect(preview, greaterThan(302));
    await gesture.up();
    await tester.pump();
    expect(picked, [preview]);
  });

  testWidgets('holding still opens the fine scale, one page per step', (
    tester,
  ) async {
    final picked = await _pump(tester);
    final track = _track(tester);
    final gesture = await tester.startGesture(track.center);
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    // A tremor does not restart the wait.
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(-2, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Fine'), findsOneWidget);
    final coarse = _shownPage(tester);

    // One twentieth of the track is one page on the fine scale.
    await gesture.moveBy(Offset(-track.width / 20, 0));
    await tester.pump();
    expect((_shownPage(tester) - coarse).abs(), inInclusiveRange(1, 2));

    final chosen = _shownPage(tester);
    await gesture.up();
    await tester.pump();
    expect(picked, [chosen]);
    expect(find.text('Fine'), findsNothing);
  });

  testWidgets('holding the thumb at an end of the fine scale rolls it on', (
    tester,
  ) async {
    final picked = await _pump(tester);
    final track = _track(tester);
    final gesture = await tester.startGesture(track.center);
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Fine'), findsOneWidget);
    // To the left end, where the later pages are, and wait there.
    await gesture.moveTo(Offset(track.left + 2, track.center.dy));
    await tester.pump();
    final atEdge = _shownPage(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(_shownPage(tester), greaterThan(atEdge + 2));
    // Away from the end it stops.
    await gesture.moveTo(track.center);
    await tester.pump();
    final resting = _shownPage(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_shownPage(tester), resting);
    await gesture.up();
    await tester.pump();
    expect(picked, [resting]);
  });

  testWidgets('lifting the finger above the track changes nothing', (
    tester,
  ) async {
    final picked = await _pump(tester);
    final track = _track(tester);
    final gesture = await tester.startGesture(track.center);
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(find.text('Up to cancel'), findsOneWidget);
    expect(_shownPage(tester), isNot(100));
    // Up and away from the track: the card shows the reader's page again.
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(find.text('Lift to cancel'), findsOneWidget);
    expect(_shownPage(tester), 100);
    // Back on the track the drag goes on.
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(find.text('Lift to cancel'), findsNothing);
    expect(_shownPage(tester), isNot(100));
    await gesture.moveBy(const Offset(0, -80));
    await gesture.up();
    await tester.pump();
    expect(picked, isEmpty);
  });

  testWidgets('a moving finger never opens the fine scale', (tester) async {
    await _pump(tester);
    final gesture = await tester.startGesture(_track(tester).center);
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-12, 0));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Fine'), findsNothing);
    await gesture.up();
    await tester.pump();
  });

  testWidgets('the number button asks for a typed page', (tester) async {
    var asked = 0;
    await _pump(tester, onEnterNumber: () => asked++);
    await tester.tap(find.byTooltip('Type a page'));
    expect(asked, 1);
  });

  testWidgets('a screen reader steps one page at a time', (tester) async {
    final handle = tester.ensureSemantics();
    final picked = await _pump(tester);
    final slider = find.semantics.byAction(SemanticsAction.increase);
    tester.semantics.increase(slider);
    tester.semantics.decrease(slider);
    expect(picked, [101, 99]);
    handle.dispose();
  });
}
