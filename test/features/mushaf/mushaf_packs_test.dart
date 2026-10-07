import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/mushaf_packs.dart';
import 'package:mre_quran/features/mushaf/application/page_image_providers.dart';
import 'package:mre_quran/features/mushaf/data/pack_downloader.dart';
import 'package:mre_quran/features/mushaf/data/page_asset_store.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/fake_pack_downloader.dart';

const _text = PackNotificationText(
  runningTitle: 'Downloading',
  runningBody: '{progress}',
  completeTitle: 'Done',
  completeBody: 'Offline now',
  errorTitle: 'Failed',
  errorBody: 'Open settings',
);

final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0, //
]);

final _webp = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50, //
]);

void main() {
  final tajweed = MushafEdition.tajweed;
  late Directory root;
  late FakePackDownloader downloader;
  late ProviderContainer container;

  setUp(() {
    MushafPacks.settleDelay = const Duration(milliseconds: 10);
    root = Directory.systemTemp.createTempSync('mushaf_packs');
    downloader = FakePackDownloader();
    container = ProviderContainer(
      overrides: [
        packDownloaderProvider.overrideWithValue(downloader),
        pageAssetStoreProvider.overrideWithValue(
          PageAssetStore(
            root: () async => root,
            fetch: (_) async => throw StateError('no network in this test'),
          ),
        ),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    root.deleteSync(recursive: true);
  });

  File file(String path, List<int> bytes) => File('${root.path}/mushaf/$path')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  Future<PackProgress> progress(MushafEdition edition) async =>
      (await container.read(mushafPacksProvider.future))[edition.style]!;

  test(
    'counts the files on disk; an edition with two themes needs both',
    () async {
      file(tajweed.imagePath(1, dark: false), _png);
      file(tajweed.imagePath(1, dark: true), _png);
      file(tajweed.imagePath(2, dark: false), _webp);
      final packs = await container.read(mushafPacksProvider.future);
      expect(packs[MushafStyle.tajweed]!.total, 1208);
      expect(packs[MushafStyle.tajweed]!.done, 3);
      expect(packs[MushafStyle.madinah]!.total, 604);
      expect(packs[MushafStyle.madinah]!.done, 0);
      expect(packs[MushafStyle.tajweed]!.partial, isTrue);
    },
  );

  test('a broken file does not count', () async {
    file(tajweed.imagePath(1, dark: false), '<html>503</html>'.codeUnits);
    expect((await progress(tajweed)).done, 0);
  });

  test('start downloads only what is missing, as one notified group', () async {
    file(tajweed.imagePath(1, dark: false), _png);
    await container.read(mushafPacksProvider.future);
    await container.read(mushafPacksProvider.notifier).start(tajweed, _text);
    expect(downloader.notificationRequests, 1);
    final files = downloader.enqueued['mushaf-tajweed']!;
    expect(files, hasLength(1207));
    expect(
      files.map((f) => f.path),
      isNot(contains('images/tajweed/light/p1.png')),
    );
    expect(downloader.texts['mushaf-tajweed'], _text);
    final state = await progress(tajweed);
    expect((state.active, state.done), (true, 1));
  });

  test(
    'a finished file is counted, and the last one ends the download',
    () async {
      await container.read(mushafPacksProvider.future);
      final notifier = container.read(mushafPacksProvider.notifier);
      await notifier.start(MushafEdition.madinahHd, _text);
      final first = MushafEdition.madinahHd.packFiles.first;
      file(first.path, _png);
      downloader
        ..running['mushaf-madinahHd'] = 1
        ..finish('mushaf-madinahHd', first.path);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final state = await progress(MushafEdition.madinahHd);
      expect(state.done, 1);
      expect(state.active, isFalse);
    },
  );

  test('an error page that came back as a file is dropped', () async {
    await container.read(mushafPacksProvider.future);
    final page = MushafEdition.madinahHd.packFiles.first;
    final bad = file(page.path, '<html>503</html>'.codeUnits);
    downloader.finish('mushaf-madinahHd', page.path);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect((await progress(MushafEdition.madinahHd)).done, 0);
    expect(bad.existsSync(), isFalse);
  });

  test('cancel keeps the files; delete removes them', () async {
    file(tajweed.imagePath(7, dark: false), _png);
    await container.read(mushafPacksProvider.future);
    final notifier = container.read(mushafPacksProvider.notifier);
    await notifier.cancel(tajweed);
    expect(downloader.cancelled, ['mushaf-tajweed']);
    expect((await progress(tajweed)).done, 1);
    await notifier.delete(tajweed);
    expect((await progress(tajweed)).done, 0);
    expect(
      Directory('${root.path}/mushaf/images/tajweed').existsSync(),
      isFalse,
    );
  });

  test('image paths keep the type of the source', () {
    expect(tajweed.imagePath(5, dark: true), 'images/tajweed/dark/p5.png');
    expect(
      MushafEdition.madinah.imagePath(5, dark: true),
      'images/madinah/light/p5.png',
    );
  });
}
