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
    final store = _GatedPageStore();
    PagePrefetcher(store).around(page: 10, pageCount: 604);
    expect(store.started, [11, 12, 13]);
    store.gates[11]!.complete();
    await store.fourthStarted.future;
    expect(store.started, [11, 12, 13, 14]);
    for (final gate in store.gates.values) {
      if (!gate.isCompleted) gate.complete();
    }
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
    await until(() => started.any((page) => page > 90));
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

/// Holds the first batch at the store boundary so disk timing cannot decide
/// which page the scheduler starts next.
class _GatedPageStore extends Fake implements SvgPageStore {
  final started = <int>[];
  final gates = <int, Completer<void>>{};
  final fourthStarted = Completer<void>();

  @override
  Future<void> fetch(int page) {
    started.add(page);
    if (started.length == 4) fourthStarted.complete();
    if (started.length > 4) return Future<void>.value();
    return (gates[page] = Completer<void>()).future;
  }
}
