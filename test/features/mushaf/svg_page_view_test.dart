import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/theme/app_palette.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/quran_colors.dart';
import 'package:mre_quran/core/widgets/empty_state.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';
import 'package:mre_quran/features/mushaf/presentation/svg_page_view.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/svg_page_fixtures.dart';

void main() {
  final metadata = QuranMetadataParser.parse(
    File('assets/quran/quran-data.xml').readAsStringSync(),
  );

  Future<void> pump(
    WidgetTester tester, {
    required Future<SvgPage> Function(int page) load,
    int page = 3,
    Locale locale = const Locale('ar'),
    ThemeData? theme,
    AyahRef? selected,
    Set<AyahRef> bookmarked = const {},
    VoidCallback? onTap,
    ValueChanged<AyahRef>? onAyahLongPress,
    WidgetBuilder? fallbackBuilder,
    Duration fallbackAfter = const Duration(seconds: 30),
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [svgPageProvider.overrideWith((ref, page) => load(page))],
        child: MaterialApp(
          locale: locale,
          theme: theme ?? AppTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SvgPageView(
              metadata: metadata,
              page: page,
              onTap: onTap ?? () {},
              onAyahLongPress: onAyahLongPress,
              selected: selected,
              bookmarked: bookmarked,
              fallbackBuilder: fallbackBuilder,
              fallbackAfter: fallbackAfter,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// The two artwork layers: the script, then the ornaments.
  List<SvgPicture> layers(WidgetTester tester) =>
      tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();

  /// The screen point of a page point: the artwork fills its sheet with the
  /// visible part of the page.
  Offset onScreen(WidgetTester tester, SvgPage page, double x, double y) {
    final box = page.layout.content;
    final rect = tester.getRect(find.byType(SvgPicture).first);
    return Offset(
      rect.left + (x - box.left) / pageBoxWidth(box) * rect.width,
      rect.top + (y - box.top) / pageBoxHeight(box) * rect.height,
    );
  }

  testWidgets('draws the script in the ink colour and the ayah numbers in '
      'the accent', (tester) async {
    final theme = AppTheme.of(AppPaper.green, AppAccent.crimson);
    await pump(tester, load: (page) async => fixturePage(page), theme: theme);
    final colors = theme.extension<QuranColors>()!;
    final [script, ornaments] = layers(tester);
    expect(script.colorFilter, ColorFilter.mode(colors.ink, BlendMode.srcIn));
    expect(
      ornaments.colorFilter,
      ColorFilter.mode(colors.ayahNumber, BlendMode.srcIn),
    );
    expect(colors.ayahNumber, isNot(colors.ink));
    expect(find.bySemanticsLabel('الصفحة ٣ من المصحف المطبوع'), findsOneWidget);
  });

  testWidgets('a long press selects the ayah under the finger; a tap is '
      'passed on', (tester) async {
    final page = fixturePage(3);
    final pressed = <AyahRef>[];
    var taps = 0;
    await pump(
      tester,
      load: (_) async => page,
      onAyahLongPress: pressed.add,
      onTap: () => taps++,
    );
    for (final region in [page.layout.regions.first, page.layout.regions[3]]) {
      final ring = region.rings.first;
      await tester.longPressAt(
        onScreen(
          tester,
          page,
          (ring[0].x + ring[2].x) / 2,
          (ring[0].y + ring[2].y) / 2,
        ),
      );
      await tester.pump();
    }
    expect(pressed, [
      page.layout.regions.first.ref,
      page.layout.regions[3].ref,
    ]);

    await tester.tapAt(tester.getCenter(find.byType(SvgPicture).first));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('the page sits the same way in Arabic and in English', (
    tester,
  ) async {
    // A printed page reads the same in every app language: it must not
    // mirror with the app.
    final page = fixturePage(3);
    await pump(tester, load: (_) async => page);
    final arabic = tester.getRect(find.byType(SvgPicture).first);
    final pressed = <AyahRef>[];
    await pump(
      tester,
      load: (_) async => page,
      locale: const Locale('en'),
      onAyahLongPress: pressed.add,
    );
    expect(tester.getRect(find.byType(SvgPicture).first), arabic);
    final region = page.layout.regions.first;
    final ring = region.rings.first;
    await tester.longPressAt(
      onScreen(
        tester,
        page,
        (ring[0].x + ring[2].x) / 2,
        (ring[0].y + ring[2].y) / 2,
      ),
    );
    expect(pressed, [region.ref]);
  });

  testWidgets('fits inside the frame at compact, medium, and expanded '
      'widths', (tester) async {
    for (final size in const [
      Size(320, 640),
      Size(700, 900),
      Size(1100, 800),
    ]) {
      await pump(tester, load: (page) async => fixturePage(page), size: size);
      expect(tester.takeException(), isNull, reason: '$size');
      final sheet = tester.getRect(find.byType(SvgPicture).first);
      expect(sheet.width, lessThanOrEqualTo(size.width), reason: '$size');
      expect(sheet.height, lessThanOrEqualTo(size.height), reason: '$size');
      // The whole page keeps the proportions of its view box.
      expect(sheet.width / sheet.height, closeTo(345 / 550, 0.01));
    }
  });

  testWidgets('an opening page is shown cropped to its text, enlarged', (
    tester,
  ) async {
    final opening = SvgPageParser.page(
      1,
      svg: fixtureSvg.replaceFirst(
        'viewBox="0 0 345 550"',
        'viewBox="-53.3109 -198.4777 345 550"',
      ),
      json: File('test/fixtures/svg/001.json').readAsStringSync(),
    );
    await pump(tester, load: (_) async => opening, page: 1);
    expect(tester.takeException(), isNull);
    // The sheet takes the shape of the text block, not of the declared box,
    // and every ayah can still be pressed.
    final content = opening.layout.content;
    final sheet = tester.getRect(find.byType(SvgPicture).first);
    expect(
      sheet.width / sheet.height,
      closeTo(pageBoxWidth(content) / pageBoxHeight(content), 0.01),
    );
    expect(pageBoxWidth(content), lessThan(345));
    expect(
      opening.ink,
      isNot(contains('viewBox="-53.3109 -198.4777 345 550"')),
    );
  });

  testWidgets('shows a skeleton while loading, then the page', (tester) async {
    await pump(
      tester,
      load: (page) =>
          Future.delayed(const Duration(seconds: 2), () => fixturePage(page)),
    );
    expect(find.byType(SvgPicture), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  testWidgets('when the page cannot be had, the text stands in and retry '
      'brings the artwork', (tester) async {
    var offline = true;
    await pump(
      tester,
      load: (page) async =>
          offline ? throw const SocketException('offline') : fixturePage(page),
      fallbackBuilder: (_) => const Text('typeset page'),
    );
    expect(find.text('typeset page'), findsOneWidget);
    expect(
      find.text('صفحة المصحف المطبوع غير متاحة الآن، فيُعرض النص.'),
      findsOneWidget,
    );
    offline = false;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Let the text finish fading out.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.text('typeset page'), findsNothing);
  });

  testWidgets('a slow page gives way to the text after the wait', (
    tester,
  ) async {
    await pump(
      tester,
      load: (page) =>
          Future.delayed(const Duration(minutes: 5), () => fixturePage(page)),
      fallbackBuilder: (_) => const Text('typeset page'),
      fallbackAfter: const Duration(seconds: 3),
    );
    expect(find.text('typeset page'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('typeset page'), findsOneWidget);
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('without a stand-in, a failed page offers a retry', (
    tester,
  ) async {
    await pump(
      tester,
      load: (_) async => throw const SocketException('offline'),
      theme: AppTheme.dark,
      locale: const Locale('en'),
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
