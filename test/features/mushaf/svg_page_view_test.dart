import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/core/theme/app_palette.dart';
import 'package:mre_quran/core/theme/app_theme.dart';
import 'package:mre_quran/core/theme/app_tokens.dart';
import 'package:mre_quran/core/theme/quran_colors.dart';
import 'package:mre_quran/core/widgets/empty_state.dart';
import 'package:mre_quran/core/widgets/pinch_zoom.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_compiler.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_parser.dart';
import 'package:mre_quran/features/mushaf/domain/svg_page.dart';
import 'package:mre_quran/features/mushaf/presentation/reader_page_labels.dart';
import 'package:mre_quran/features/mushaf/presentation/surah_banner.dart';
import 'package:mre_quran/features/mushaf/presentation/svg_page_view.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/quran_text/domain/ayah_range.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/svg_page_fixtures.dart';

void main() {
  final metadata = QuranMetadataParser.parse(
    File('assets/quran/quran-data.xml').readAsStringSync(),
  );

  Future<void> pump(
    WidgetTester tester, {
    required Future<SvgPagePicture> Function(SvgPageRequest request) load,
    int page = 3,
    Locale locale = const Locale('ar'),
    ThemeData? theme,
    AyahRange? selected,
    Set<AyahRef> bookmarked = const {},
    VoidCallback? onTap,
    ValueChanged<AyahRef>? onAyahLongPress,
    ValueChanged<AyahRef>? onAyahTap,
    WidgetBuilder? fallbackBuilder,
    Duration fallbackAfter = const Duration(seconds: 30),
    Size size = const Size(390, 844),
    bool fillWidth = false,
    VoidCallback? onPinchOut,
    VoidCallback? onOffline,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          svgPageProvider.overrideWith((ref, request) => load(request)),
        ],
        child: MaterialApp(
          locale: locale,
          theme: theme ?? AppTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Scaffold(
            body: SvgPageView(
              metadata: metadata,
              page: page,
              onTap: onTap ?? () {},
              onAyahLongPress: onAyahLongPress,
              onAyahTap: onAyahTap,
              selected: selected,
              bookmarked: bookmarked,
              fallbackBuilder: fallbackBuilder,
              fallbackAfter: fallbackAfter,
              fillWidth: fillWidth,
              onPinchOut: onPinchOut,
              onOffline: onOffline,
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

  testWidgets('spreading two fingers on a printed page asks for a bigger way '
      'to read, without zooming or turning it', (tester) async {
    var pinched = 0;
    var taps = 0;
    await pump(
      tester,
      load: (request) async => fixturePicture(request),
      onPinchOut: () => pinched++,
      onTap: () => taps++,
    );
    final center = tester.getCenter(find.byType(PinchOut));
    final first = await tester.startGesture(center - const Offset(50, 0));
    final second = await tester.startGesture(center + const Offset(50, 0));
    await first.moveTo(center - const Offset(70, 0));
    await second.moveTo(center + const Offset(70, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();
    expect(pinched, 1);
    expect(taps, 0);
    // The artwork does not enlarge or scroll: it is drawn as it is.
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(PinchZoom), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draws the script in the ink colour and the ayah numbers in '
      'the accent', (tester) async {
    final theme = AppTheme.of(AppPaper.green, AppAccent.crimson);
    await pump(
      tester,
      load: (request) async => fixturePicture(request),
      theme: theme,
    );
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
      load: (request) async => fixturePicture(request),
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

  testWidgets('while ayahs are being chosen, a tap on one reports it; a tap '
      'beside every ayah is still passed on', (tester) async {
    final page = fixturePage(3);
    final tapped = <AyahRef>[];
    var taps = 0;
    final region = page.layout.regions[2];
    await pump(
      tester,
      load: (request) async => fixturePicture(request),
      selected: AyahRange(page.layout.regions.first.ref, region.ref),
      onAyahTap: tapped.add,
      onTap: () => taps++,
    );
    final ring = region.rings.first;
    await tester.tapAt(
      onScreen(
        tester,
        page,
        (ring[0].x + ring[2].x) / 2,
        (ring[0].y + ring[2].y) / 2,
      ),
    );
    await tester.pump();
    expect(tapped, [region.ref]);
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page sits the same way in Arabic and in English', (
    tester,
  ) async {
    // A printed page reads the same in every app language: it must not
    // mirror with the app.
    final page = fixturePage(3);
    await pump(tester, load: (request) async => fixturePicture(request));
    final arabic = tester.getRect(find.byType(SvgPicture).first);
    final pressed = <AyahRef>[];
    await pump(
      tester,
      load: (request) async => fixturePicture(request),
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
      await pump(
        tester,
        load: (request) async => fixturePicture(request),
        size: size,
      );
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
    await pump(
      tester,
      load: (_) async => SvgPageCompiler.compile(opening),
      page: 1,
    );
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
      load: (page) => Future.delayed(
        const Duration(seconds: 2),
        () => fixturePicture(page),
      ),
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
      load: (page) async => offline
          ? throw const SocketException('offline')
          : fixturePicture(page),
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

  testWidgets('a page that cannot be had offline says so to its owner; one '
      'the server refused does not', (tester) async {
    var offline = 0;
    await pump(
      tester,
      load: (page) async => throw PageDownloadException(
        Uri.parse('https://example.test/003.svg'),
        'SocketException',
        unreachable: true,
      ),
      fallbackBuilder: (_) => const Text('typeset page'),
      onOffline: () => offline++,
    );
    expect(offline, greaterThan(0));

    offline = 0;
    await pump(
      tester,
      page: 4,
      load: (page) async => throw PageDownloadException(
        Uri.parse('https://example.test/004.svg'),
        'HTTP 404',
      ),
      fallbackBuilder: (_) => const Text('typeset page'),
      onOffline: () => offline++,
    );
    expect(offline, 0);
    // The text still stands in for that one page.
    expect(find.text('typeset page'), findsOneWidget);
  });

  testWidgets('a slow page gives way to the text after the wait', (
    tester,
  ) async {
    await pump(
      tester,
      load: (page) => Future.delayed(
        const Duration(minutes: 5),
        () => fixturePicture(page),
      ),
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

  group('on a screen taller than the page', () {
    testWidgets('the lines spread until the page fills the height', (
      tester,
    ) async {
      await pump(
        tester,
        load: (request) async => spreadPicture(request),
        fillWidth: true,
      );
      final sheet = tester.getRect(find.byType(SvgPicture).first);
      final frame = tester.getRect(find.byType(SvgPageView));
      expect(sheet.width, closeTo(frame.width, 5));
      expect(sheet.height, closeTo(frame.height, 10));
      // The lines moved apart; the page was not scaled to fit.
      expect(sheet.height / (sheet.width * 550 / 345), greaterThan(1.3));
    });

    testWidgets('a surah name\'s frame goes around the name, moved with its '
        'line', (tester) async {
      // A name 60 wide and 24 tall on the line whose middle is at 98.
      const box = (left: 142.5, top: 88.0, right: 202.5, bottom: 112.0);
      SvgPagePicture named(SvgPagePicture picture) => SvgPagePicture(
        page: picture.page,
        ink: picture.ink,
        marks: picture.marks,
        layout: picture.layout,
        stretch: picture.stretch,
        titles: const [(surah: 3, box: box, line: 98)],
      );
      for (final fill in [false, true]) {
        await pump(
          tester,
          load: (request) async => named(spreadPicture(request)),
          fillWidth: fill,
        );
        final sheet = tester.getRect(find.byType(SvgPicture).first);
        final scale = sheet.width / 345;
        final stretch = sheet.height / (550 * scale);
        final moved = (98 - 0) * (stretch - 1);
        final name = Rect.fromLTRB(
          sheet.left + box.left * scale,
          sheet.top + (box.top + moved) * scale,
          sheet.left + box.right * scale,
          sheet.top + (box.bottom + moved) * scale,
        );
        final frame = tester.getRect(find.byType(SurahBanner));
        expect(frame.contains(name.topLeft), isTrue, reason: '$fill');
        expect(frame.contains(name.bottomRight), isTrue, reason: '$fill');
        expect(frame.center.dy, closeTo(name.center.dy, 0.5));
        expect(frame.width, greaterThan(sheet.width * 0.9));
      }
    });

    testWidgets('a very tall screen stops spreading and centres the page', (
      tester,
    ) async {
      await pump(
        tester,
        load: (request) async => spreadPicture(request),
        fillWidth: true,
        size: const Size(390, 1400),
      );
      final sheet = tester.getRect(find.byType(SvgPicture).first);
      final frame = tester.getRect(find.byType(SvgPageView));
      expect(
        sheet.height,
        closeTo(sheet.width * 550 / 345 * AppTokens.readerMaxLineSpread, 1),
      );
      expect(sheet.center.dy, closeTo(frame.center.dy, 1));
    });

    testWidgets('a page whose lines are unclear keeps its printed height, '
        'centred', (tester) async {
      await pump(
        tester,
        load: (request) async => fixturePicture(request),
        fillWidth: true,
      );
      final sheet = tester.getRect(find.byType(SvgPicture).first);
      final frame = tester.getRect(find.byType(SvgPageView));
      expect(sheet.height, closeTo(sheet.width * 550 / 345, 1));
      expect(sheet.center.dy, closeTo(frame.center.dy, 1));
    });

    testWidgets('a long press still finds the ayah under the finger', (
      tester,
    ) async {
      final picked = <AyahRef>[];
      await pump(
        tester,
        load: (request) async => spreadPicture(request),
        fillWidth: true,
        onAyahLongPress: picked.add,
      );
      final sheet = tester.getRect(find.byType(SvgPicture).first);
      // The lower line's ayah band runs from 117 to 154 of the page's 550.
      await tester.longPressAt(
        Offset(sheet.center.dx, sheet.top + sheet.height * 135 / 550),
      );
      await tester.longPressAt(
        Offset(sheet.center.dx, sheet.top + sheet.height * 98 / 550),
      );
      expect(picked, [const AyahRef(2, 7), const AyahRef(2, 6)]);
    });

    testWidgets('a screen shorter than the page scrolls it, unspread', (
      tester,
    ) async {
      await pump(
        tester,
        load: (request) async => spreadPicture(request),
        fillWidth: true,
        size: const Size(844, 390),
      );
      final sheet = tester.getRect(find.byType(SvgPicture).first);
      expect(sheet.height, closeTo(sheet.width * 550 / 345, 1));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  testWidgets('the printed page carries no labels over it', (tester) async {
    await pump(tester, load: (request) async => fixturePicture(request));
    expect(find.byType(ReaderPageLabels), findsNothing);
  });

  testWidgets('offline, a page with no text to stand in says so and points '
      'to the offline download', (tester) async {
    await pump(
      tester,
      load: (_) async => throw const SocketException('offline'),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('لا يوجد إنترنت الآن'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    // It says what is saved, and the button says what to do.
    expect(find.textContaining('الصفحات التي فتحتها من قبل'), findsOneWidget);
    expect(find.text('نزّل الرواية كلها'), findsOneWidget);
  });

  testWidgets('the store\'s own "could not reach the server" reads as '
      'offline too', (tester) async {
    await pump(
      tester,
      load: (_) async => throw PageDownloadException(
        Uri.parse('https://example.test/003.svg'),
        'SocketException',
        unreachable: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('لا يوجد إنترنت الآن'), findsOneWidget);
  });
}
