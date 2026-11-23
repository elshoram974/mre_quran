import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/core/l10n/l10n.dart';
import 'package:mre_quran/features/mushaf/application/page_elsewhere.dart';
import 'package:mre_quran/features/mushaf/application/printed_fallback.dart';
import 'package:mre_quran/features/mushaf/application/reading_position_provider.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/mushaf/presentation/page_elsewhere_options.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/memory_reading_position_repository.dart';
import '../../helpers/memory_settings_repository.dart';
import '../../helpers/svg_page_fixtures.dart';

void main() {
  late Directory root;
  late MemorySettingsRepository settings;
  late MemoryReadingPositionRepository position;
  final server = FakePageServer();

  setUp(() {
    root = Directory.systemTemp.createTempSync('elsewhere');
    settings = MemorySettingsRepository()
      ..settings = const AppSettings(
        readerMode: ReaderMode.printed,
        mushafEdition: MushafEditions.warsh,
      );
    position = MemoryReadingPositionRepository()..page = 2;
  });
  tearDown(() => root.deleteSync(recursive: true));

  /// Each reading keeps its pages in its own folder.
  SvgPageStore storeOf(MushafEdition edition) => SvgPageStore(
    root: () async => Directory('${root.path}/${edition.id}'),
    manifest: () async => fixtureManifest(),
    fetch: server.fetch,
  );

  List<Override> overrides() => [
    settingsRepositoryProvider.overrideWithValue(settings),
    readingPositionRepositoryProvider.overrideWithValue(position),
    svgPageStoreProvider.overrideWith((ref, edition) => storeOf(edition)),
  ];

  test('names the readings that have the page, and the nearest page this '
      'reading has', () async {
    await storeOf(MushafEditions.hafs).fetch(2);
    await storeOf(MushafEditions.warsh).fetch(3);
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    final found = await container.read(
      pageElsewhereProvider((edition: MushafEditions.warsh, page: 2)).future,
    );
    expect(found.readings, [MushafEditions.hafs]);
    expect(found.nearest, 3);
    final none = await container.read(
      pageElsewhereProvider((edition: MushafEditions.qalon, page: 1)).future,
    );
    expect(none.readings, isEmpty);
    expect(none.isEmpty, isTrue);
  });

  test('opening another reading shows it printed, and says so', () async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);
    await container
        .read(printedFallbackProvider.notifier)
        .openReading(MushafEditions.hafs);
    expect(settings.settings.mushafEdition, MushafEditions.hafs);
    expect(settings.settings.readerMode, ReaderMode.printed);
    expect(settings.settings.textUntilOnline, isFalse);
    expect(
      container.read(printedFallbackProvider)?.change,
      PrintedFallbackChange.toSavedReading,
    );
  });

  Future<void> pumpOptions(WidgetTester tester, {String locale = 'ar'}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const Scaffold(
            body: PageElsewhereOptions(edition: MushafEditions.warsh, page: 2),
          ),
        ),
      ),
    );
    // The stores look at real files, one after another: each look needs a
    // moment of real time.
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  testWidgets('offers the reading that has the page, and opens it', (
    tester,
  ) async {
    await tester.runAsync(() => storeOf(MushafEditions.hafs).fetch(2));
    await pumpOptions(tester);
    final offer = find.text('هذه الصفحة محفوظة برواية حفص عن عاصم، اعرضها');
    expect(offer, findsOneWidget);
    await tester.tap(offer);
    await tester.pump();
    expect(settings.settings.mushafEdition, MushafEditions.hafs);
  });

  testWidgets('with no reading that has it, offers the nearest saved page', (
    tester,
  ) async {
    await tester.runAsync(() => storeOf(MushafEditions.warsh).fetch(3));
    await pumpOptions(tester, locale: 'en');
    // In the app's digits, Arabic by default.
    final offer = find.text('Go to the nearest saved page (٣)');
    expect(offer, findsOneWidget);
    await tester.tap(offer);
    await tester.pump();
    expect(position.page, 3);
  });

  testWidgets('nothing saved anywhere: nothing offered', (tester) async {
    await pumpOptions(tester);
    expect(find.byType(TextButton), findsNothing);
  });
}
