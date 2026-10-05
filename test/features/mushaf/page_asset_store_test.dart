import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/page_asset_store.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';

const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0];

void main() {
  final hd = MushafEdition.madinahHd;
  late Directory root;
  late List<Uri> requests;

  setUp(() {
    root = Directory.systemTemp.createTempSync('mushaf_store');
    requests = [];
  });
  tearDown(() => root.deleteSync(recursive: true));

  PageAssetStore store(Future<Uint8List> Function(Uri) fetch) => PageAssetStore(
    root: () async => root,
    fetch: (uri) {
      requests.add(uri);
      return fetch(uri);
    },
  );

  test('downloads once, then reads from disk', () async {
    final s = store((_) async => Uint8List.fromList(png));
    final first = await s.image(hd, 5, dark: false);
    final again = await s.image(hd, 5, dark: false);
    expect(first.path, again.path);
    expect(await again.readAsBytes(), png);
    expect(requests, hasLength(1));
    expect(requests.single.path, endsWith('/light/p5.png'));
    expect(File('${first.path}.part').existsSync(), isFalse);
  });

  test('light and dark are kept apart', () async {
    final s = store((_) async => Uint8List.fromList(png));
    final light = await s.image(hd, 5, dark: false);
    final dark = await s.image(hd, 5, dark: true);
    expect(light.path, isNot(dark.path));
    expect(requests.last.path, endsWith('/dark/p5.png'));
  });

  test('reads a layout as text', () async {
    final s = store((_) async => Uint8List.fromList('{"page":7}'.codeUnits));
    expect(await s.layout(7), '{"page":7}');
    expect(requests.single.path, endsWith('/page-007.json'));
  });

  test('a failed download leaves nothing behind and can be retried', () async {
    var fail = true;
    final s = store((uri) async {
      if (fail) throw PageDownloadException(uri, 'offline');
      return Uint8List.fromList(png);
    });
    await expectLater(
      s.image(hd, 3, dark: false),
      throwsA(isA<PageDownloadException>()),
    );
    expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
    fail = false;
    expect(await (await s.image(hd, 3, dark: false)).readAsBytes(), png);
  });

  test('an empty response or an error page is not cached', () async {
    final html = Uint8List.fromList('<html>503</html>'.codeUnits);
    for (final body in [Uint8List(0), html]) {
      final s = store((_) async => body);
      await expectLater(
        s.image(hd, 1, dark: false),
        throwsA(isA<PageDownloadException>()),
      );
      await expectLater(s.layout(1), throwsA(isA<PageDownloadException>()));
    }
    expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('an edition without dark images uses one file in both themes', () async {
    final s = store((_) async => Uint8List.fromList(png));
    final madinah = MushafEdition.madinah;
    final light = await s.image(madinah, 42, dark: false);
    final dark = await s.image(madinah, 42, dark: true);
    expect(dark.path, light.path);
    expect(requests, hasLength(1));
    expect(requests.single.path, endsWith('/width_1260/page042.png'));
  });

  test('a glyph database that fails its checksum is rejected', () async {
    final s = store((_) async => Uint8List.fromList([1, 2, 3]));
    await expectLater(
      s.ayahInfoDatabase(),
      throwsA(isA<PageDownloadException>()),
    );
    expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
  });
}
