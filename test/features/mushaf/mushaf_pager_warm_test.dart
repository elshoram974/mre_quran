import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// The printed reader on [page], recording which pages it asks for.
Future<Set<int>> _pump(
  WidgetTester tester, {
  required int page,
  Size size = const Size(390, 844),
  ReaderPageLayout layout = ReaderPageLayout.auto,
}) async {
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
            ),
        ),
        svgPageProvider.overrideWith((ref, page) async {
          asked.add(page);
          return fixturePage(page);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: MushafPage()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return asked;
}

void main() {
  testWidgets('the pages two turns each way are made ready, unseen', (
    tester,
  ) async {
    final asked = await _pump(tester, page: 10);
    expect(asked, {8, 9, 10, 11, 12});
    // Only the reader's page can be seen or touched.
    expect(find.byType(SvgPageView), findsOneWidget);
    expect(find.byType(SvgPageView, skipOffstage: false), findsNWidgets(5));
  });

  testWidgets('nothing is asked for before the first page or after the last', (
    tester,
  ) async {
    expect(await _pump(tester, page: 1), {1, 2, 3});
    await tester.pumpWidget(const SizedBox.shrink());
    expect(await _pump(tester, page: 604), {602, 603, 604});
  });

  testWidgets('a spread keeps the two spreads on each side ready', (
    tester,
  ) async {
    final asked = await _pump(
      tester,
      page: 10,
      size: const Size(1200, 800),
      layout: ReaderPageLayout.spread,
    );
    // Pages 9 and 10 face each other; two spreads each way.
    expect(asked, {5, 6, 7, 8, 9, 10, 11, 12, 13, 14});
  });
}
