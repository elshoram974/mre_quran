import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/printed_fallback.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/memory_settings_repository.dart';
import '../../helpers/svg_page_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FakePageServer server;
  late MemorySettingsRepository settings;
  late ProviderContainer container;

  ProviderContainer make(AppSettings saved) {
    settings = MemorySettingsRepository()..settings = saved;
    return ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settings),
        svgPageStoreProvider.overrideWith(
          (ref, edition) => SvgPageStore(
            root: () async => root,
            manifest: () async => fixtureManifest(),
            fetch: server.fetch,
          ),
        ),
      ],
    );
  }

  setUp(() async {
    root = Directory.systemTemp.createTempSync('printed_fallback');
    server = FakePageServer();
    container = make(const AppSettings(readerMode: ReaderMode.printed));
    await container.read(settingsProvider.future);
  });
  tearDown(() {
    container.dispose();
    root.deleteSync(recursive: true);
  });

  PrintedFallback fallback() =>
      container.read(printedFallbackProvider.notifier);
  AppSettings current() => container.read(settingsProvider).value!;
  PrintedFallbackChange? lastChange() =>
      container.read(printedFallbackProvider)?.change;

  test('offline, the printed Mushaf turns to text, saved and said', () async {
    await fallback().offline();
    expect(current().readerMode, ReaderMode.text);
    expect(current().textUntilOnline, isTrue);
    // Kept, so it is still so when the app opens again.
    expect(settings.settings.readerMode, ReaderMode.text);
    expect(settings.settings.textUntilOnline, isTrue);
    expect(lastChange(), PrintedFallbackChange.toText);
  });

  test('a reading whose text is not the app\'s stays printed', () async {
    container.dispose();
    container = make(
      AppSettings(
        readerMode: ReaderMode.printed,
        mushafEdition: MushafEditions.all.firstWhere(
          (edition) => !edition.matchesAppText,
        ),
      ),
    );
    await container.read(settingsProvider.future);
    await fallback().offline();
    expect(current().readerMode, ReaderMode.printed);
    expect(current().textUntilOnline, isFalse);
    expect(lastChange(), isNull);
  });

  test('text the person chose is left alone', () async {
    await container
        .read(settingsProvider.notifier)
        .chooseReaderMode(ReaderMode.text);
    await fallback().offline();
    expect(current().textUntilOnline, isFalse);
    expect(lastChange(), isNull);
    // Nor is it switched back to printed when pages can be had.
    await fallback().retry(1);
    expect(current().readerMode, ReaderMode.text);
    expect(server.requests, isEmpty);
  });

  test('while still offline, trying again keeps the text', () async {
    await fallback().offline();
    server.offline = true;
    await fallback().retry(2);
    expect(current().readerMode, ReaderMode.text);
    expect(current().textUntilOnline, isTrue);
    // Page 2 was tried again: its two files are asked for together.
    expect(
      {
        for (final uri in server.requests.reversed.take(2))
          uri.pathSegments.last,
      },
      {'002.svg', '002.json'},
    );
  });

  test('once a page downloads, the printed Mushaf is back', () async {
    await fallback().offline();
    await fallback().retry(2);
    expect(current().readerMode, ReaderMode.printed);
    expect(current().textUntilOnline, isFalse);
    expect(settings.settings.readerMode, ReaderMode.printed);
    expect(lastChange(), PrintedFallbackChange.toPrinted);
    // The page the reader was on was the one tried, and it is now kept.
    expect(
      await container
          .read(svgPageStoreProvider(MushafEditions.hafs))
          .isOnDevice(2),
      isTrue,
    );
  });

  test('a page the reader has is passed over for one it has not', () async {
    final store = container.read(svgPageStoreProvider(MushafEditions.hafs));
    await store.fetch(2);
    server.requests.clear();
    await fallback().offline();
    server.offline = true;
    await fallback().retry(2);
    // Page 2 opens offline and proves nothing: page 3 was tried, its two
    // files together.
    expect(
      {for (final uri in server.requests) uri.pathSegments.last},
      {'003.svg', '003.json'},
    );
    expect(current().readerMode, ReaderMode.text);
  });

  test(
    'a server that answers with an error means the internet is back',
    () async {
      await fallback().offline();
      server.tamper = true;
      await fallback().retry(1);
      expect(current().readerMode, ReaderMode.printed);
    },
  );

  test('with every page on the device, the printed Mushaf is back at '
      'once', () async {
    final store = container.read(svgPageStoreProvider(MushafEditions.hafs));
    for (final page in [1, 2, 3]) {
      await store.fetch(page);
    }
    server.requests.clear();
    await fallback().offline();
    server.offline = true;
    await fallback().retry(1);
    expect(current().readerMode, ReaderMode.printed);
    expect(server.requests, isEmpty);
    // Said for what it is: the pages are on the phone; the internet is not
    // back.
    expect(lastChange(), PrintedFallbackChange.toPrintedSaved);
  });

  test(
    'a download that finished while the app was closed is unpacked, '
    'and the printed Mushaf is back saying the pages are on the phone',
    () async {
      await fallback().offline();
      server.offline = true;
      for (final kind in ['svg', 'json']) {
        File('${root.path}/mushaf/svg/hafs-kfqc/pack/hafs-kfqc-$kind.zip')
          ..createSync(recursive: true)
          ..writeAsBytesSync(fixtureArchive(kind));
      }
      await fallback().retry(2);
      expect(current().readerMode, ReaderMode.printed);
      expect(server.requests, isEmpty);
      expect(lastChange(), PrintedFallbackChange.toPrintedSaved);
    },
  );

  test('once a page of a Mushaf not all on the phone downloads, it says the '
      'internet is back', () async {
    await fallback().offline();
    await fallback().retry(2);
    expect(lastChange(), PrintedFallbackChange.toPrinted);
  });

  group('another reading, whose text is not the app\'s', () {
    setUp(() async {
      container.dispose();
      container = make(
        AppSettings(
          readerMode: ReaderMode.printed,
          mushafEdition: MushafEditions.all.firstWhere(
            (edition) => !edition.matchesAppText,
          ),
        ),
      );
      await container.read(settingsProvider.future);
    });

    test('offline, the person may read the text in its place; the printed '
        'reading comes back with the internet', () async {
      await fallback().readTextInstead(offline: true);
      expect(current().readerMode, ReaderMode.text);
      expect(current().textUntilOnline, isTrue);
      expect(lastChange(), PrintedFallbackChange.toTextChosen);
      await fallback().retry(1);
      expect(current().readerMode, ReaderMode.printed);
      expect(lastChange(), PrintedFallbackChange.toPrinted);
    });

    test('when the server failed, the text is the person\'s choice and '
        'stays', () async {
      await fallback().readTextInstead(offline: false);
      expect(current().readerMode, ReaderMode.text);
      expect(current().textUntilOnline, isFalse);
      expect(lastChange(), isNull);
    });
  });

  test('it keeps trying by itself while the text stands in', () async {
    PrintedFallback.retryEvery = const Duration(milliseconds: 20);
    addTearDown(() => PrintedFallback.retryEvery = const Duration(seconds: 30));
    container.dispose();
    container = make(const AppSettings(readerMode: ReaderMode.printed));
    await container.read(settingsProvider.future);
    server.offline = true;
    await fallback().offline();
    // The page the reader is on, as the reader says when it turns to it.
    await fallback().retry(1);
    expect(current().readerMode, ReaderMode.text);
    server.offline = false;
    // A retry comes every 20 ms; on a busy machine the page may take longer
    // to come down and be checked, so wait for the switch, up to a limit.
    for (
      var i = 0;
      i < 100 && current().readerMode != ReaderMode.printed;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(current().readerMode, ReaderMode.printed);
  });

  test(
    'when the app opens still showing text, it tries from the start',
    () async {
      container.dispose();
      container = make(
        const AppSettings(readerMode: ReaderMode.text, textUntilOnline: true),
      );
      await container.read(settingsProvider.future);
      await fallback().retry(3);
      expect(current().readerMode, ReaderMode.printed);
      expect(current().textUntilOnline, isFalse);
    },
  );
}
