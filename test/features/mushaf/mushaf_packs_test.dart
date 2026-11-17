import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/mushaf_packs.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
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
  pausedTitle: 'Paused',
  pausedBody: 'Tap resume',
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
        svgPageStoreProvider.overrideWith(
          (ref, edition) => SvgPageStore(
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

  /// Puts an archive where the system downloader writes it.
  File arrived(String extension, {List<int>? bytes}) =>
      File('${root.path}/mushaf/svg/hafs-kfqc/pack/hafs-kfqc-$extension.zip')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes ?? fixtureArchive(extension));

  const svgPath = 'svg/hafs-kfqc/pack/hafs-kfqc-svg.zip';
  const jsonPath = 'svg/hafs-kfqc/pack/hafs-kfqc-json.zip';

  Future<PackProgress> progress() =>
      container.read(mushafPackProvider(MushafEditions.hafs).future);

  Future<void> settled() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  test('starts empty: no page on the device, nothing running', () async {
    final state = await progress();
    expect((state.done, state.total), (0, 6));
    expect(state.active, isFalse);
    expect(state.partial, isFalse);
  });

  test('start downloads the two archives as one notified group', () async {
    await progress();
    await container
        .read(mushafPackProvider(MushafEditions.hafs).notifier)
        .start(_text);
    expect(downloader.notificationRequests, 1);
    expect(
      [
        for (final f
            in downloader.enqueued[MushafPack.groupOf(MushafEditions.hafs)]!)
          f.path,
      ],
      [svgPath, jsonPath],
    );
    expect(downloader.texts[MushafPack.groupOf(MushafEditions.hafs)], _text);
    final state = await progress();
    expect((state.active, state.transfer), (true, 0.0));
  });

  test('the progress follows the slower archive', () async {
    await progress();
    await container
        .read(mushafPackProvider(MushafEditions.hafs).notifier)
        .start(_text);
    downloader
      ..move(MushafPack.groupOf(MushafEditions.hafs), jsonPath, 1)
      ..move(MushafPack.groupOf(MushafEditions.hafs), svgPath, 0.4);
    await Future<void>.delayed(Duration.zero);
    expect((await progress()).transfer, 0.4);
    // Another group's download does not move it.
    downloader.move('something-else', svgPath, 0.9);
    await Future<void>.delayed(Duration.zero);
    expect((await progress()).transfer, 0.4);
  });

  test('arrived archives are installed, and the download ends', () async {
    await progress();
    await container
        .read(mushafPackProvider(MushafEditions.hafs).notifier)
        .start(_text);
    arrived('svg');
    arrived('json');
    downloader
      ..finish(MushafPack.groupOf(MushafEditions.hafs), svgPath)
      ..finish(MushafPack.groupOf(MushafEditions.hafs), jsonPath);
    await settled();
    final state = await progress();
    expect((state.done, state.total), (6, 6));
    expect(state.complete, isTrue);
    expect(state.active, isFalse);
    expect(state.installing, isFalse);
    expect(state.bytes, greaterThan(0));
  });

  test('an archive that came back broken installs nothing', () async {
    await progress();
    arrived('svg', bytes: '<html>503</html>'.codeUnits);
    downloader.finish(
      MushafPack.groupOf(MushafEditions.hafs),
      svgPath,
      ok: false,
    );
    await settled();
    final state = await progress();
    expect(state.done, 0);
    expect(state.installing, isFalse);
  });

  test(
    'while archives are unpacked, the pages ready so far are counted',
    () async {
      MushafPack.installPoll = const Duration(milliseconds: 5);
      addTearDown(() => MushafPack.installPoll = const Duration(seconds: 1));
      arrived('svg');
      arrived('json');
      final seen = <PackProgress>[];
      container.listen(mushafPackProvider(MushafEditions.hafs), (_, next) {
        if (next.value case final value?) seen.add(value);
      }, fireImmediately: true);
      await progress();
      await settled();
      // It said it was unpacking, and ended with every page and no spinner.
      expect(seen.any((state) => state.installing), isTrue);
      expect(seen.last.installing, isFalse);
      expect(seen.last.complete, isTrue);
      // The count never went backwards while unpacking.
      final counts = [for (final state in seen) state.done];
      expect(counts, [...counts]..sort());
    },
  );

  test('archives that arrived while the app was closed are installed when '
      'it opens', () async {
    arrived('svg');
    arrived('json');
    await progress();
    await settled();
    expect((await progress()).complete, isTrue);
  });

  test('files of another download group are ignored', () async {
    final before = await progress();
    downloader.finish('something-else', 'x');
    await settled();
    expect(await progress(), before);
  });

  test('a download cannot be started twice', () async {
    await progress();
    final notifier = container.read(
      mushafPackProvider(MushafEditions.hafs).notifier,
    );
    await notifier.start(_text);
    await notifier.start(_text);
    expect(downloader.notificationRequests, 1);
  });

  test('cancel keeps the pages; delete removes them', () async {
    arrived('svg');
    arrived('json');
    await progress();
    await settled();
    final notifier = container.read(
      mushafPackProvider(MushafEditions.hafs).notifier,
    );
    await notifier.cancel();
    expect(downloader.cancelled, [MushafPack.groupOf(MushafEditions.hafs)]);
    expect((await progress()).done, 6);
    await notifier.delete();
    expect((await progress()).done, 0);
    expect(
      Directory('${root.path}/mushaf/svg/hafs-kfqc').existsSync(),
      isFalse,
    );
  });

  test('coming back to the app collects what finished meanwhile', () async {
    await progress();
    arrived('svg');
    arrived('json');
    await container
        .read(mushafPackProvider(MushafEditions.hafs).notifier)
        .refresh();
    expect(downloader.resumes, 1);
    expect((await progress()).complete, isTrue);
  });
}
