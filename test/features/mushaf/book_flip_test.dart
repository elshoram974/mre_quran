import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/page_curl_painter.dart';

Future<List<int>> _pump(
  WidgetTester tester, {
  required bool realistic,
  required bool spread,
  int page = 5,
}) async {
  tester.view.physicalSize = Size(spread ? 900 : 400, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final changes = <int>[];
  var current = page;
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => BookFlip(
          pageCount: 20,
          spread: spread,
          realistic: realistic,
          page: current,
          onPageChanged: (p) => setState(() {
            changes.add(p);
            current = p;
          }),
          pageBuilder: (context, p) => Center(child: Text('page $p')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return changes;
}

Future<void> _drag(WidgetTester tester, double dx) async {
  final gesture = await tester.startGesture(const Offset(200, 350));
  for (var i = 0; i < 30; i++) {
    await gesture.moveBy(Offset(dx / 30, 0));
    await tester.pump(const Duration(milliseconds: 8));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  for (final realistic in [true, false]) {
    final style = realistic ? 'realistic' : 'sliding';

    testWidgets('$style single: a drag to the right turns forward', (
      tester,
    ) async {
      final changes = await _pump(tester, realistic: realistic, spread: false);
      await _drag(tester, 260);
      expect(changes, [6]);
      expect(find.text('page 6').hitTestable(), findsOneWidget);
    });

    testWidgets('$style single: a drag to the left turns back', (tester) async {
      final changes = await _pump(tester, realistic: realistic, spread: false);
      await _drag(tester, -260);
      expect(changes, [4]);
    });

    testWidgets('$style spread: turning moves two pages', (tester) async {
      final changes = await _pump(tester, realistic: realistic, spread: true);
      expect(find.text('page 5').hitTestable(), findsOneWidget);
      expect(find.text('page 6').hitTestable(), findsOneWidget);
      await _drag(tester, 500);
      expect(changes, [7]);
      expect(find.text('page 7').hitTestable(), findsOneWidget);
      expect(find.text('page 8').hitTestable(), findsOneWidget);
    });
  }

  /// Drags halfway and leaves the finger down.
  Future<TestGesture> halfway(WidgetTester tester, double dx) async {
    final gesture = await tester.startGesture(const Offset(200, 350));
    for (var i = 0; i < 30; i++) {
      await gesture.moveBy(Offset(dx / 30, 0));
      await tester.pump(const Duration(milliseconds: 8));
    }
    return gesture;
  }

  Finder curl() => find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is PageCurlPainter,
  );

  testWidgets('single: an even page turns its leaf onto the page before', (
    tester,
  ) async {
    final changes = await _pump(
      tester,
      realistic: true,
      spread: false,
      page: 4,
    );
    final gesture = await halfway(tester, 210);
    // Mid-turn the leaf is up, and the page it lands on (3, facing it in the
    // open book) has come in from the right.
    expect(curl(), findsOneWidget);
    final facing = tester.getRect(find.text('page 3'));
    expect(facing.center.dx, inExclusiveRange(200, 400));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [5]);
    expect(find.text('page 5').hitTestable(), findsOneWidget);
    expect(find.text('page 3').hitTestable(), findsNothing);
  });

  testWidgets('single: an odd page slides to the page facing it', (
    tester,
  ) async {
    final changes = await _pump(tester, realistic: true, spread: false);
    final gesture = await halfway(tester, 210);
    // No leaf turns inside one spread: page 5 moves right, 6 comes from the
    // left.
    expect(curl(), findsNothing);
    expect(tester.getRect(find.text('page 5')).center.dx, greaterThan(200));
    expect(tester.getRect(find.text('page 6')).center.dx, lessThan(200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [6]);
    expect(find.text('page 6').hitTestable(), findsOneWidget);
  });

  testWidgets('single: going back slides within a spread and turns across', (
    tester,
  ) async {
    final changes = await _pump(
      tester,
      realistic: true,
      spread: false,
      page: 6,
    );
    var gesture = await halfway(tester, -210);
    expect(curl(), findsNothing, reason: '6 back to 5 is one spread');
    await gesture.up();
    await tester.pumpAndSettle();
    gesture = await halfway(tester, -210);
    expect(curl(), findsOneWidget, reason: '5 back to 4 turns the leaf');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [5, 4]);
    expect(find.text('page 4').hitTestable(), findsOneWidget);
  });

  testWidgets('cannot turn before the first page or past the last', (
    tester,
  ) async {
    final first = await _pump(tester, realistic: true, spread: false, page: 1);
    await _drag(tester, -300);
    expect(first, isEmpty);
  });

  /// The lead of the painter drawing the turning sheet.
  double leadOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<PageCurlPainter>()
      .single
      .lead;

  for (final spread in [true, false]) {
    final mode = spread ? 'spread' : 'single';
    testWidgets('$mode: the sheet bends one way going forward and the other '
        'going back', (tester) async {
      await _pump(tester, realistic: true, spread: spread, page: 4);
      var gesture = await halfway(tester, 210);
      expect(leadOf(tester), closeTo(1, 0.02));
      await gesture.up();
      await tester.pumpAndSettle();
      gesture = await halfway(tester, -210);
      expect(leadOf(tester), closeTo(-1, 0.1));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a turn tells the reader it began, before anything moves', (
    tester,
  ) async {
    var began = 0;
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: BookFlip(
          pageCount: 20,
          spread: false,
          realistic: true,
          page: 4,
          onTurnStart: () => began++,
          onPageChanged: (_) {},
          pageBuilder: (context, p) => Center(child: Text('page $p')),
        ),
      ),
    );
    final gesture = await tester.startGesture(const Offset(200, 350));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(began, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
