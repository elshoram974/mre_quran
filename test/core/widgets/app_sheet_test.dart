import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_sheet.dart';

void main() {
  for (final expandable in [false, true]) {
    testWidgets(
      'a ${expandable ? 'draggable' : 'short'} sheet stays above the keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => AppSheet.show<void>(
                    context: context,
                    expandable: expandable,
                    builder: (_) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(key: Key('field')),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // The keyboard opens: 300 px come off the bottom of the screen.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        final field = tester.getRect(find.byKey(const Key('field')));
        expect(field.bottom, lessThanOrEqualTo(500));
        expect(field.top, greaterThan(0));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a short sheet clears the system bar at the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    // The 3-button navigation bar of an edge-to-edge Android phone.
    tester.view.padding = const FakeViewPadding(bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    double? insetSeenByBody;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AppSheet.show<void>(
                context: context,
                builder: (context) {
                  insetSeenByBody = MediaQuery.paddingOf(context).bottom;
                  return const SizedBox(
                    height: 40,
                    child: Text('last', key: Key('last')),
                  );
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const Key('last'))).bottom,
      lessThanOrEqualTo(800 - 48),
    );
    // The sheet took the inset: a body that also pads for it would double it.
    expect(insetSeenByBody, 0);
  });

  testWidgets('dragging a short sheet down dismisses it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AppSheet.show<void>(
                context: context,
                builder: (_) =>
                    const SizedBox(height: 120, child: Text('body')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('body'), findsOneWidget);
    await tester.fling(find.text('body'), const Offset(0, 400), 1500);
    await tester.pumpAndSettle();
    expect(find.text('body'), findsNothing);
  });

  Future<void> openSheet(
    WidgetTester tester, {
    bool expandable = false,
    Widget? above,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AppSheet.show<void>(
                context: context,
                expandable: expandable,
                above: above,
                // Longer than the sheet: it scrolls.
                builder: (_) => Column(
                  children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 48, child: Text('row $i')),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final expandable in [false, true]) {
    testWidgets('a ${expandable ? 'draggable' : 'short'} sheet that scrolls '
        'closes when pulled down from its top', (tester) async {
      await openSheet(tester, expandable: expandable);
      // Scrolled down, a pull down scrolls back first: the sheet stays.
      await tester.drag(find.text('row 3'), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(find.text('row 9'), const Offset(0, 150));
      await tester.pumpAndSettle();
      expect(find.text('row 9'), findsOneWidget);
      // Once back at the top, the same pull goes on to take the sheet away.
      await tester.drag(find.text('row 5'), const Offset(0, 650));
      await tester.pumpAndSettle();
      expect(find.text('row 5'), findsNothing);
    });
  }

  group('a draggable sheet rests where it is let go', () {
    double top(WidgetTester tester) =>
        tester.getTopLeft(find.byType(AppSheetDragArea).first).dy;

    // A slow drag of the handle, well under any flick's speed. It ends with
    // the finger lifted, before anything settles.
    Future<void> slowDrag(WidgetTester tester, double dy) => tester.timedDrag(
      find.byType(AppSheetDragArea).first,
      Offset(0, dy),
      const Duration(milliseconds: 800),
    );

    testWidgets('half way up, and half way down again', (tester) async {
      await openSheet(tester, expandable: true);
      final opened = top(tester);

      await slowDrag(tester, -100);
      final up = top(tester);
      await tester.pumpAndSettle();
      expect(up, lessThan(opened - 50));
      // Nothing snapped it anywhere once let go.
      expect(top(tester), closeTo(up, 1));

      await slowDrag(tester, 70);
      final down = top(tester);
      await tester.pumpAndSettle();
      expect(down, greaterThan(up + 30));
      expect(top(tester), closeTo(down, 1));
    });

    testWidgets('and can stay at half the screen', (tester) async {
      await openSheet(tester, expandable: true);
      // The sheet opens at 0.6 of 800 px; a 130 px pull leaves it near 0.46,
      // below the middle that used to close it.
      await slowDrag(tester, 130);
      final released = top(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AppSheetDragArea), findsOneWidget);
      expect(released, greaterThan(800 * 0.4 + 80));
      expect(top(tester), closeTo(released, 1));
    });

    testWidgets('a flick up reaches the top of the screen', (tester) async {
      await openSheet(tester, expandable: true);
      await tester.fling(
        find.byType(AppSheetDragArea).first,
        const Offset(0, -200),
        2000,
      );
      await tester.pumpAndSettle();
      expect(top(tester), closeTo(0, 1));
    });

    testWidgets('a pull down far enough closes it', (tester) async {
      await openSheet(tester, expandable: true);
      await slowDrag(tester, 400);
      await tester.pumpAndSettle();
      expect(find.byType(AppSheetDragArea), findsNothing);
    });
  });

  testWidgets('a short pull from the top lets the sheet spring back', (
    tester,
  ) async {
    await openSheet(tester);
    final top = tester.getTopLeft(find.text('row 0')).dy;
    await tester.drag(find.text('row 0'), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(find.text('row 0'), findsOneWidget);
    expect(tester.getTopLeft(find.text('row 0')).dy, top);
  });

  testWidgets('has one drag handle, and shows what floats above it', (
    tester,
  ) async {
    await openSheet(tester, above: const Text('the ayah'));
    // Material's own handle would be a second one over the sheet's.
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_DragHandle',
      ),
      findsNothing,
    );
    final above = tester.getRect(find.text('the ayah'));
    final first = tester.getRect(find.text('row 0'));
    expect(above.bottom, lessThan(first.top));
  });

  testWidgets('closing a sheet opened over another leaves the one under it '
      'open', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => AppSheet.showFilling<void>(
                context: context,
                builder: (context, scroll) => ListView(
                  controller: scroll,
                  children: [
                    const Text('under'),
                    TextButton(
                      onPressed: () => AppSheet.show<void>(
                        context: context,
                        expandable: true,
                        builder: (_) => Column(
                          children: [
                            for (var i = 0; i < 40; i++)
                              SizedBox(height: 48, child: Text('over $i')),
                          ],
                        ),
                      ),
                      child: const Text('pick'),
                    ),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    // Pulled all the way down: the sheet on top closes, and only it.
    await tester.drag(find.text('over 2'), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('over 2'), findsNothing);
    expect(find.text('under'), findsOneWidget);
  });
}
