import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/pinch_zoom.dart';

void main() {
  late List<double> changes;
  late int swipes;

  Future<void> pump(WidgetTester tester, {double value = 1}) async {
    changes = [];
    swipes = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        // A page swipe under the detector, as in the reader.
        child: GestureDetector(
          onHorizontalDragEnd: (_) => swipes++,
          child: PinchZoom(
            value: value,
            min: 0.8,
            max: 1.6,
            onChanged: changes.add,
            child: const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  /// Two fingers start [from] apart and end [to] apart, around the centre.
  Future<void> pinch(WidgetTester tester, double from, double to) async {
    final centre = tester.getCenter(find.byType(PinchZoom));
    final a = await tester.startGesture(centre - Offset(from / 2, 0));
    final b = await tester.startGesture(centre + Offset(from / 2, 0));
    for (var step = 1; step <= 5; step++) {
      final span = from + (to - from) * step / 5;
      await a.moveTo(centre - Offset(span / 2, 0));
      await b.moveTo(centre + Offset(span / 2, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pump();
  }

  testWidgets('spreading two fingers enlarges, once, on release', (
    tester,
  ) async {
    await pump(tester);
    await pinch(tester, 100, 130);
    expect(changes, hasLength(1));
    expect(changes.single, closeTo(1.3, 0.01));
    expect(swipes, 0, reason: 'the pinch is not a page swipe');
  });

  testWidgets('pinching in shrinks, and both ends are clamped', (tester) async {
    await pump(tester);
    await pinch(tester, 200, 40);
    expect(changes.single, 0.8);
    await pump(tester, value: 1.5);
    await pinch(tester, 100, 300);
    expect(changes.single, 1.6);
  });

  testWidgets('a reader pinch does not also resize the surrounding app', (
    tester,
  ) async {
    final appChanges = <double>[];
    final readerChanges = <double>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: PinchZoom(
          value: 1,
          min: 0.8,
          max: 1.6,
          onChanged: appChanges.add,
          child: PinchZoom(
            value: 1,
            min: 0.8,
            max: 1.6,
            onChanged: readerChanges.add,
            child: const ColoredBox(
              color: Color(0xFFFFFFFF),
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    final centre = tester.getCenter(find.byType(PinchZoom).last);
    final first = await tester.startGesture(centre - const Offset(50, 0));
    final second = await tester.startGesture(centre + const Offset(50, 0));
    await first.moveTo(centre - const Offset(70, 0));
    await second.moveTo(centre + const Offset(70, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
    expect(readerChanges.single, closeTo(1.4, 0.05));
    expect(appChanges, isEmpty);
  });

  testWidgets('one finger still swipes the page and changes nothing', (
    tester,
  ) async {
    await pump(tester);
    await tester.drag(find.byType(PinchZoom), const Offset(-200, 0));
    await tester.pump();
    expect(changes, isEmpty);
    expect(swipes, 1);
  });
}
