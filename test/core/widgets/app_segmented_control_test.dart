import 'package:flutter/foundation.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_segmented_control.dart';

enum _Place { first, second, third }

Future<List<_Place>> _pump(
  WidgetTester tester, {
  _Place value = _Place.first,
  TextDirection direction = TextDirection.rtl,
  double width = 360,
  Map<_Place, String>? segments,
}) async {
  final chosen = <_Place>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: AppSegmentedControl<_Place>(
                value: value,
                onChanged: chosen.add,
                segments:
                    segments ??
                    const {
                      _Place.first: 'A',
                      _Place.second: 'B',
                      _Place.third: 'C',
                    },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return chosen;
}

void main() {
  group('on Android', () {
    testWidgets('the chosen one is on a filled pill, bold, and says it is '
        'selected', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, value: _Place.second);
      final theme = AppTheme.light;
      final chosen = tester.widget<Text>(find.text('B'));
      final other = tester.widget<Text>(find.text('A'));
      TextStyle styleOf(String label) => tester
          .widget<AnimatedDefaultTextStyle>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(AnimatedDefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(chosen.data, 'B');
      expect(other.data, 'A');
      expect(styleOf('B').fontWeight, FontWeight.w700);
      expect(styleOf('B').color, theme.colorScheme.onPrimary);
      expect(styleOf('A').fontWeight, FontWeight.w500);
      expect(
        tester.getSemantics(find.bySemanticsLabel('B')),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('A')),
        isSemantics(isSelected: false, isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets('a tap chooses; the chosen one does nothing', (tester) async {
      final chosen = await _pump(tester);
      await tester.tap(find.text('C'));
      await tester.tap(find.text('A'));
      expect(chosen, [_Place.third]);
    });

    testWidgets('labels that fit share the width; in right to left the first '
        'is at the right', (tester) async {
      await _pump(tester);
      expect(find.byType(SingleChildScrollView), findsNothing);
      final a = tester.getCenter(find.text('A')).dx;
      final c = tester.getCenter(find.text('C')).dx;
      expect(a, greaterThan(c));
    });

    testWidgets('labels that do not fit scroll, and the chosen one comes into '
        'view', (tester) async {
      const long = {
        _Place.first: 'A very long first label',
        _Place.second: 'A very long second label',
        _Place.third: 'A very long third label',
      };
      await _pump(tester, width: 240, segments: long);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _pump(tester, width: 240, segments: long, value: _Place.third);
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(SingleChildScrollView));
      final third = tester.getRect(find.text('A very long third label'));
      expect(bar.overlaps(third), isTrue);
    });
  });

  group('on iOS', () {
    for (final direction in TextDirection.values) {
      testWidgets('the glass control keeps the order of reading '
          '(${direction.name})', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final chosen = await _pump(tester, direction: direction);
        expect(find.byType(GlassSegmentedControl), findsOneWidget);
        final a = tester.getCenter(find.text('A')).dx;
        final c = tester.getCenter(find.text('C')).dx;
        // The first segment is at the start: the right in Arabic.
        expect(a > c, direction == TextDirection.rtl);
        await tester.tap(find.text('C'));
        await tester.pumpAndSettle();
        expect(chosen.last, _Place.third);
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });
}
