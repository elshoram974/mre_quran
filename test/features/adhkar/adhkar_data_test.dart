import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_parser.dart';
import 'package:mre_quran/features/adhkar/data/adhkar_source.dart';
import 'package:mre_quran/features/adhkar/domain/quran_passage.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_parser.dart';
import 'package:mre_quran/features/quran_index/data/quran_metadata_source.dart';

/// Serves asset bytes from disk, with optional replacements.
class _DiskBundle extends CachingAssetBundle {
  _DiskBundle([this.overrides = const {}]);

  final Map<String, Uint8List> overrides;

  @override
  Future<ByteData> load(String key) async {
    final bytes = overrides[key] ?? File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

Map<String, Object?> _entry({
  int order = 1,
  int count = 1,
  Object? source = 'مصدر',
}) => {
  'order': order,
  'content': 'ذكر',
  'count': count,
  'count_description': 'مرة',
  'fadl': '',
  'source': source,
  'type': 0,
  'audio': '',
  'hadith_text': '',
  'explanation_of_hadith_vocabulary': '',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled data', () {
    test(
      'loads, verifies, and splits the shared file into collections',
      () async {
        final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
        expect(catalog.collections.map((c) => c.id).take(5).toList(), [
          'morning',
          'evening',
          'sleep',
          'wake',
          'after_prayer',
        ]);
        // The Hisn chapters come from the included manifest.
        expect(catalog.byId('hisn_4'), isNotNull);
        expect(catalog.collections.length, greaterThan(40));
        expect(catalog.groups.map((g) => g.id), contains('travel'));
        expect(catalog.byId('after_prayer')!.group.id, 'prayer');
        expect(catalog.byId('after_prayer')!.sessionWindowMinutes, 30);
        final morning = catalog.byId('morning')!;
        final evening = catalog.byId('evening')!;
        expect(morning.group.id, 'daily');
        expect(morning.entries, isNotEmpty);
        expect(evening.entries, isNotEmpty);
        // Variant 1 is morning only, 2 is evening only, 0 is both.
        expect(morning.entries.every((e) => e.variant != 2), isTrue);
        expect(evening.entries.every((e) => e.variant != 1), isTrue);
        expect(
          morning.entries.where((e) => e.variant == 0).map((e) => e.order),
          evening.entries.where((e) => e.variant == 0).map((e) => e.order),
        );
      },
    );

    test('every dhikr has words, a repeat count, and its evidence', () async {
      final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
      for (final collection in catalog.collections) {
        expect(collection.titles['ar'], isNotEmpty);
        for (final entry in collection.entries) {
          expect(
            entry.text.trim().isNotEmpty || entry.quran != null,
            isTrue,
            reason: '${entry.order}',
          );
          expect(entry.repeat, greaterThanOrEqualTo(1));
          expect(entry.source.trim(), isNotEmpty, reason: '${entry.order}');
        }
      }
    });

    test('every Quran passage names ayahs that exist', () async {
      final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
      final metadata = QuranMetadataParser.parse(
        File(QuranMetadataSource.assetPath).readAsStringSync(),
      );
      var passages = 0;
      for (final collection in catalog.collections) {
        for (final entry in collection.entries) {
          for (final span in entry.quran?.spans ?? const <AyahSpan>[]) {
            passages++;
            expect(
              span.to,
              lessThanOrEqualTo(metadata.surah(span.surah).ayahCount),
              reason: '${collection.id} ${entry.order}',
            );
          }
        }
      }
      expect(passages, greaterThan(0));
    });

    test('the isti\'adha opens a list once, not every surah', () async {
      final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
      for (final id in ['sleep', 'after_prayer', 'wake']) {
        final withIstiadha = [
          for (final entry in catalog.byId(id)!.entries)
            if (entry.quran?.istiadha ?? false) entry,
        ];
        expect(withIstiadha, hasLength(1), reason: id);
        final firstQuran = catalog
            .byId(id)!
            .entries
            .firstWhere((entry) => entry.quran != null);
        expect(firstQuran.quran!.istiadha, isTrue, reason: id);
      }
    });

    test(
      'the after-prayer list marks what is said after Maghrib only',
      () async {
        final catalog = await AdhkarSource(bundle: _DiskBundle()).load();
        final only = [
          for (final entry in catalog.byId('after_prayer')!.entries)
            if (entry.onlyAfter.isNotEmpty) entry,
        ];
        expect(only, isNotEmpty);
        expect(
          only.every((entry) => entry.onlyAfter.contains('maghrib')),
          isTrue,
        );
        expect(only.first.repeat, 10);
      },
    );

    test('refuses a file changed by even one character', () async {
      final bytes = File('assets/adhkar/morning_evening.ar.json')
          .readAsBytesSync();
      final changed = Uint8List.fromList([...bytes, 0x20]);
      expect(
        AdhkarSource(
          bundle: _DiskBundle({
            'assets/adhkar/morning_evening.ar.json': changed,
          }),
        ).load(),
        throwsA(isA<AdhkarIntegrityException>()),
      );
    });
  });

  group('AdhkarParser', () {
    test('rejects an entry without evidence', () {
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([_entry(source: '')])),
        throwsA(isA<AdhkarDataException>()),
      );
    });

    test('rejects a repeat count below one and duplicate orders', () {
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([_entry(count: 0)])),
        throwsA(isA<AdhkarDataException>()),
      );
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([_entry(), _entry()])),
        throwsA(isA<AdhkarDataException>()),
      );
    });

    test('rejects a manifest with a bad schema, time, or title', () {
      Map<String, Object?> collection({
        Object? time = '05:30',
        Object? ar = 'س',
      }) => {
        'id': 'a',
        'title': {'ar': ar},
        'file': 'a.json',
        'sha256': 'x',
        'variants': [0],
        'reminderTime': time,
      };
      String manifest(Map<String, Object?> c, {int schema = 1}) => jsonEncode({
        'schema': schema,
        'collections': [c],
      });

      expect(
        AdhkarParser.parseManifest(manifest(collection())).specs,
        hasLength(1),
      );
      for (final bad in [
        manifest(collection(), schema: 2),
        manifest(collection(time: '5:30')),
        manifest(collection(time: '24:00')),
        manifest(collection(ar: null)),
      ]) {
        expect(
          () => AdhkarParser.parseManifest(bad),
          throwsA(isA<AdhkarDataException>()),
        );
      }
    });

    test('reads the group and the prayer window, and rejects a bad window', () {
      Map<String, Object?> collection({Object? window, Object? group}) => {
        'id': 'a',
        'title': {'ar': 'س'},
        'file': 'a.json',
        'sha256': 'x',
        'variants': [0],
        'group': group,
        'sessionWindowMinutes': window,
      };
      String manifest(Map<String, Object?> c) => jsonEncode({
        'schema': 1,
        'collections': [c],
      });

      final spec = AdhkarParser.parseManifest(
        manifest(collection(window: 30, group: 'prayer')),
      ).specs.single;
      expect(spec.groupId, 'prayer');
      expect(spec.sessionWindowMinutes, 30);
      for (final bad in [0, -5, '30']) {
        expect(
          () => AdhkarParser.parseManifest(manifest(collection(window: bad))),
          throwsA(isA<AdhkarDataException>()),
        );
      }
    });

    test(
      'reads which prayers a dhikr is said after, and rejects an unknown one',
      () {
        Map<String, Object?> entry(Object? when) => {
          ..._entry(order: 1),
          'when': when,
        };
        final parsed = AdhkarParser.parseEntries(
          jsonEncode([
            entry(['fajr', 'maghrib']),
          ]),
        );
        expect(parsed.single.onlyAfter, {'fajr', 'maghrib'});
        expect(
          AdhkarParser.parseEntries(jsonEncode([entry(null)])).single.onlyAfter,
          isEmpty,
        );
        for (final bad in [
          ['noon'],
          'fajr',
          [1],
        ]) {
          expect(
            () => AdhkarParser.parseEntries(jsonEncode([entry(bad)])),
            throwsA(isA<AdhkarDataException>()),
          );
        }
      },
    );

    test('reads a Quran passage and rejects a bad range', () {
      Map<String, Object?> entry(Object? quran, {String content = ''}) => {
        ..._entry(order: 1),
        'content': content,
        'quran': quran,
      };
      final parsed = AdhkarParser.parseEntries(
        jsonEncode([
          entry({
            'istiadha': true,
            'ranges': [
              {'surah': 2, 'from': 255, 'to': 255},
            ],
          }),
        ]),
      );
      expect(parsed.single.quran!.istiadha, isTrue);
      expect(parsed.single.quran!.spans.single.surah, 2);
      expect(parsed.single.text, isEmpty);
      for (final bad in [
        <String, Object?>{'ranges': <Object?>[]},
        {
          'ranges': [
            {'surah': 0, 'from': 1, 'to': 1},
          ],
        },
        {
          'ranges': [
            {'surah': 2, 'from': 5, 'to': 4},
          ],
        },
      ]) {
        expect(
          () => AdhkarParser.parseEntries(jsonEncode([entry(bad)])),
          throwsA(isA<AdhkarDataException>()),
        );
      }
      // Without a passage the words are required.
      expect(
        () => AdhkarParser.parseEntries(jsonEncode([entry(null)])),
        throwsA(isA<AdhkarDataException>()),
      );
    });

    test('an unknown icon name falls back to the generic icon', () {
      final specs = AdhkarParser.parseManifest(
        jsonEncode({
          'schema': 1,
          'collections': [
            {
              'id': 'a',
              'title': {'ar': 'س'},
              'icon': 'rocket',
              'file': 'a.json',
              'sha256': 'x',
              'variants': [0],
            },
          ],
        }),
      );
      expect(specs.specs.single.icon.name, 'generic');
      expect(specs.specs.single.reminderMinutes, isNull);
    });
  });
}
