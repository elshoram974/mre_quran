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
}
