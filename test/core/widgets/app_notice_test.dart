import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_notice.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget notice, {
  ThemeData? theme,
  TextDirection direction = TextDirection.rtl,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: Center(child: notice)),
        ),
      ),
    ),
  );
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('an important notice is red, boxed, with its button inside in '
        '$name', (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        AppNotice(
          'Allow it',
          important: true,
          action: FilledButton(
            onPressed: () => pressed++,
            child: const Text('Allow'),
          ),
        ),
        theme: theme,
      );
      final red = theme.colorScheme.error;
      expect(tester.widget<Text>(find.text('Allow it')).style?.color, red);
      expect(tester.widget<Icon>(find.byType(Icon)).color, red);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppNotice),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(box.decoration, isA<BoxDecoration>());
      expect((box.decoration as BoxDecoration).border, isNotNull);
      // The button is inside the box.
      expect(
        find.descendant(
          of: find.descendant(
            of: find.byType(AppNotice),
            matching: find.byType(DecoratedBox),
          ),
          matching: find.text('Allow'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Allow'));
      expect(pressed, 1);
    });
  }

  testWidgets('a plain notice is muted and has no box', (tester) async {
    await _pump(tester, const AppNotice('Just so you know'));
    expect(
      tester.widget<Text>(find.text('Just so you know')).style?.color,
      AppTheme.light.colorScheme.onSurfaceVariant,
    );
    expect(
      find.descendant(
        of: find.byType(AppNotice),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('an error is red and announced, but not boxed', (tester) async {
    await _pump(tester, const AppNotice('It failed', error: true));
    expect(
      tester.widget<Text>(find.text('It failed')).style?.color,
      AppTheme.light.colorScheme.error,
    );
    expect(
      find.descendant(
        of: find.byType(AppNotice),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('an important notice fits large text on a narrow screen, in '
      'either direction', (tester) async {
    for (final direction in TextDirection.values) {
      await _pump(
        tester,
        AppNotice(
          'قد يؤخّر أندرويد التنبيه بضع دقائق ما لم يُسمح بالمنبّهات الدقيقة.',
          important: true,
          action: FilledButton(
            onPressed: () {},
            child: const Text('السماح بالتوقيت الدقيق'),
          ),
        ),
        direction: direction,
        textScale: 2,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
