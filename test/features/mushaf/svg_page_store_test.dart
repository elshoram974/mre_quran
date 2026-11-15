import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/svg_manifest_parser.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';
import 'package:mre_quran/features/mushaf/domain/svg_manifest.dart';

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

  group('the bundled manifest', () {
    final file = File(SvgManifest.asset);

    test('matches its recorded SHA-256', () {
      expect(
        sha256.convert(file.readAsBytesSync()).toString(),
        SvgManifest.assetSha256,
      );
    });

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
    });

    test('a broken manifest is rejected', () {
      expect(() => SvgManifestParser.parse('{}'), throwsFormatException);
      expect(
        () => SvgManifestParser.parse(
          '{"edition":"x","base":"https://x","packedBytes":1,'
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
    expect(page.marks, contains('ayah-mark-ornament'));
    expect(
      [for (final uri in server.requests) uri.pathSegments.last],
      ['002.svg', '002.json'],
    );

    server.offline = true;
    final again = await store.page(2);
    expect(again.layout.regions.length, page.layout.regions.length);
    expect(server.requests, hasLength(2), reason: 'no second download');
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
    test('lists what is missing, at the paths the downloader writes', () async {
      expect(await store.packFileCount(), 6);
      await store.fetch(1);
      final missing = await store.missing();
      expect(
        [for (final file in missing) file.path],
        [
          'svg/hafs-kfqc/002.svg',
          'svg/hafs-kfqc/002.json',
          'svg/hafs-kfqc/003.svg',
          'svg/hafs-kfqc/003.json',
        ],
      );
      expect(
        missing.first.url.toString(),
        'https://example.test/pages/002.svg',
      );
    });

    test('downloaded files are checked and compressed; bad ones go', () async {
      stored('002.svg')
        ..createSync(recursive: true)
        ..writeAsStringSync(fixtureSvg);
      stored('002.json').writeAsStringSync(fixtureJson);
      // An error page a CDN answered with 200.
      stored('003.svg').writeAsStringSync('<html>Not found</html>');
      stored('999.svg').writeAsStringSync(fixtureSvg);

      await store.ingest();

      expect(stored('002.svg.gz').existsSync(), isTrue);
      expect(stored('002.json.gz').existsSync(), isTrue);
      expect(stored('002.svg').existsSync(), isFalse);
      expect(stored('003.svg').existsSync(), isFalse);
      expect(stored('003.svg.gz').existsSync(), isFalse);
      expect(stored('999.svg').existsSync(), isFalse);
      expect(
        [for (final file in await store.missing()) file.path],
        [
          'svg/hafs-kfqc/001.svg',
          'svg/hafs-kfqc/001.json',
          'svg/hafs-kfqc/003.svg',
          'svg/hafs-kfqc/003.json',
        ],
      );
      // The page opens without the network.
      server.offline = true;
      expect((await store.page(2)).page, 2);
    });

    test('counts its bytes and deletes everything', () async {
      expect(await store.bytesOnDevice(), 0);
      await store.fetch(1);
      expect(await store.bytesOnDevice(), greaterThan(0));
      await store.deleteAll();
      expect(await store.bytesOnDevice(), 0);
      expect(await store.missing(), hasLength(6));
    });
  });
}
