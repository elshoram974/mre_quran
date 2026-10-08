import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
