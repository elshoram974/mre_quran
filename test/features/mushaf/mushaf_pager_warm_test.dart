import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/application/page_prefetcher.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page.dart';
import 'package:mre_quran/features/mushaf/presentation/svg_page_view.dart';
import 'package:mre_quran/features/quran_index/application/quran_metadata_provider.dart';
import 'package:mre_quran/features/quran_text/application/quran_text_providers.dart';
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

/// The printed reader on [page], recording which pages it asks for.
Future<Set<int>> _pump(
  WidgetTester tester, {
  required int page,
  Size size = const Size(390, 844),
  ReaderPageLayout layout = ReaderPageLayout.auto,
  MushafEdition edition = MushafEditions.hafs,
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
        bookmarksRepositoryProvider.overrideWithValue(
          MemoryBookmarksRepository(),
        ),
        readingPositionRepositoryProvider.overrideWithValue(
          MemoryReadingPositionRepository()..page = page,
        ),
        settingsRepositoryProvider.overrideWithValue(
          MemorySettingsRepository()
            ..settings = AppSettings(
              readerMode: ReaderMode.printed,
              readerPageLayout: layout,
              mushafEdition: edition,
            ),
        ),
        svgPageProvider.overrideWith((ref, request) async {
          asked.add(request.page);
          _stretches[request.page] = request.stretch;
          return fixturePicture(request);
        }),
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
  await tester.pump(const Duration(milliseconds: 400));
  return asked;
}

void main() {
  testWidgets('the pages ahead of the reader, and one behind, are made '
      'ready, unseen', (tester) async {
    final asked = await _pump(tester, page: 10);
    expect(asked, {9, 10, 11, 12, 13});
    // They are prepared without being built: only the reader's page is a
    // widget.
    expect(find.byType(SvgPageView, skipOffstage: false), findsOneWidget);
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

  group('a reading other than the app\'s own text', () {
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
}
