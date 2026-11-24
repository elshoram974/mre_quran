import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/bookmarks/application/bookmarks_provider.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/mushaf/presentation/mushaf_page.dart';
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

void main() {
  testWidgets('switching to a reading that has the page saved shows it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final root = Directory.systemTemp.createTempSync('switch');
    addTearDown(() => root.deleteSync(recursive: true));
    final server = FakePageServer();
    SvgPageStore storeOf(MushafEdition edition) => SvgPageStore(
      root: () async => Directory('${root.path}/${edition.id}'),
      manifest: () async => fixtureManifest(pages: 604),
      fetch: server.fetch,
    );
    // Hafs has page 10 on the phone; nothing else does, and it is offline.
    await tester.runAsync(() => storeOf(MushafEditions.hafs).fetch(10));
    server.offline = true;
    final settings = MemorySettingsRepository()
      ..settings = const AppSettings(
        readerMode: ReaderMode.printed,
        mushafEdition: MushafEditions.warsh,
      );
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
            MemoryReadingPositionRepository()..page = 10,
          ),
          settingsRepositoryProvider.overrideWithValue(settings),
          svgPageStoreProvider.overrideWith((ref, edition) => storeOf(edition)),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Scaffold(body: MushafPage()),
        ),
      ),
    );
    Future<void> settle() async {
      for (var i = 0; i < 60; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    final offer = find.text('هذه الصفحة محفوظة برواية حفص عن عاصم، اعرضها');
    expect(offer, findsOneWidget);
    await tester.tap(offer);
    await settle();
    expect(tester.takeException(), isNull);
    expect(settings.settings.mushafEdition, MushafEditions.hafs);
    expect(find.text('إعادة المحاولة'), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  testWidgets('in the reader, a retry once the internet is back shows the '
      'page', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final root = Directory.systemTemp.createTempSync('retry');
    addTearDown(() => root.deleteSync(recursive: true));
    final server = FakePageServer()..offline = true;
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
            MemoryReadingPositionRepository()..page = 10,
          ),
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository()
              ..settings = const AppSettings(
                readerMode: ReaderMode.printed,
                mushafEdition: MushafEditions.warsh,
              ),
          ),
          svgPageStoreProvider.overrideWith(
            (ref, edition) => SvgPageStore(
              root: () async => root,
              manifest: () async => fixtureManifest(pages: 604),
              fetch: server.fetch,
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
    // Downloading, writing and preparing a page each take real time, one
    // step after another.
    Future<void> settle() async {
      for (var i = 0; i < 60; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    server.offline = false;
    await tester.tap(find.text('إعادة المحاولة'));
    await settle();
    expect(tester.takeException(), isNull);
    // The page came down: no failure left on screen, and no blank page.
    expect(find.text('إعادة المحاولة'), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });
}
