import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/page_prefetcher.dart';
import 'package:mre_quran/features/mushaf/data/page_asset_store.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';

const _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0];

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('prefetch'));
  tearDown(() => root.deleteSync(recursive: true));

  PagePrefetcher prefetcher(Future<Uint8List> Function(Uri) fetch) =>
      PagePrefetcher(PageAssetStore(root: () async => root, fetch: fetch));

  Future<void> idle() => Future<void>.delayed(const Duration(milliseconds: 80));

  test('fetches several pages at once, nearest first', () async {
    final started = <int>[];
    final gates = <int, Completer<Uint8List>>{};
    final p = prefetcher((uri) {
      final page = int.parse(RegExp(r'p(\d+)\.png').firstMatch('$uri')![1]!);
      started.add(page);
      return (gates[page] = Completer<Uint8List>()).future;
    });
    p.around(
      style: MushafStyle.madinahHd,
      page: 10,
      dark: false,
      pageCount: 604,
    );
    await idle();
    // Three at a time, the nearest ahead of the page first; nothing waits for
    // the first to finish.
    expect(started, [11, 12, 13]);
    gates[11]!.complete(Uint8List.fromList(_png));
    await idle();
    expect(started, [11, 12, 13, 14]);
    for (final gate in gates.values) {
      if (!gate.isCompleted) gate.complete(Uint8List.fromList(_png));
    }
    await idle();
  });

  test(
    'one failed page does not stop the rest, but offline gives up',
    () async {
      final started = <int>[];
      final p = prefetcher((uri) async {
        final page = int.parse(RegExp(r'p(\d+)\.png').firstMatch('$uri')![1]!);
        started.add(page);
        if (page == 12) throw PageDownloadException(uri, 'HTTP 404');
        return Uint8List.fromList(_png);
      });
      p.around(
        style: MushafStyle.madinahHd,
        page: 10,
        dark: false,
        pageCount: 604,
      );
      await idle();
      expect(started, containsAll([11, 12, 13, 14, 15, 16, 17, 18, 9, 8]));

      started.clear();
      final offline = prefetcher((uri) async {
        started.add(1);
        throw PageDownloadException(uri, 'offline');
      });
      offline.around(
        style: MushafStyle.madinahHd,
        page: 300,
        dark: false,
        pageCount: 604,
      );
      await idle();
      expect(started.length, lessThan(10), reason: 'gave up, not 10 tries');
    },
  );

  test('a newer request replaces an older one', () async {
    final started = <int>[];
    final p = prefetcher((uri) async {
      started.add(int.parse(RegExp(r'p(\d+)\.png').firstMatch('$uri')![1]!));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return Uint8List.fromList(_png);
    });
    p.around(
      style: MushafStyle.madinahHd,
      page: 10,
      dark: false,
      pageCount: 604,
    );
    p.around(
      style: MushafStyle.madinahHd,
      page: 100,
      dark: false,
      pageCount: 604,
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(started.where((page) => page > 90), isNotEmpty);
    expect(started.where((page) => page > 14 && page < 90), isEmpty);
  });
}
