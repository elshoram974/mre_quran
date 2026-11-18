import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/widgets/app_hero_card.dart';
import 'package:mre_quran/core/widgets/app_icon_badge.dart';
import 'package:mre_quran/core/widgets/app_surface_card.dart';
import 'package:mre_quran/core/widgets/app_tile_card.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.rtl,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _decorationOf(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byType(AppSurfaceCard),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  group('AppSurfaceCard', () {
    testWidgets('rests on the raised fill, and tints when highlighted', (
      tester,
    ) async {
      final scheme = AppTheme.light.colorScheme;
      await _pump(tester, const AppSurfaceCard(child: Text('ذكر')));
      expect(_decorationOf(tester).color, scheme.surfaceContainerLowest);
      expect(_decorationOf(tester).boxShadow, isNotEmpty);

      await _pump(
        tester,
        const AppSurfaceCard(highlighted: true, child: Text('ذكر')),
        disableAnimations: true,
      );
      expect(_decorationOf(tester).color, scheme.primaryContainer);
    });

    testWidgets('lifts above the page in dark mode', (tester) async {
      final scheme = AppTheme.dark.colorScheme;
      await _pump(
        tester,
        const AppSurfaceCard(child: Text('dhikr')),
        theme: AppTheme.dark,
        direction: TextDirection.ltr,
      );
      expect(_decorationOf(tester).color, scheme.surfaceContainerLow);
    });

    testWidgets('gives list rows a Material to paint on', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppSurfaceCard(
          child: ListTile(title: const Text('row'), onTap: () => taps++),
        ),
      );
      await tester.tap(find.text('row'));
      expect(tester.takeException(), isNull);
      expect(taps, 1);
    });

    testWidgets('is one tap target with onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppSurfaceCard(onTap: () => taps++, child: const Text('open')),
      );
      await tester.tap(find.byType(AppSurfaceCard));
      expect(taps, 1);
    });
  });

  group('AppIconBadge', () {
    testWidgets('is hidden from screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const AppIconBadge.text('٣'));
      expect(find.bySemanticsLabel('٣'), findsNothing);
      handle.dispose();
    });

    testWidgets('takes the size it is given', (tester) async {
      await _pump(
        tester,
        const Center(
          child: AppIconBadge(Icons.star, size: AppIconBadgeSize.large),
        ),
      );
      expect(tester.getSize(find.byType(AppIconBadge)), const Size.square(72));
    });
  });

  group('AppHeroCard', () {
    testWidgets('colours its text with the on-container role', (tester) async {
      final scheme = AppTheme.dark.colorScheme;
      await _pump(
        tester,
        const AppHeroCard(watermark: Icons.mosque, child: Text('الظهر')),
        theme: AppTheme.dark,
      );
      final style = DefaultTextStyle.of(tester.element(find.text('الظهر')))
          .style;
      expect(style.color, scheme.onPrimaryContainer);
    });

    testWidgets('fits with large text in English', (tester) async {
      await _pump(
        tester,
        const AppHeroCard(
          watermark: Icons.mosque,
          child: Text('Next prayer: Dhuhr in 2 hours 15 minutes'),
        ),
        direction: TextDirection.ltr,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppTileCard', () {
    testWidgets('keeps the badge beside the text at normal size', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTileCard(icon: Icons.access_time, title: 'مواقيت', onTap: () {}),
      );
      final badge = tester.getCenter(find.byType(AppIconBadge));
      final title = tester.getCenter(find.text('مواقيت'));
      expect((badge.dy - title.dy).abs(), lessThan(1));
      // Arabic: the badge leads from the right.
      expect(badge.dx, greaterThan(title.dx));
    });

    testWidgets('moves the badge above the text with large text', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTileCard(
          icon: Icons.access_time,
          title: 'Prayer times',
          subtitle: 'Dhuhr · 12:03 · in 2 h 15 min',
          onTap: () {},
        ),
        direction: TextDirection.ltr,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final badge = tester.getRect(find.byType(AppIconBadge));
      final title = tester.getRect(find.text('Prayer times'));
      expect(badge.bottom, lessThanOrEqualTo(title.top));
    });

    testWidgets('moves a trailing action below large text without a badge', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTileCard(
          title: 'Prayer times',
          subtitle: 'The next prayer and its time',
          trailing: FilledButton(onPressed: () {}, child: const Text('Add')),
        ),
        direction: TextDirection.ltr,
        textScale: 2,
      );
      final subtitle = tester.getRect(
        find.text('The next prayer and its time'),
      );
      final action = tester.getRect(find.text('Add'));
      expect(action.top, greaterThanOrEqualTo(subtitle.bottom));
      expect(tester.takeException(), isNull);
    });
  });
}
