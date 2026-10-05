import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/data/page_asset_store.dart';

void main() {
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
    final s = store((_) async => Uint8List.fromList([1, 2, 3]));
    final first = await s.image(5, dark: false);
    final again = await s.image(5, dark: false);
    expect(first.path, again.path);
    expect(await again.readAsBytes(), [1, 2, 3]);
    expect(requests, hasLength(1));
    expect(requests.single.path, endsWith('/light/p5.png'));
    expect(File('${first.path}.part').existsSync(), isFalse);
  });

  test('light and dark are kept apart', () async {
    final s = store((_) async => Uint8List.fromList([9]));
    final light = await s.image(5, dark: false);
    final dark = await s.image(5, dark: true);
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
      return Uint8List.fromList([4]);
    });
    await expectLater(
      s.image(3, dark: false),
      throwsA(isA<PageDownloadException>()),
    );
    expect(root.listSync(recursive: true).whereType<File>(), isEmpty);
    fail = false;
    expect(await (await s.image(3, dark: false)).readAsBytes(), [4]);
  });

  test('an empty response is an error', () async {
    final s = store((_) async => Uint8List(0));
    await expectLater(
      s.image(1, dark: false),
      throwsA(isA<PageDownloadException>()),
    );
  });
}
