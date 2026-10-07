import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/app_shimmer.dart';
import 'package:mre_quran/features/mushaf/application/page_image_providers.dart';
import 'package:mre_quran/features/mushaf/data/ayah_info_database.dart';
import 'package:mre_quran/features/mushaf/data/page_asset_store.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';
import 'package:mre_quran/features/mushaf/domain/page_geometry.dart';
import 'package:mre_quran/features/mushaf/presentation/line_spread.dart';
import 'package:mre_quran/features/mushaf/presentation/printed_page_view.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';
import 'package:mre_quran/features/quran_index/domain/quran_metadata.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/ayah_info_fixture.dart';

/// A 200 × 400 page with two black lines of one word each, on white paper
/// or on a transparent sheet.
Future<Uint8List> _pagePng({bool transparent = false}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (!transparent) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 200, 400),
      Paint()..color = Colors.white,
    );
  }
  final ink = Paint()..color = Colors.black;
  canvas
    ..drawRect(const Rect.fromLTRB(40, 60, 170, 120), ink)
    ..drawRect(const Rect.fromLTRB(60, 260, 160, 320), ink);
  final image = await recorder.endRecording().toImage(200, 400);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Where the test page's two words sit, as the markers would place them.
const _geometry = PageGeometry(
  words: [
    WordBox(
      ayah: AyahRef(1, 1),
      word: 1,
      line: 0,
      left: 0.2,
      right: 0.85,
      top: 0.12,
      bottom: 0.4,
    ),
    WordBox(
      ayah: AyahRef(1, 2),
      word: 1,
      line: 1,
      left: 0.3,
      right: 0.8,
      top: 0.6,
      bottom: 0.88,
    ),
  ],
  inkTop: 0.15,
  inkBottom: 0.8,
);

void main() {
  late QuranMetadata metadata;
  late Uint8List png;
  late Directory root;

  setUpAll(() {
    metadata = QuranMetadataParser.parse(
      File(QuranMetadataSource.assetPath).readAsStringSync(),
    );
  });
  setUp(() => root = Directory.systemTemp.createTempSync('printed_page'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<void> settle(WidgetTester tester, {Finder? until}) async {
    // Downloads, decoding, and measuring run on real time; wait until the
    // shimmer has given way to the page or the error, or [until] shows.
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final done = until == null
          ? find.byType(AppShimmer).evaluate().isEmpty
          : until.evaluate().isNotEmpty;
      if (done) break;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<List<AyahRef>> pump(
    WidgetTester tester, {
    required bool Function() online,
    Brightness brightness = Brightness.light,
    MushafStyle style = MushafStyle.madinahHd,
    List<Override> extra = const [],
    VoidCallback? onTap,
    bool withFallback = false,
    Duration fallbackAfter = const Duration(seconds: 30),
    Future<Uint8List> Function(Uri)? fetch,
  }) async {
    png = (await tester.runAsync(
      () => _pagePng(transparent: style == MushafStyle.madinah),
    ))!;
    final pressed = <AyahRef>[];
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        pageAssetStoreProvider.overrideWithValue(
          PageAssetStore(
            root: () async => root,
            fetch:
                fetch ??
                (uri) async {
                  if (!online()) throw PageDownloadException(uri, 'offline');
                  return png;
                },
          ),
        ),
        ...extra,
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: ThemeData(brightness: brightness),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: PrintedPageView(
              metadata: metadata,
              style: style,
              page: 1,
              onTap: onTap ?? () {},
              onAyahLongPress: pressed.add,
              selected: const AyahRef(1, 2),
              fallbackAfter: fallbackAfter,
              fallbackBuilder: withFallback
                  ? (_) => const Center(child: Text('نص الصفحة'))
                  : null,
            ),
          ),
        ),
      ),
    );
    return pressed;
  }

  testWidgets('shows a shimmer, then the page', (tester) async {
    await pump(tester, online: () => true);
    expect(find.byType(AppShimmer), findsOneWidget);
    await settle(tester);
    expect(find.byType(AppShimmer), findsNothing);
    expect(find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'), findsOneWidget);
  });

  testWidgets('long press finds the ayah under the finger', (tester) async {
    final pressed = await pump(
      tester,
      online: () => true,
      extra: [
        pageGeometryProvider((style: MushafStyle.madinahHd, page: 1))
            .overrideWith((ref) => _geometry),
      ],
    );
    await settle(tester);
    final label = find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع');
    final page = tester.getRect(label);
    final area = tester.getSize(
      find.ancestor(of: label, matching: find.byType(Center)).first,
    );
    // The test page's ink runs from 60 to 320 of 400 pixels.
    final crop = printedCropFor(
      MushafEdition.madinahHd,
      inkTop: 0.15,
      inkBottom: 0.8,
      area: area,
    );
    // Map an image point to the screen through the shown crop.
    Offset at(double x, double y) {
      return Offset(
        page.left +
            (x / 200 - crop.left) / (crop.right - crop.left) * page.width,
        page.top +
            (y / 400 - crop.top) / (crop.bottom - crop.top) * page.height,
      );
    }

    await tester.longPressAt(at(100, 90));
    await tester.longPressAt(at(110, 290));
    expect(pressed, [const AyahRef(1, 1), const AyahRef(1, 2)]);
  });

  testWidgets('a tap toggles the bars and splashes the ayah, then it fades', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      online: () => true,
      onTap: () => taps++,
      extra: [
        pageGeometryProvider((style: MushafStyle.madinahHd, page: 1))
            .overrideWith((ref) => _geometry),
      ],
    );
    await settle(tester);
    final page = tester.getRect(
      find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
    );
    await tester.tapAt(page.center - Offset(0, page.height * 0.18));
    await tester.pump(const Duration(milliseconds: 100));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    // The splash is not a selection: it is gone after it fades.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('printedCropFor', () {
    test('fills the width and centres on the ink when it fits', () {
      final crop = printedCropFor(
        MushafEdition.madinahHd,
        inkTop: 0.12,
        inkBottom: 0.88,
        area: const Size(340, 700),
      );
      final fits = 700 / (340 / (crop.right - crop.left) / 0.5);
      expect(crop.bottom - crop.top, closeTo(fits, 1e-9));
      expect((crop.top + crop.bottom) / 2, closeTo(0.5, 1e-9));
      expect(crop.top, lessThan(0.12));
      expect(crop.bottom, greaterThan(0.88));
    });

    test('shows a tall page whole, scaled down', () {
      final crop = printedCropFor(
        MushafEdition.madinahHd,
        inkTop: 0.04,
        inkBottom: 0.97,
        area: const Size(340, 600),
      );
      expect(crop.top, closeTo(0.032, 1e-9));
      expect(crop.bottom, closeTo(0.978, 1e-9));
    });

    test('never reads outside the image', () {
      for (final inkTop in [0.0, 0.3, 0.6]) {
        final crop = printedCropFor(
          MushafEdition.madinahHd,
          inkTop: inkTop,
          inkBottom: inkTop + 0.3,
          area: const Size(340, 500),
        );
        expect(crop.top, greaterThanOrEqualTo(0));
        expect(crop.bottom, lessThanOrEqualTo(1));
      }
      final wide = printedCropFor(
        MushafEdition.madinahHd,
        inkTop: 0.2,
        inkBottom: 0.8,
        area: const Size(300, 2000),
      );
      expect((wide.top, wide.bottom), (0, 1));
    });
  });

  testWidgets('Quran.com pages show at once and select from the database', (
    tester,
  ) async {
    // Two lines in the database's 1024 × 1656 space: ayah 1:1 on top, 1:2
    // lower down.
    final file = writeAyahInfo(root, [
      [1, 1, 1, 1, 1, 100, 900, 250, 500],
      [1, 2, 1, 2, 1, 200, 800, 1100, 1300],
    ]);
    final database = AyahInfoDatabase.open(file);
    addTearDown(database.close);
    final pressed = await pump(
      tester,
      online: () => true,
      style: MushafStyle.madinah,
      extra: [ayahInfoDatabaseProvider.overrideWith((ref) async => database)],
    );
    await settle(tester);
    final page = tester.getRect(
      find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
    );
    // The page is spread over the whole area, its rows apart.
    final geometry = glyphGeometry(
      database.page(1),
      width: 1024,
      height: 1656,
      lines: printedLinesOnPage(1),
    );
    final edition = MushafEdition.madinah;
    final spread = LineSpread.fit(
      cuts: geometry.lineCuts,
      crop: edition.crop,
      aspect: edition.width / edition.height,
      area: page.size,
    )!;
    Offset at(double x, double y) => Offset(
      page.left + x / 1024 * page.width,
      page.top + spread.toScreen(y / 1656),
    );
    await tester.longPressAt(at(500, 400));
    await tester.longPressAt(at(500, 1200));
    await tester.longPressAt(at(500, 800));
    expect(pressed, [const AyahRef(1, 1), const AyahRef(1, 2)]);
  });

  testWidgets('offline shows an error with retry that recovers', (
    tester,
  ) async {
    var online = false;
    await pump(tester, online: () => online, brightness: Brightness.dark);
    await settle(tester);
    expect(
      find.text('تعذّر تحميل الصفحة. تأكد من الاتصال بالإنترنت.'),
      findsOneWidget,
    );
    online = true;
    await tester.tap(find.text('إعادة المحاولة'));
    await settle(
      tester,
      until: find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
    );
    expect(find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'), findsOneWidget);
  });

  group('text fallback', () {
    testWidgets('offline, the page shows as text at once, with a retry', (
      tester,
    ) async {
      var online = false;
      await pump(tester, online: () => online, withFallback: true);
      await settle(tester, until: find.text('نص الصفحة'));
      expect(find.text('نص الصفحة'), findsOneWidget);
      expect(
        find.text('صورة الصفحة غير متاحة الآن، فيُعرض النص.'),
        findsOneWidget,
      );
      online = true;
      await tester.tap(find.text('إعادة المحاولة'));
      await settle(
        tester,
        until: find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
      );
      expect(find.text('نص الصفحة'), findsNothing);
      expect(
        find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
        findsOneWidget,
      );
    });

    testWidgets('a download that takes too long gives way to the text, then '
        'the image takes over when it arrives', (tester) async {
      final arrive = Completer<Uint8List>();
      await pump(
        tester,
        online: () => true,
        withFallback: true,
        fallbackAfter: const Duration(milliseconds: 400),
        fetch: (_) => arrive.future,
      );
      expect(find.byType(AppShimmer), findsOneWidget);
      expect(find.text('نص الصفحة'), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('نص الصفحة'), findsOneWidget);
      arrive.complete(png);
      await settle(
        tester,
        until: find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
      );
      expect(find.text('نص الصفحة'), findsNothing);
    });

    testWidgets('a quick download never shows the text', (tester) async {
      await pump(tester, online: () => true, withFallback: true);
      await settle(tester);
      expect(find.text('نص الصفحة'), findsNothing);
      expect(
        find.bySemanticsLabel('الصفحة ١ من المصحف المطبوع'),
        findsOneWidget,
      );
    });
  });
}
