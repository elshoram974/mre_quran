import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/widgets/pinch_zoom.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/application/page_prefetcher.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_pager.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page_view.dart';
import 'package:mre_quran/features/mushaf/presentation/svg_page_view.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
import 'package:mre_quran/features/quran_text/domain/quran_text.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_quran_metadata_source.dart';
import '../../helpers/fake_quran_text_source.dart';
import '../../helpers/memory_bookmarks_repository.dart';
import '../../helpers/memory_reading_position_repository.dart';
import '../../helpers/memory_settings_repository.dart';
import '../../helpers/svg_page_fixtures.dart';

/// The spread asked for with each page the reader last pumped asked for.
final Map<int, int> _stretches = {};

/// The settings store of the reader last pumped.
late MemorySettingsRepository _settings;

/// The printed reader on [page], recording which pages it asks for.
Future<Set<int>> _pump(
  WidgetTester tester, {
  required int page,
  Size size = const Size(390, 844),
  ReaderPageLayout layout = ReaderPageLayout.auto,
  MushafEdition edition = MushafEditions.hafs,
  bool textLate = false,
  bool untilDrawn = true,
  Set<int> offline = const {},
  SvgPageStore Function(MushafEdition edition)? stores,
}) async {
  _stretches.clear();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final asked = <int>{};
  final storage = Directory.systemTemp.createTempSync('warm');
  addTearDown(() => storage.deleteSync(recursive: true));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quranMetadataSourceProvider.overrideWithValue(
          FakeQuranMetadataSource(),
        ),
        quranTextSourceProvider.overrideWithValue(FakeQuranTextSource()),
        if (textLate)
          // The text is still being read.
          quranTextProvider.overrideWith(
            (ref) => Completer<QuranText>().future,
          ),
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository()..page = page,
        ),
        settingsRepositoryProvider.overrideWithValue(
          _settings = MemorySettingsRepository()
            ..settings = AppSettings(
              readerMode: ReaderMode.printed,
              readerPageLayout: layout,
              mushafEdition: edition,
            ),
        ),
        svgPageProvider.overrideWith((ref, request) async {
          asked.add(request.page);
          _stretches[request.page] = request.stretch;
          if (offline.contains(request.page)) {
            throw PageDownloadException(
              Uri.parse('https://example.test/${request.page}.svg'),
              'SocketException',
              unreachable: true,
            );
          }
          return fixturePicture(request);
        }),
        if (stores != null)
          svgPageStoreProvider.overrideWith((ref, edition) => stores(edition)),
        // Downloads are not this test's business.
        pagePrefetcherProvider.overrideWithValue(
          PagePrefetcher(
            SvgPageStore(
              root: () async => storage,
              manifest: () async => fixtureManifest(pages: 604),
              fetch: (uri) async => throw const SocketException('offline'),
            ),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Scaffold(body: MushafPage()),
      ),
    ),
  );
  await tester.pump();
  if (!untilDrawn) return asked;
  await tester.pump(const Duration(milliseconds: 400));
  // The page on screen is drawn; the pages around it are prepared next.
  await tester.pump();
  return asked;
}

void main() {
  testWidgets('at start-up the page on screen is prepared alone, before the '
      'pages around it', (tester) async {
    // The first frame: the page is asked for, not yet drawn.
    expect(await _pump(tester, page: 10, untilDrawn: false), {10});
  });

  testWidgets('the pages ahead of the reader, and one behind, are made '
      'ready, unseen', (tester) async {
    final asked = await _pump(tester, page: 10);
    expect(asked, {9, 10, 11, 12, 13});
    // They are prepared without being built: only the reader's page is a
    // widget.
    expect(find.byType(SvgPageView, skipOffstage: false), findsOneWidget);
  });

  testWidgets('the printed pages load while the text is still being read', (
    tester,
  ) async {
    final asked = await _pump(tester, page: 10, textLate: true);
    expect(asked, {9, 10, 11, 12, 13});
    expect(find.byType(SvgPageView), findsOneWidget);
  });

  testWidgets('nothing is asked for before the first page or after the last', (
    tester,
  ) async {
    expect(await _pump(tester, page: 1), {1, 2, 3, 4});
    await tester.pumpWidget(const SizedBox.shrink());
    expect(await _pump(tester, page: 604), {603, 604});
  });

  testWidgets('a spread keeps the spreads around it ready', (tester) async {
    final asked = await _pump(
      tester,
      page: 10,
      size: const Size(1200, 800),
      layout: ReaderPageLayout.spread,
    );
    // Pages 9 and 10 face each other; one spread behind, three ahead.
    expect(asked, {7, 8, 9, 10, 11, 12, 13, 14, 15, 16});
  });

  testWidgets('offline, a page not on the phone turns the whole Mushaf to '
      'text, saved in the settings and said', (tester) async {
    await _pump(tester, page: 10, offline: {10});
    await tester.pump(const Duration(milliseconds: 400));
    expect(_settings.settings.readerMode, ReaderMode.text);
    expect(_settings.settings.textUntilOnline, isTrue);
    expect(find.byType(SvgPageView), findsNothing);
    expect(find.byType(MushafPageView), findsOneWidget);
    expect(find.textContaining('فصار المصحف يُعرض نصًّا'), findsOneWidget);
  });

  testWidgets('turned to text offline, it offers a reading that has the page '
      'on the phone, and opens it', (tester) async {
    final saved = Directory.systemTemp.createTempSync('saved');
    addTearDown(() => saved.deleteSync(recursive: true));
    // Offline: nothing downloads; Warsh's page 10 was saved before.
    final server = FakePageServer();
    SvgPageStore storeOf(MushafEdition edition) => SvgPageStore(
      root: () async => Directory('${saved.path}/${edition.id}'),
      manifest: () async => fixtureManifest(pages: 604),
      fetch: server.fetch,
    );
    await tester.runAsync(() => storeOf(MushafEditions.warsh).fetch(10));
    server.offline = true;
    // Looking at real files takes real time here; wait for it.
    MushafPager.lookupWait = const Duration(minutes: 1);
    addTearDown(
      () => MushafPager.lookupWait = const Duration(milliseconds: 300),
    );
    await _pump(tester, page: 10, offline: {10}, stores: storeOf);
    // The stores look at real files, one after another.
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(_settings.settings.readerMode, ReaderMode.text);
    // The reading is named in the message; the button stays short.
    expect(find.textContaining('محفوظة برواية ورش عن نافع'), findsOneWidget);
    final offer = find.text('اعرضها');
    expect(offer, findsOneWidget);
    // Let the message finish coming in, then take its offer.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(offer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_settings.settings.mushafEdition, MushafEditions.warsh);
    expect(_settings.settings.readerMode, ReaderMode.printed);
  });

  testWidgets('a page out of sight that fails does not switch the Mushaf', (
    tester,
  ) async {
    // Page 11 is only made ready ahead; the reader is on page 10.
    await _pump(tester, page: 10, offline: {11});
    await tester.pump(const Duration(milliseconds: 400));
    expect(_settings.settings.readerMode, ReaderMode.printed);
    expect(find.byType(SvgPageView), findsOneWidget);
  });

  group('a reading other than the app\'s own text', () {
    testWidgets('offline, stays printed and says why on the page', (
      tester,
    ) async {
      await _pump(
        tester,
        page: 10,
        edition: MushafEditions.warsh,
        offline: {10},
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(_settings.settings.readerMode, ReaderMode.printed);
      expect(find.textContaining('لا يوجد إنترنت الآن'), findsOneWidget);

      // The person may read the app's text in its place, until the
      // internet is back.
      await tester.tap(find.text('اقرأ النص المكتوب (رواية حفص)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_settings.settings.readerMode, ReaderMode.text);
      expect(_settings.settings.textUntilOnline, isTrue);
      expect(find.byType(MushafPageView), findsOneWidget);
      expect(find.textContaining('برواية حفص، ويعود مصحف'), findsOneWidget);
    });

    testWidgets('has no Hafs text standing in and no bookmarks', (
      tester,
    ) async {
      await _pump(tester, page: 10, edition: MushafEditions.warsh);
      final view = tester.widget<SvgPageView>(find.byType(SvgPageView));
      expect(view.fallbackBuilder, isNull);
      expect(view.bookmarked, isEmpty);
      expect(view.selected, isNull);
    });

    testWidgets('Warsh, drawn line by line, has its lines spread', (
      tester,
    ) async {
      await _pump(tester, page: 10, edition: MushafEditions.warsh);
      expect(_stretches.values.toSet().single, greaterThan(1000));
    });

    testWidgets('one whose lines are not drawn in order has its lines '
        'spread too', (tester) async {
      await _pump(tester, page: 10, edition: MushafEditions.qalon);
      expect(_stretches.values.toSet().single, greaterThan(1000));
    });
  });

  testWidgets('Hafs asks for its lines spread on a tall screen, and offers '
      'ayah actions', (tester) async {
    await _pump(tester, page: 10);
    expect(_stretches.values.toSet().single, greaterThan(1000));
    final view = tester.widget<SvgPageView>(find.byType(SvgPageView));
    expect(view.onAyahLongPress, isNotNull);
    expect(view.fallbackBuilder, isNotNull);
  });

  Future<void> pinchOut(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(PinchOut));
    final first = await tester.startGesture(center - const Offset(50, 0));
    final second = await tester.startGesture(center + const Offset(50, 0));
    await first.moveTo(center - const Offset(90, 0));
    await second.moveTo(center + const Offset(90, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('spreading two fingers on a printed page, held upright, '
      'suggests turning the phone sideways, and does', (tester) async {
    final orientations = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientations.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, page: 10);
    await pinchOut(tester);
    expect(find.text('لتكبير الخط أكثر، أدر الهاتف بالعرض'), findsOneWidget);
    // The page itself was not enlarged.
    expect(find.byType(PinchZoom), findsNothing);

    await tester.tap(find.text('تدوير'));
    await tester.pump();
    expect(orientations, [
      ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight'],
    ]);
  });

  testWidgets('held sideways, the suggestion is the typeset text, and it '
      'switches to it', (tester) async {
    await _pump(tester, page: 10, size: const Size(844, 390));
    await pinchOut(tester);
    expect(find.text('للقراءة بخط أكبر، اعرض الصفحة كنص'), findsOneWidget);
    await tester.tap(find.text('عرض النص'));
    await tester.pumpAndSettle();
    expect(find.byType(SvgPageView), findsNothing);
  });

  testWidgets('pinching again straight away does not stack suggestions', (
    tester,
  ) async {
    await _pump(tester, page: 10);
    await pinchOut(tester);
    await pinchOut(tester);
    expect(find.text('لتكبير الخط أكثر، أدر الهاتف بالعرض'), findsOneWidget);
  });
}
