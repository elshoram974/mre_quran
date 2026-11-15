import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/mushaf_packs.dart';
import 'package:mre_quran/features/mushaf/application/svg_page_providers.dart';
import 'package:mre_quran/features/mushaf/data/pack_downloader.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';

import '../../helpers/fake_pack_downloader.dart';
import '../../helpers/svg_page_fixtures.dart';

const _text = PackNotificationText(
  runningTitle: 'Downloading',
  runningBody: '{progress}',
  completeTitle: 'Done',
  completeBody: 'Offline now',
  errorTitle: 'Failed',
  errorBody: 'Open settings',
);

void main() {
  late Directory root;
  late FakePackDownloader downloader;
  late ProviderContainer container;

  setUp(() {
    MushafPack.settleDelay = const Duration(milliseconds: 10);
    root = Directory.systemTemp.createTempSync('mushaf_pack');
    downloader = FakePackDownloader();
    container = ProviderContainer(
      overrides: [
        packDownloaderProvider.overrideWithValue(downloader),
        svgPageStoreProvider.overrideWithValue(
          SvgPageStore(
            root: () async => root,
            manifest: () async => fixtureManifest(),
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

  /// Writes a file the way the system downloader does: as it came.
  File downloaded(String name, String content) =>
      File('${root.path}/mushaf/svg/hafs-kfqc/$name')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

  Future<PackProgress> progress() => container.read(mushafPackProvider.future);

  test('counts the sound files on the device, two per page', () async {
    downloaded('001.svg', fixtureSvg);
    downloaded('001.json', fixtureJson);
    downloaded('002.svg', fixtureSvg);
    final state = await progress();
    expect(state.total, 6);
    expect(state.done, 3);
    expect(state.partial, isTrue);
    expect(state.bytes, greaterThan(0));
  });

  test(
    'a file that fails its checksum does not count and is removed',
    () async {
      final bad = downloaded('001.svg', '<html>503</html>');
      expect((await progress()).done, 0);
      expect(bad.existsSync(), isFalse);
    },
  );

  test('start downloads only what is missing, as one notified group', () async {
    downloaded('001.svg', fixtureSvg);
    await progress();
    await container.read(mushafPackProvider.notifier).start(_text);
    expect(downloader.notificationRequests, 1);
    final files = downloader.enqueued[MushafPack.group]!;
    expect(files, hasLength(5));
    expect(files.map((f) => f.path), isNot(contains('svg/hafs-kfqc/001.svg')));
    expect(downloader.texts[MushafPack.group], _text);
    final state = await progress();
    expect((state.active, state.done), (true, 1));
  });

  test(
    'a finished file is checked, counted, and the last ends the download',
    () async {
      await progress();
      await container.read(mushafPackProvider.notifier).start(_text);
      downloaded('001.svg', fixtureSvg);
      downloader
        ..running[MushafPack.group] = 1
        ..finish(MushafPack.group, 'svg/hafs-kfqc/001.svg');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final state = await progress();
      expect(state.done, 1);
      expect(state.active, isFalse);
    },
  );

  test('an error page that came back as a file is dropped', () async {
    await progress();
    final bad = downloaded('001.svg', '<html>503</html>');
    downloader.finish(MushafPack.group, 'svg/hafs-kfqc/001.svg');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect((await progress()).done, 0);
    expect(bad.existsSync(), isFalse);
  });

  test('files of another download group are ignored', () async {
    final before = await progress();
    downloader.finish('something-else', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await progress(), before);
  });

  test('cancel keeps the files; delete removes them', () async {
    downloaded('002.json', fixtureJson);
    await progress();
    final notifier = container.read(mushafPackProvider.notifier);
    await notifier.cancel();
    expect(downloader.cancelled, [MushafPack.group]);
    expect((await progress()).done, 1);
    await notifier.delete();
    expect((await progress()).done, 0);
    expect(
      Directory('${root.path}/mushaf/svg/hafs-kfqc').existsSync(),
      isFalse,
    );
  });

  test('coming back to the app collects what finished meanwhile', () async {
    await progress();
    downloaded('003.svg', fixtureSvg);
    await container.read(mushafPackProvider.notifier).refresh();
    expect(downloader.resumes, 1);
    expect((await progress()).done, 1);
  });
}
