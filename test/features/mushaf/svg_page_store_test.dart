import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/svg_manifest_parser.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

import '../../helpers/svg_page_fixtures.dart';

void main() {
  late Directory root;
  late FakePageServer server;
  late SvgPageStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('svg_store');
    server = FakePageServer();
    store = SvgPageStore(
      root: () async => root,
      manifest: () async => fixtureManifest(),
      fetch: server.fetch,
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  File stored(String name) => File('${root.path}/mushaf/svg/hafs-kfqc/$name');

  group('the bundled manifests', () {
    for (final edition in MushafEditions.all) {
      final file = File(edition.manifestAsset);

      test('${edition.id}: content matches the recorded SHA-256', () {
        final compact = jsonEncode(jsonDecode(file.readAsStringSync()));
        expect(
          sha256.convert(utf8.encode(compact)).toString(),
          edition.manifestSha256,
        );
      });

      test('${edition.id}: lists its own 604 pages and two archives', () {
        final manifest = SvgManifestParser.parse(file.readAsStringSync());
        expect(manifest.edition, edition.id);
        expect(manifest.pageCount, 604);
        expect(
          manifest.url(10, 'svg').toString(),
          'https://cdn.quran.ws/svg/pages/v1.1.1/${edition.id}/010.svg',
        );
        expect(
          [for (final archive in manifest.archives) archive.url.toString()],
          [
            for (final kind in ['svg', 'json'])
              'https://github.com/quran-ws/quran-svg/releases/download/'
                  'v1.1.1/${edition.id}-$kind.zip',
          ],
        );
      });
    }

    test('no two editions share a page file', () {
      // A page of one reading must never pass for a page of another.
      final seen = <String>{};
      for (final edition in MushafEditions.all) {
        final manifest = SvgManifestParser.parse(
          File(edition.manifestAsset).readAsStringSync(),
        );
        for (final page in manifest.pages) {
          expect(seen.add(page.svgSha256), isTrue, reason: edition.id);
        }
      }
    });

    final file = File(MushafEditions.hafs.manifestAsset);

    test('lists all 604 pages on the versioned, immutable folder', () {
      final manifest = SvgManifestParser.parse(file.readAsStringSync());
      expect(manifest.pageCount, 604);
      expect(manifest.edition, 'hafs-kfqc');
      expect(
        manifest.url(10, 'svg').toString(),
        'https://cdn.quran.ws/svg/pages/v1.1.1/hafs-kfqc/010.svg',
      );
      expect(
        manifest.entry(10).svgSha256,
        'ccbceb7ff356e89052bab82adef24bd95fece0cb36bd087633d3ae410f96600b',
      );
      expect(manifest.totalBytes, greaterThan(300 * 1000 * 1000));
      // Kept compressed, the whole Mushaf is about a quarter of that.
      expect(manifest.packedBytes, lessThan(manifest.totalBytes ~/ 3));
      // The two release archives, on the versioned release.
      expect(
        [for (final archive in manifest.archives) archive.name],
        ['hafs-kfqc-svg.zip', 'hafs-kfqc-json.zip'],
      );
      expect(
        manifest.archives.first.url.toString(),
        'https://github.com/quran-ws/quran-svg/releases/download/v1.1.1/'
        'hafs-kfqc-svg.zip',
      );
      expect(manifest.downloadBytes, greaterThan(100 * 1000 * 1000));
    });

    test('a broken manifest is rejected', () {
      expect(() => SvgManifestParser.parse('{}'), throwsFormatException);
      expect(
        () => SvgManifestParser.parse(
          '{"edition":"x","base":"https://x","packedBytes":1,"archives":[],'
          '"pages":[["zz","zz",1]]}',
        ),
        throwsFormatException,
      );
    });
  });

  test('downloads a page once, then reads it from the device', () async {
    final page = await store.page(2);
    expect(page.page, 2);
    expect(page.layout.regions, isNotEmpty);
    expect(page.ink, isNotEmpty);
    expect(page.marks, isNotEmpty);
    expect(page.stretch, 1);
    expect(
      [for (final uri in server.requests) uri.pathSegments.last],
      ['002.svg', '002.json'],
    );

    server.offline = true;
    final again = await store.page(2);
    expect(again.layout.regions.length, page.layout.regions.length);
    expect(server.requests, hasLength(2), reason: 'no second download');
  });

  test('many pages asked for at once are all prepared', () async {
    // Only two are prepared at a time; the rest wait their turn.
    final pages = await Future.wait([
      for (var page = 1; page <= 3; page++) store.page(page),
      store.page(1),
      store.page(2),
    ]);
    expect([for (final page in pages) page.page], [1, 2, 3, 1, 2]);
  });

  test('files are kept compressed, smaller than they came', () async {
    await store.fetch(1);
    expect(stored('001.svg.gz').existsSync(), isTrue);
    expect(stored('001.json.gz').existsSync(), isTrue);
    expect(stored('001.svg').existsSync(), isFalse);
    expect(stored('001.json.gz').lengthSync(), lessThan(fixtureJson.length));
  });

  test('a file that fails its checksum is refused and not kept', () async {
    server.tamper = true;
    await expectLater(
      store.page(1),
      throwsA(
        isA<PageDownloadException>().having(
          (e) => e.reason,
          'reason',
          'checksum mismatch',
        ),
      ),
    );
    expect(stored('001.svg.gz').existsSync(), isFalse);
    expect(stored('001.svg.gz.part').existsSync(), isFalse);

    // The real file is taken once it can be had.
    server.tamper = false;
    expect((await store.page(1)).page, 1);
  });

  test('concurrent requests for a page share one download', () async {
    await Future.wait([store.fetch(3), store.fetch(3), store.page(3)]);
    expect(server.requests, hasLength(2));
  });

  test(
    'offline with nothing on the device fails, and can be retried',
    () async {
      server.offline = true;
      await expectLater(store.page(1), throwsA(isA<SocketException>()));
      server.offline = false;
      expect((await store.page(1)).page, 1);
    },
  );

  test('a damaged file on the device is dropped and fetched again', () async {
    await store.fetch(1);
    stored('001.svg.gz').writeAsBytesSync([1, 2, 3]);
    await expectLater(store.page(1), throwsA(isA<PageDownloadException>()));
    expect(stored('001.svg.gz').existsSync(), isFalse);
    expect((await store.page(1)).page, 1);
  });

  group('the offline pack', () {
    /// Puts an archive where the system downloader writes it.
    File arrived(String extension, {List<int>? bytes}) =>
        stored('pack/hafs-kfqc-$extension.zip')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes ?? fixtureArchive(extension));

    test(
      'asks for the two archives, at the paths the downloader writes',
      () async {
        expect(await store.packFileCount(), 6);
        final missing = await store.missing();
        expect(
          [for (final file in missing) file.path],
          [
            'svg/hafs-kfqc/pack/hafs-kfqc-svg.zip',
            'svg/hafs-kfqc/pack/hafs-kfqc-json.zip',
          ],
        );
        expect(
          missing.first.url.toString(),
          'https://example.test/hafs-kfqc-svg.zip',
        );
        // One that has arrived is not asked for again.
        arrived('json');
        expect(
          [for (final file in await store.missing()) file.path],
          ['svg/hafs-kfqc/pack/hafs-kfqc-svg.zip'],
        );
        expect(await store.hasArchives(), isTrue);
      },
    );

    test('installing checks, unpacks, and compresses every page', () async {
      arrived('svg');
      arrived('json');
      await store.install();

      expect(await store.filesOnDevice(), 6);
      expect(stored('002.svg.gz').existsSync(), isTrue);
      expect(stored('003.json.gz').existsSync(), isTrue);
      // The archives are gone, and so are the files that are not pages.
      expect(await store.hasArchives(), isFalse);
      expect(stored('001-surah1.svg.gz').existsSync(), isFalse);
      expect(await store.missing(), isEmpty);
      // Every page now opens without the network.
      server.offline = true;
      for (final page in [1, 2, 3]) {
        expect((await store.page(page)).page, page);
      }
      expect(server.requests, isEmpty);
    });

    test('two unpackings at once do not trip over each other', () async {
      // Each deletes the archives it finished; the other finds them gone.
      arrived('svg');
      arrived('json');
      await Future.wait([store.install(), store.install()]);
      expect(await store.filesOnDevice(), 6);
      expect(await store.hasArchives(), isFalse);
    });

    test('an archive that fails its checksum installs nothing', () async {
      final altered = fixtureArchive('svg')..[40] ^= 0xFF;
      arrived('svg', bytes: altered);
      arrived('json', bytes: '<html>Not found</html>'.codeUnits);
      await store.install();
      expect(await store.filesOnDevice(), 0);
      expect(await store.hasArchives(), isFalse);
      // Both are asked for again.
      expect(await store.missing(), hasLength(2));
    });

    test('a page inside a sound archive is still checked on its own', () async {
      // An archive whose checksum the manifest vouches for, but holding a
      // page that does not match its own checksum.
      final manifest = fixtureManifest();
      final odd = SvgPageStore(
        root: () async => root,
        manifest: () async => SvgManifestParser.parse(
          jsonEncode({
            'edition': manifest.edition,
            'base': '${manifest.base}',
            'packedBytes': 1,
            'archives': [
              for (final archive in manifest.archives)
                {
                  'name': archive.name,
                  'url': '${archive.url}',
                  'sha256': archive.sha256,
                  'bytes': archive.bytes,
                },
            ],
            'pages': [
              for (final page in manifest.pages)
                ['0' * 64, page.jsonSha256, page.bytes],
            ],
          }),
        ),
        fetch: server.fetch,
      );
      arrived('svg');
      arrived('json');
      await odd.install();
      expect(stored('001.svg.gz').existsSync(), isFalse);
      expect(stored('001.json.gz').existsSync(), isTrue);
    });

    test('pages already on the device are kept as they are', () async {
      await store.fetch(1);
      final before = stored('001.svg.gz').lastModifiedSync();
      arrived('svg');
      arrived('json');
      await store.install();
      expect(stored('001.svg.gz').lastModifiedSync(), before);
      expect(await store.filesOnDevice(), 6);
    });

    test('counts its bytes and deletes everything', () async {
      expect(await store.bytesOnDevice(), 0);
      await store.fetch(1);
      expect(await store.bytesOnDevice(), greaterThan(0));
      arrived('json');
      await store.deleteAll();
      expect(await store.bytesOnDevice(), 0);
      expect(await store.hasArchives(), isFalse);
      expect(await store.missing(), hasLength(2));
    });
  });
}
