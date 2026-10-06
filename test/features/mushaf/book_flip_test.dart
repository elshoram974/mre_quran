import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/presentation/flip/book_flip.dart';

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

  testWidgets('single: the sheet peels off and uncovers the next page', (
    tester,
  ) async {
    await _pump(tester, realistic: true, spread: false);
    final gesture = await tester.startGesture(const Offset(100, 350));
    for (var i = 0; i < 30; i++) {
      await gesture.moveBy(const Offset(7, 0));
      await tester.pump(const Duration(milliseconds: 8));
    }
    // Mid-turn the next page lies under the sheet, in place; the page before
    // does not come in.
    final next = tester.getRect(find.text('page 6'));
    expect(next.center.dx, closeTo(200, 1));
    expect(find.text('page 4').hitTestable(), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 6').hitTestable(), findsOneWidget);
    expect(find.text('page 5').hitTestable(), findsNothing);
  });

  testWidgets('cannot turn before the first page or past the last', (
    tester,
  ) async {
    final first = await _pump(tester, realistic: true, spread: false, page: 1);
    await _drag(tester, -300);
    expect(first, isEmpty);
  });
}
