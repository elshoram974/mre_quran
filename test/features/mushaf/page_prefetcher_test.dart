import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/page_prefetcher.dart';
import 'package:mre_quran/features/mushaf/data/svg_page_store.dart';

import '../../helpers/svg_page_fixtures.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('prefetch'));
  tearDown(() => root.deleteSync(recursive: true));

  PagePrefetcher prefetcher(Future<Uint8List> Function(Uri) fetch) =>
      PagePrefetcher(
        SvgPageStore(
          root: () async => root,
          manifest: () async => fixtureManifest(pages: 604),
          fetch: fetch,
        ),
      );

  Future<void> idle() => Future<void>.delayed(const Duration(milliseconds: 80));

  /// Waits for [done], however busy the machine is.
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await idle();
    }
  }

  /// The page a request is for, when it asks for the page's artwork.
  int? artworkPage(Uri uri) {
    final match = RegExp(r'(\d+)\.svg$').firstMatch(uri.path);
    return match == null ? null : int.parse(match[1]!);
  }

  Uint8List answer(Uri uri) =>
      bytesOf(uri.path.endsWith('.svg') ? fixtureSvg : fixtureJson);

  test('fetches several pages at once, nearest first', () async {
    final started = <int>[];
    final gates = <int, Completer<Uint8List>>{};
    final p = prefetcher((uri) {
      final page = artworkPage(uri);
      if (page == null) return Future.value(answer(uri));
      started.add(page);
      return (gates[page] = Completer<Uint8List>()).future;
    });
    p.around(page: 10, pageCount: 604);
    await until(() => started.length >= 3);
    await idle();
    // Three at a time, the nearest ahead of the page first; nothing waits for
    // the first to finish, and no fourth starts while three are running.
    // The three start together, so their own order depends on the disk.
    expect(started, unorderedEquals([11, 12, 13]));
    gates[11]!.complete(bytesOf(fixtureSvg));
    await until(() => started.length >= 4);
    expect(started.last, 14);
    for (final gate in gates.values) {
      if (!gate.isCompleted) gate.complete(bytesOf(fixtureSvg));
    }
    await idle();
  });

  test(
    'one failed page does not stop the rest, but offline gives up',
    () async {
      final started = <int>[];
      final p = prefetcher((uri) async {
        final page = artworkPage(uri);
        if (page != null) started.add(page);
        if (page == 12) throw PageDownloadException(uri, 'HTTP 404');
        return answer(uri);
      });
      p.around(page: 10, pageCount: 604);
      // Each page is checked and compressed as it lands; wait for them all.
      await until(() => started.length >= 10);
      expect(started, containsAll([11, 12, 13, 14, 15, 16, 17, 18, 9, 8]));

      started.clear();
      final offline = prefetcher((uri) async {
        started.add(1);
        throw PageDownloadException(uri, 'offline');
      });
      offline.around(page: 300, pageCount: 604);
      await idle();
      expect(started.length, lessThan(10), reason: 'gave up, not 10 tries');
    },
  );

  test('a newer request replaces an older one', () async {
    final started = <int>[];
    final p = prefetcher((uri) async {
      final page = artworkPage(uri);
      if (page != null) started.add(page);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return answer(uri);
    });
    p
      ..around(page: 10, pageCount: 604)
      ..around(page: 100, pageCount: 604);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(started.where((page) => page > 90), isNotEmpty);
    expect(started.where((page) => page > 14 && page < 90), isEmpty);
  });

  test('stays inside the Mushaf at its first and last pages', () async {
    final started = <int>[];
    final p = prefetcher((uri) async {
      final page = artworkPage(uri);
      if (page != null) started.add(page);
      return answer(uri);
    });
    p.around(page: 604, pageCount: 604);
    await until(() => started.length >= 2);
    await idle();
    expect(started, unorderedEquals([603, 602]));
  });
}
