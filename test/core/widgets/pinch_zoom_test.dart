import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/pinch_zoom.dart';

void main() {
  late List<double> changes;
  late List<double> live;
  late int swipes;

  Future<void> pump(WidgetTester tester, {double value = 1}) async {
    changes = [];
    live = [];
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
            onChanging: live.add,
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

  testWidgets('spreading two fingers enlarges the text as they move, and '
      'keeps the size once, on release', (tester) async {
    await pump(tester);
    await pinch(tester, 100, 130);
    // The size follows the fingers, in steps, and ends where they ended.
    expect(live.length, greaterThan(1));
    expect(live, orderedEquals([...live]..sort()));
    expect(live.last, closeTo(1.3, PinchZoom.step));
    expect(changes, hasLength(1));
    expect(changes.single, live.last);
    expect(swipes, 0, reason: 'the pinch is not a page swipe');
  });

  testWidgets('the content is drawn as it is, never magnified', (tester) async {
    await pump(tester);
    await pinch(tester, 100, 200);
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('sizes come in steps, not at every pixel', (tester) async {
    await pump(tester);
    await pinch(tester, 100, 130);
    for (final size in live) {
      expect(
        (size / PinchZoom.step) - (size / PinchZoom.step).round(),
        closeTo(0, 1e-9),
      );
    }
  });

  testWidgets('pinching in shrinks, and both ends are clamped', (tester) async {
    await pump(tester);
    await pinch(tester, 200, 40);
    expect(changes.single, 0.8);
    await pump(tester, value: 1.5);
    await pinch(tester, 100, 300);
    expect(changes.single, 1.6);
  });

  testWidgets('a pinch that ends where it began keeps nothing', (tester) async {
    await pump(tester);
    await pinch(tester, 100, 100);
    expect(changes, isEmpty);
  });

  testWidgets('the size the owner shows while pinching does not compound', (
    tester,
  ) async {
    // The owner moves [value] as the fingers do, as a reader showing the
    // size at once would; the pinch still counts from where it began.
    var shown = 1.0;
    late StateSetter update;
    final kept = <double>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PinchZoom(
              value: shown,
              min: 0.8,
              max: 1.6,
              onChanging: (value) => update(() => shown = value),
              onChanged: kept.add,
              child: const ColoredBox(
                color: Color(0xFFFFFFFF),
                child: SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
    await pinch(tester, 100, 130);
    expect(kept.single, closeTo(1.3, PinchZoom.step));
  });

  testWidgets('one finger still swipes the page and changes nothing', (
    tester,
  ) async {
    await pump(tester);
    await tester.drag(find.byType(PinchZoom), const Offset(-200, 0));
    await tester.pump();
    expect(changes, isEmpty);
    expect(live, isEmpty);
    expect(swipes, 1);
  });

  group('PinchOut', () {
    late int pinchedOut;

    Future<void> pumpOut(WidgetTester tester) async {
      pinchedOut = 0;
      swipes = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: GestureDetector(
            onHorizontalDragEnd: (_) => swipes++,
            child: PinchOut(
              onPinchOut: () => pinchedOut++,
              child: const ColoredBox(
                color: Color(0xFFFFFFFF),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> pinchOut(WidgetTester tester, double from, double to) async {
      final centre = tester.getCenter(find.byType(PinchOut));
      final a = await tester.startGesture(centre - Offset(from / 2, 0));
      final b = await tester.startGesture(centre + Offset(from / 2, 0));
      for (var step = 1; step <= 8; step++) {
        final span = from + (to - from) * step / 8;
        await a.moveTo(centre - Offset(span / 2, 0));
        await b.moveTo(centre + Offset(span / 2, 0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pump();
    }

    testWidgets('spreading two fingers reports once, and draws nothing', (
      tester,
    ) async {
      await pumpOut(tester);
      await pinchOut(tester, 100, 220);
      expect(pinchedOut, 1);
      expect(swipes, 0);
      // The content is not scaled.
      expect(find.byType(Transform), findsNothing);
    });

    testWidgets('a small spread or a pinch in reports nothing', (tester) async {
      await pumpOut(tester);
      await pinchOut(tester, 100, 108);
      await pinchOut(tester, 200, 80);
      expect(pinchedOut, 0);
    });

    testWidgets('each pinch reports again', (tester) async {
      await pumpOut(tester);
      await pinchOut(tester, 100, 200);
      await pinchOut(tester, 100, 200);
      expect(pinchedOut, 2);
    });

    testWidgets('one finger still swipes the page', (tester) async {
      await pumpOut(tester);
      await tester.fling(find.byType(PinchOut), const Offset(-300, 0), 1500);
      expect(swipes, 1);
      expect(pinchedOut, 0);
    });
  });
}
